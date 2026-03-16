#!/bin/bash
# Test QMD CUDA Performance
# Compares CPU vs CUDA performance for embeddings and search

set -e

echo "🧪 QMD CUDA Performance Test"
echo "=============================="
echo ""

# Activate environment
source ~/clawd/scripts/activate-ml-cuda.sh
export PATH="$HOME/.bun/bin:$PATH"
cd ~/clawd

echo "📊 System Info:"
nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader
echo ""

# Check if CUDA libraries are present
if [ -f ~/.bun/install/global/node_modules/node-llama-cpp/llama/localBuilds/linux-x64-cuda/bin/libggml-cuda.so ]; then
    echo "✅ CUDA libraries found"
else
    echo "⚠️  CUDA libraries NOT found - will use CPU"
fi
echo ""

# Test 1: Quick search (doesn't use embeddings)
echo "Test 1: BM25 Search (CPU-only, baseline)"
time qmd search "email setup" -n 3 > /dev/null 2>&1
echo ""

# Test 2: Vector search (uses embeddings model)
echo "Test 2: Vector Search (uses GPU if available)"
echo "Monitoring GPU usage..."
nvidia-smi dmon -c 1 &
time qmd vsearch "how to send emails" -n 3 > /dev/null
echo ""

# Test 3: Re-embed a single file to measure embedding speed
echo "Test 3: Embedding Performance"
TEST_FILE=$(mktemp --suffix=.md)
cat > $TEST_FILE << 'EOF'
# Test Document for Embedding Performance

This is a test document to measure embedding generation speed.
It contains multiple paragraphs to create a reasonable chunk size.

## Section 1
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Machine learning and artificial intelligence are transforming technology.
CUDA acceleration provides significant speedups for tensor operations.

## Section 2
PyTorch is a popular deep learning framework.
Embeddings capture semantic meaning in vector space.
Vector search enables similarity-based retrieval.

## Section 3
Performance benchmarking helps optimize ML workflows.
GPU memory management is crucial for large models.
Batch processing improves throughput for inference tasks.
EOF

# Create temporary collection
qmd collection add $(dirname $TEST_FILE) --name test-perf --mask "*.md" > /dev/null 2>&1

echo "Embedding test document..."
nvidia-smi dmon -c 1 &
time qmd embed -f
echo ""

# Cleanup
qmd collection remove test-perf > /dev/null 2>&1
rm $TEST_FILE

echo "✅ Tests complete!"
echo ""
echo "Summary:"
echo "- BM25 search: CPU-only (baseline)"
echo "- Vector search: Should use GPU if CUDA libraries present"  
echo "- Embedding: Should use GPU if CUDA libraries present"
echo ""
echo "Check nvidia-smi output above for GPU utilization during tests."
