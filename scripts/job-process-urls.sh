#!/bin/bash
# Simple wrapper to process job URLs from Obsidian queue or direct URLs

OBSIDIAN_VAULT="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Business_Vault"
JOB_QUEUE="$OBSIDIAN_VAULT/Projects/Job Application Pipeline/JOB_QUEUE.md"
RESULTS_DIR="$OBSIDIAN_VAULT/Projects/Job Application Pipeline/results"
PIPELINE_DIR="$HOME/clawd/job-pipeline"

usage() {
    cat <<EOF
Usage: $0 [command] [options]

Commands:
    process-queue       Process all URLs in JOB_QUEUE.md
    process-url <url>   Process single URL
    rank               Re-rank all processed jobs
    top [N]            Show top N opportunities (default: 5)
    status             Show processing status

Examples:
    $0 process-queue
    $0 process-url "https://careers.nvidia.com/..."
    $0 top 10
    $0 status
EOF
}

process_url() {
    local url="$1"
    
    echo "🔍 Processing: $url"
    
    cd "$PIPELINE_DIR"
    
    # Activate conda if available
    if command -v conda &> /dev/null; then
        source "$(conda info --base)/etc/profile.d/conda.sh"
        conda activate job-pipeline 2>/dev/null || true
    fi
    
    # Quick extraction test (simplified)
    local job_id=$(echo "$url" | md5sum | cut -d' ' -f1 | head -c 8)
    local timestamp=$(date '+%Y-%m-%d-%H%M')
    local output="$RESULTS_DIR/${timestamp}-${job_id}"
    
    mkdir -p "$output"
    echo "$url" > "$output/url.txt"
    
    # For now, return URL for manual processing by main agent
    echo "URL saved. Main agent will process."
    echo "$output"
}

show_top() {
    local n=${1:-5}
    
    echo "🏆 Top $n Opportunities:"
    echo ""
    
    if [ -f "$RESULTS_DIR/top_opportunities.json" ]; then
        jq -r ".[:$n] | .[] | \"\\(.total_rank | tonumber | floor) - \\(.company) - \\(.position) (Fit: \\(.fit_score)%, ATS: \\(.ats_score))\"" \
            "$RESULTS_DIR/top_opportunities.json" 2>/dev/null || {
            echo "No results yet. Process some jobs first!"
        }
    else
        echo "No results yet. Process some jobs first!"
    fi
}

show_status() {
    echo "📊 Job Queue Status:"
    echo ""
    
    local total=$(find "$RESULTS_DIR" -name "ranking.json" 2>/dev/null | wc -l)
    local success=$(find "$RESULTS_DIR" -name "status.txt" -exec grep -l "SUCCESS" {} \; 2>/dev/null | wc -l)
    local failed=$(find "$RESULTS_DIR" -name "status.txt" -exec grep -l "FAILED" {} \; 2>/dev/null | wc -l)
    
    echo "  Total processed: $total"
    echo "  Successful: $success"
    echo "  Failed: $failed"
    
    if [ $total -gt 0 ]; then
        local avg_ats=$(find "$RESULTS_DIR" -name "ats_score.json" -exec jq -r '.total_score' {} \; 2>/dev/null | \
            awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')
        echo "  Average ATS score: ${avg_ats:-N/A}"
    fi
}

# Main command router
case "${1:-}" in
    process-queue)
        bash ~/clawd/scripts/job-queue-processor.sh
        ;;
    process-url)
        if [ -z "$2" ]; then
            echo "Error: URL required"
            usage
            exit 1
        fi
        process_url "$2"
        ;;
    rank)
        bash ~/clawd/scripts/job-queue-processor.sh
        ;;
    top)
        show_top "$2"
        ;;
    status)
        show_status
        ;;
    *)
        usage
        exit 1
        ;;
esac
