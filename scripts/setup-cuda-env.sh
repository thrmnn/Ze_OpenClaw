#!/bin/bash
# Setup CUDA environment for ML tools
# Source this file before running CUDA-accelerated tools

export CUDA_HOME=/usr/local/cuda
export CUDA_PATH=/usr/local/cuda
export CUDACXX=/usr/local/cuda/bin/nvcc
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify CUDA is available
if command -v nvcc &> /dev/null; then
    echo "✓ CUDA environment configured"
    nvcc --version | head -1
else
    echo "✗ CUDA not found in PATH"
    exit 1
fi
