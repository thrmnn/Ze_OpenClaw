#!/bin/bash
# Activate ML-CUDA environment
# Reusable setup for PyTorch + CUDA projects

# Use existing miniconda3 installation
source ~/miniconda3/etc/profile.d/conda.sh

# Activate ml-cuda environment
conda activate ml-cuda

# Set CUDA environment variables
export CUDA_HOME=/usr/local/cuda
export CUDA_PATH=/usr/local/cuda
export CUDACXX=/usr/local/cuda/bin/nvcc
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# GPU device selection (default to GPU 0)
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}

# Verify setup
echo "✓ ML-CUDA environment activated"
echo "  Python: $(python --version)"
echo "  Conda env: $CONDA_DEFAULT_ENV"
echo "  CUDA: $(nvcc --version 2>/dev/null | grep release || echo 'nvcc not in PATH')"

# Check PyTorch + CUDA
python -c "import torch; print(f'  PyTorch: {torch.__version__}'); print(f'  CUDA available: {torch.cuda.is_available()}'); print(f'  GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')" 2>/dev/null || echo "  PyTorch: Not installed yet"
