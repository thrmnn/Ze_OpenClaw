#!/bin/bash
# Build QMD with CUDA support
# Uses ml-cuda environment for robust CUDA setup

set -e

echo "🚀 Building QMD with CUDA acceleration..."
echo ""

# Activate ml-cuda environment
source ~/clawd/scripts/activate-ml-cuda.sh
echo ""

# Add bun to PATH
export PATH="$HOME/.bun/bin:$PATH"

# Set CUDA build flags
# RTX 4060 = compute_89, sm_89
export NODE_LLAMA_CPP_CUDA_ARCHS="89"
export CMAKE_ARGS="-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=89 -DCMAKE_BUILD_PARALLEL_LEVEL=4"

echo "📋 Build Configuration:"
echo "  CUDA_HOME: $CUDA_HOME"
echo "  CUDA Architectures: 89 (RTX 4060)"
echo "  Parallel jobs: 4"
echo ""

# Remove existing QMD
echo "🗑️  Removing old QMD installation..."
bun remove -g qmd 2>/dev/null || true

# Clean cached builds
echo "🧹 Cleaning cached builds..."
rm -rf ~/.bun/install/global/node_modules/node-llama-cpp/llama/localBuilds 2>/dev/null || true
echo ""

# Install QMD with CUDA
echo "⚙️  Building QMD with CUDA support..."
echo "  (This will take 5-10 minutes)"
echo ""
bun install -g https://github.com/tobi/qmd

echo ""
echo "✅ QMD installation complete!"
echo ""
echo "🧪 Testing..."

# Test QMD
cd ~/clawd
qmd status

echo ""
echo "🎉 QMD with CUDA is ready!"
echo ""
echo "Next steps:"
echo "  1. Re-generate embeddings: cd ~/clawd && qmd embed -f"
echo "  2. Test search: qmd query 'test query' -n 3"
echo "  3. Benchmark CPU vs CUDA performance"
