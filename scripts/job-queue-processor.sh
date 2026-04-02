#!/bin/bash
# Job Queue Processor - Monitors Obsidian JOB_QUEUE.md and processes job URLs

set -e

# Configuration
OBSIDIAN_VAULT="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Business_Vault"
JOB_QUEUE="$OBSIDIAN_VAULT/Projects/Job Application Pipeline/JOB_QUEUE.md"
RESULTS_DIR="$OBSIDIAN_VAULT/Projects/Job Application Pipeline/results"
PIPELINE_DIR="$HOME/clawd/job-pipeline"
PROFILE="$PIPELINE_DIR/data/theo-profile.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging
LOG_FILE="$HOME/clawd/logs/job-queue.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Extract URLs from JOB_QUEUE.md
extract_urls() {
    local priority=$1
    grep -A 50 "priority: $priority" "$JOB_QUEUE" | \
        grep "^https://" | \
        head -20
}

# Process single job URL
process_job() {
    local url=$1
    local priority=$2
    
    log "📋 Processing: $url (priority: $priority)"
    
    # Extract job ID from URL
    local job_id=$(echo "$url" | md5sum | cut -d' ' -f1 | head -c 8)
    local timestamp=$(date '+%Y-%m-%d-%H%M')
    local output_dir="$RESULTS_DIR/${timestamp}-${job_id}"
    
    mkdir -p "$output_dir"
    
    # Save URL
    echo "$url" > "$output_dir/job_url.txt"
    
    # Try to extract job description
    log "🔍 Extracting job description..."
    
    # Method 1: Try web_fetch (if available)
    if command -v openclaw &> /dev/null; then
        # Use OpenClaw web_fetch
        log "  Using OpenClaw web_fetch..."
        # This would need to be called via OpenClaw session
        # For now, save URL for manual processing
    fi
    
    # Method 2: Try curl + html2text (fallback)
    if command -v curl &> /dev/null && command -v html2text &> /dev/null; then
        log "  Using curl + html2text..."
        curl -s "$url" | html2text > "$output_dir/job_description.txt" 2>/dev/null || {
            log "  ⚠️  Extraction failed, will need manual input"
            echo "EXTRACTION_FAILED" > "$output_dir/status.txt"
            return 1
        }
    else
        log "  ⚠️  No extraction tools available"
        echo "EXTRACTION_FAILED" > "$output_dir/status.txt"
        return 1
    fi
    
    # Convert to markdown
    cat "$output_dir/job_description.txt" > "$output_dir/job_description.md"
    
    # Run job pipeline
    log "🤖 Running job application pipeline..."
    cd "$PIPELINE_DIR"
    
    # Activate conda env if available
    if command -v conda &> /dev/null; then
        source "$(conda info --base)/etc/profile.d/conda.sh"
        conda activate job-pipeline 2>/dev/null || true
    fi
    
    # Run pipeline with LLM rewriter
    python3 main.py apply \
        --use-llm-rewriter \
        --profile "$PROFILE" \
        --job "$output_dir/job_description.md" \
        --output "$output_dir" \
        2>&1 | tee "$output_dir/pipeline.log"
    
    # Check if successful
    if [ -f "$output_dir/tailored_resume.md" ]; then
        log "✅ Resume generated successfully"
        echo "SUCCESS" > "$output_dir/status.txt"
        
        # Run ATS scoring
        log "📊 Running ATS scoring..."
        python3 utils/ats_scorer.py \
            --resume "$output_dir/tailored_resume.md" \
            --job "$output_dir/job_description.md" \
            > "$output_dir/ats_score.json" 2>&1 || {
            log "  ⚠️  ATS scoring failed, continuing..."
        }
        
        # Extract scores for ranking
        if [ -f "$output_dir/ats_score.json" ]; then
            local ats_score=$(jq -r '.total_score // 0' "$output_dir/ats_score.json" 2>/dev/null || echo "0")
            local fit_score=$(jq -r '.fit_score // 0' "$output_dir/application.json" 2>/dev/null || echo "0")
            
            # Calculate rank: (fit * 0.4) + (ats * 0.6)
            local rank=$(echo "scale=2; ($fit_score * 0.4) + ($ats_score * 0.6)" | bc)
            
            # Save ranking
            cat > "$output_dir/ranking.json" <<EOF
{
  "url": "$url",
  "priority": "$priority",
  "fit_score": $fit_score,
  "ats_score": $ats_score,
  "total_rank": $rank,
  "timestamp": "$timestamp"
}
EOF
            log "  Fit: $fit_score% | ATS: $ats_score | Rank: $rank"
        fi
        
        return 0
    else
        log "❌ Pipeline failed"
        echo "PIPELINE_FAILED" > "$output_dir/status.txt"
        return 1
    fi
}

# Update JOB_QUEUE.md with results
update_queue() {
    log "📝 Updating JOB_QUEUE.md with results..."
    
    # Find all ranking.json files
    local results_table=""
    
    for ranking_file in "$RESULTS_DIR"/*/ranking.json; do
        if [ -f "$ranking_file" ]; then
            local dir=$(dirname "$ranking_file")
            local company=$(jq -r '.company // "Unknown"' "$ranking_file" 2>/dev/null || echo "Unknown")
            local position=$(jq -r '.position // "Unknown"' "$ranking_file" 2>/dev/null || echo "Unknown")
            local fit=$(jq -r '.fit_score' "$ranking_file")
            local ats=$(jq -r '.ats_score' "$ranking_file")
            local rank=$(jq -r '.total_rank' "$ranking_file")
            local timestamp=$(jq -r '.timestamp' "$ranking_file")
            
            local resume_path=$(basename "$dir")/tailored_resume.pdf
            
            results_table+="| $position | $company | $fit | $ats | $rank | ✅ Done | [$resume_path](results/$resume_path) |\n"
        fi
    done
    
    # This would update the markdown table
    # For now, log the results
    log "Results summary:"
    echo -e "$results_table"
}

# Generate top opportunities
generate_top_opportunities() {
    log "🏆 Generating top opportunities ranking..."
    
    # Find all ranking.json files and sort by total_rank
    local top_jobs=$(find "$RESULTS_DIR" -name "ranking.json" -exec cat {} \; | \
        jq -s 'sort_by(.total_rank) | reverse' 2>/dev/null)
    
    echo "$top_jobs" > "$RESULTS_DIR/top_opportunities.json"
    
    log "  Top opportunities saved to top_opportunities.json"
}

# Main processing loop
main() {
    log "🚀 Job Queue Processor started"
    
    # Check if JOB_QUEUE exists
    if [ ! -f "$JOB_QUEUE" ]; then
        log "❌ JOB_QUEUE.md not found: $JOB_QUEUE"
        exit 1
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    # Process high priority jobs first
    log "📋 Processing HIGH priority jobs..."
    local high_urls=$(extract_urls "high")
    local count=0
    
    while IFS= read -r url; do
        if [ ! -z "$url" ]; then
            process_job "$url" "high" || true
            count=$((count + 1))
        fi
    done <<< "$high_urls"
    
    log "  Processed $count high priority jobs"
    
    # Process medium priority
    log "📋 Processing MEDIUM priority jobs..."
    local medium_urls=$(extract_urls "medium")
    count=0
    
    while IFS= read -r url; do
        if [ ! -z "$url" ]; then
            process_job "$url" "medium" || true
            count=$((count + 1))
        fi
    done <<< "$medium_urls"
    
    log "  Processed $count medium priority jobs"
    
    # Generate rankings
    generate_top_opportunities
    
    # Update queue file
    update_queue
    
    log "✅ Job queue processing complete"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
