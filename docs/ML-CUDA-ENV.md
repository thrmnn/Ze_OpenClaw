# ML-CUDA Environment - Reusable Setup

## Overview

**Purpose:** Robust, reusable ML/AI environment with PyTorch + CUDA 12.1 support

**Best Practices:**
- Uses existing miniconda3 installation (not a separate install)
- Reproducible via conda environment
- Portable across projects
- Proper CUDA environment variables
- Easy activation script

---

## Environment Details

**Name:** `ml-cuda`  
**Location:** `~/miniconda3/envs/ml-cuda`  
**Python:** 3.11  
**CUDA:** 12.1  
**GPU:** NVIDIA GeForce RTX 4060 (8GB VRAM)

---

## Installation

### Option 1: From Environment File (Recommended)

```bash
# Create environment from YAML
cd ~/clawd
source ~/miniconda3/etc/profile.d/conda.sh
conda env create -f envs/ml-cuda.yml
```

### Option 2: Manual Install

```bash
# Create base environment
source ~/miniconda3/etc/profile.d/conda.sh
conda create -n ml-cuda python=3.11 -y

# Activate
conda activate ml-cuda

# Install PyTorch with CUDA 12.1
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install ML libraries
pip install transformers sentence-transformers accelerate datasets
pip install faiss-gpu  # Vector search with GPU support
pip install jupyter ipython numpy scipy scikit-learn pandas tqdm
```

---

## Activation

### Quick Activation (Recommended)

```bash
# Use activation script (sets CUDA env vars automatically)
source ~/clawd/scripts/activate-ml-cuda.sh
```

**This script:**
- Activates conda environment
- Sets CUDA_HOME, CUDA_PATH, CUDACXX
- Adds CUDA bin to PATH
- Verifies PyTorch + CUDA setup

### Manual Activation

```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ml-cuda

# Set CUDA variables
export CUDA_HOME=/usr/local/cuda
export CUDA_PATH=/usr/local/cuda
export CUDACXX=/usr/local/cuda/bin/nvcc
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

---

## Verification

### Test PyTorch + CUDA

```python
import torch
print(f"PyTorch: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"GPU count: {torch.cuda.device_count()}")
```

**Expected output:**
```
PyTorch: 2.4.1+cu121
CUDA available: True
CUDA version: 12.1
GPU: NVIDIA GeForce RTX 4060 Laptop GPU
GPU count: 1
```

### Test GPU Memory

```python
import torch

# Allocate tensor on GPU
x = torch.randn(1000, 1000).cuda()
y = torch.randn(1000, 1000).cuda()
z = torch.mm(x, y)

print(f"GPU memory allocated: {torch.cuda.memory_allocated() / 1e9:.2f} GB")
print(f"GPU memory reserved: {torch.cuda.memory_reserved() / 1e9:.2f} GB")
print(f"Max GPU memory: {torch.cuda.max_memory_allocated() / 1e9:.2f} GB")
```

### Monitor GPU Usage

```bash
# Real-time monitoring
watch -n 1 nvidia-smi

# Check once
nvidia-smi
```

---

## QMD with CUDA

### Rebuild QMD with CUDA Support

```bash
# Activate environment
source ~/clawd/scripts/activate-ml-cuda.sh

# Set build flags
export NODE_LLAMA_CPP_CUDA_ARCHS="89"  # RTX 4060 = compute_89
export CMAKE_ARGS="-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=89"

# Remove old build
export PATH="$HOME/.bun/bin:$PATH"
bun remove -g qmd
rm -rf ~/.bun/install/global/node_modules/node-llama-cpp/llama/localBuilds

# Install with CUDA
bun install -g https://github.com/tobi/qmd

# Verify (should show CUDA backend)
cd ~/clawd
qmd embed
```

### Limit Parallel Jobs (Avoid OOM)

```bash
# For WSL with limited memory
export CMAKE_ARGS="-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=89 -DCMAKE_BUILD_PARALLEL_LEVEL=2"
bun install -g https://github.com/tobi/qmd
```

---

## Common Use Cases

### 1. Embeddings Generation

```python
from sentence_transformers import SentenceTransformer

# Load model on GPU
model = SentenceTransformer('all-MiniLM-L6-v2', device='cuda')

# Generate embeddings
texts = ["Hello world", "Machine learning", "CUDA acceleration"]
embeddings = model.encode(texts)
print(f"Shape: {embeddings.shape}")
```

### 2. FAISS Vector Search (GPU)

```python
import faiss
import numpy as np

# Create GPU index
res = faiss.StandardGpuResources()
dim = 128
index = faiss.GpuIndexFlatL2(res, dim)

# Add vectors
vectors = np.random.random((1000, dim)).astype('float32')
index.add(vectors)

# Search
query = np.random.random((1, dim)).astype('float32')
distances, indices = index.search(query, k=5)
print(f"Top 5 neighbors: {indices}")
```

### 3. Transformers with GPU

```python
from transformers import pipeline

# Load model on GPU
classifier = pipeline("sentiment-analysis", device=0)  # device=0 for CUDA:0

result = classifier("I love using CUDA acceleration!")
print(result)
```

---

## Environment Management

### List Environments

```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda env list
```

### Export Environment

```bash
conda activate ml-cuda
conda env export > envs/ml-cuda-$(date +%Y%m%d).yml
```

### Update Environment

```bash
conda activate ml-cuda
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Remove Environment

```bash
conda env remove -n ml-cuda
```

---

## Reusability

### For Other Projects

```bash
# Clone this environment
conda create --name project-name --clone ml-cuda

# Or use environment file
conda env create -f ~/clawd/envs/ml-cuda.yml -n project-name
```

### Adding to New Project

```bash
cd /path/to/new/project

# Activate ml-cuda
source ~/clawd/scripts/activate-ml-cuda.sh

# Install project-specific dependencies
pip install -r requirements.txt
```

---

## Troubleshooting

### PyTorch not seeing CUDA

```bash
# Check CUDA environment
echo $CUDA_HOME
echo $LD_LIBRARY_PATH

# Verify CUDA toolkit
nvcc --version
nvidia-smi

# Reinstall PyTorch
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### OOM during QMD build

```bash
# Limit parallel jobs
export CMAKE_ARGS="-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=89 -DCMAKE_BUILD_PARALLEL_LEVEL=2"

# Or build for single architecture only
export NODE_LLAMA_CPP_CUDA_ARCHS="89"
```

### WSL Memory Limits

```bash
# Check WSL memory
free -h

# Configure WSL memory (create ~/.wslconfig on Windows)
# [wsl2]
# memory=12GB
# processors=8
```

---

## Performance Benchmarks

### CPU vs GPU - Matrix Multiplication

```python
import torch
import time

size = 5000
iterations = 100

# CPU
x = torch.randn(size, size)
y = torch.randn(size, size)
start = time.time()
for _ in range(iterations):
    z = torch.mm(x, y)
cpu_time = time.time() - start

# GPU
x = x.cuda()
y = y.cuda()
torch.cuda.synchronize()
start = time.time()
for _ in range(iterations):
    z = torch.mm(x, y)
torch.cuda.synchronize()
gpu_time = time.time() - start

print(f"CPU: {cpu_time:.2f}s")
print(f"GPU: {gpu_time:.2f}s")
print(f"Speedup: {cpu_time/gpu_time:.1f}x")
```

**Expected:** 10-50x speedup on RTX 4060

---

## Best Practices

1. **Always activate environment** before running ML code
2. **Use activation script** for consistent CUDA setup
3. **Monitor GPU memory** with nvidia-smi
4. **Free GPU memory** after experiments: `torch.cuda.empty_cache()`
5. **Pin to single GPU** if needed: `export CUDA_VISIBLE_DEVICES=0`
6. **Document dependencies** in requirements.txt or environment.yml
7. **Version control** environment files (not conda binaries)

---

## Related Files

- `~/clawd/envs/ml-cuda.yml` - Environment specification
- `~/clawd/scripts/activate-ml-cuda.sh` - Activation script
- `~/clawd/docs/CUDA-SETUP.md` - CUDA configuration details
- `~/clawd/docs/QMD-USAGE.md` - QMD search tool usage

---

**Created:** 2026-01-31  
**Status:** Production Ready  
**GPU:** NVIDIA GeForce RTX 4060 (8GB VRAM)  
**CUDA:** 12.1
