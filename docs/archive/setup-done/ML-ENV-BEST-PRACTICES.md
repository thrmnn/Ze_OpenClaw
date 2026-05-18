# ML Environment Best Practices

## Overview
Lessons learned from setting up robust ML/AI environments with CUDA support on WSL/Linux systems.

---

## Environment Management

### Use Conda, Not Venv
**Why:** Better CUDA/cuDNN integration, easier package management for ML libraries

```bash
# ✅ Good
conda create -n ml-cuda python=3.11
conda activate ml-cuda

# ❌ Avoid for ML/CUDA
python -m venv venv-cuda
source venv-cuda/bin/activate
```

### Reuse Existing Conda Installation
**Don't:** Install multiple conda/miniconda/miniforge instances  
**Do:** Use existing installation and create named environments

```bash
# Check existing installation
ls ~/miniconda3 || ls ~/miniforge3

# Create new environment in existing installation
source ~/miniconda3/etc/profile.d/conda.sh
conda create -n project-name python=3.11
```

### Document Environment
Always create `environment.yml` for reproducibility:

```yaml
name: ml-cuda
channels:
  - pytorch
  - nvidia
  - conda-forge
dependencies:
  - python=3.11
  - pytorch::pytorch
  - pytorch::pytorch-cuda=12.1
  - pip:
    - transformers
    - sentence-transformers
```

---

## CUDA Setup

### Set Environment Variables Consistently
Create activation script to set CUDA paths:

```bash
# scripts/activate-ml-env.sh
export CUDA_HOME=/usr/local/cuda
export CUDA_PATH=/usr/local/cuda
export CUDACXX=/usr/local/cuda/bin/nvcc
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### Verify CUDA Before Proceeding
```python
import torch
assert torch.cuda.is_available(), "CUDA not available!"
print(f"GPU: {torch.cuda.get_device_name(0)}")
```

### Match CUDA Versions
- **System CUDA:** `nvcc --version`
- **PyTorch CUDA:** `torch.version.cuda`
- **Should match major version** (e.g., both 12.1)

---

## Compilation Best Practices

### WSL Memory Constraints
WSL has limited memory for compilation. Avoid OOM:

```bash
# Limit parallel jobs
export CMAKE_BUILD_PARALLEL_LEVEL=1

# Or set maximum
export CMAKE_BUILD_PARALLEL_LEVEL=2
```

### Target Specific GPU Architecture
Don't compile for all architectures (wastes memory/time):

```bash
# ❌ Default: All architectures (50, 61, 70, 75, 80, 86, 89)
# Memory usage: ~8GB+ during compilation

# ✅ Specific GPU (RTX 4060 = compute_89)
export NODE_LLAMA_CPP_CUDA_ARCHS="89"
export CMAKE_CUDA_ARCHITECTURES=89
# Memory usage: ~2-4GB during compilation
```

**Find your architecture:**
```bash
nvidia-smi --query-gpu=compute_cap --format=csv,noheader
# Output: 8.9 → use "89"
```

### Monitor During Build
```bash
# Terminal 1: Build
bun install -g package-with-cuda

# Terminal 2: Monitor
watch -n 1 'free -h && nvidia-smi'
```

---

## PyTorch Installation

### Always Use Index URL
Specify CUDA version explicitly:

```bash
# ✅ Correct
pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

# ❌ Wrong (gets CPU-only version)
pip install torch torchvision torchaudio
```

### Verify Installation
```python
import torch

# Check version
print(f"PyTorch: {torch.__version__}")  # Should show +cu121

# Check CUDA
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"GPU count: {torch.cuda.device_count()}")
print(f"GPU name: {torch.cuda.get_device_name(0)}")
```

---

## Common Issues & Solutions

### Issue: "libcudart.so.12 not found"
**Solution:** Set LD_LIBRARY_PATH
```bash
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### Issue: PyTorch not seeing GPU
**Check:**
1. CUDA installed: `nvcc --version`
2. Drivers installed: `nvidia-smi`
3. PyTorch built with CUDA: `torch.version.cuda`
4. Environment variables set

### Issue: CUDA OOM during compilation
**Solutions:**
1. Reduce parallel jobs: `CMAKE_BUILD_PARALLEL_LEVEL=1`
2. Target specific architecture
3. Increase WSL memory limit (`.wslconfig`)
4. Close other applications

### Issue: "prebuilt binary not compatible"
**Expected:** Many CUDA packages must build from source  
**Solution:** Ensure CUDA environment variables set before install

---

## Testing & Validation

### Test Suite
Always create test scripts:

```bash
# scripts/test-env.sh
python -c "import torch; assert torch.cuda.is_available()"
python -c "import transformers; print('✓ Transformers OK')"
nvidia-smi
```

### Benchmark
Compare CPU vs GPU performance:

```python
import torch
import time

# CPU
x = torch.randn(5000, 5000)
start = time.time()
y = torch.mm(x, x)
cpu_time = time.time() - start

# GPU
x = x.cuda()
torch.cuda.synchronize()
start = time.time()
y = torch.mm(x, x)
torch.cuda.synchronize()
gpu_time = time.time() - start

print(f"CPU: {cpu_time:.2f}s, GPU: {gpu_time:.2f}s")
print(f"Speedup: {cpu_time/gpu_time:.1f}x")
```

---

## Project Organization

### Directory Structure
```
project/
├── envs/
│   ├── ml-cuda.yml          # Environment spec
│   └── requirements.txt     # Pip packages
├── scripts/
│   ├── activate-env.sh      # Environment activation
│   ├── setup-cuda.sh        # CUDA environment setup
│   └── test-env.sh          # Validation tests
├── docs/
│   ├── ENVIRONMENT.md       # Setup instructions
│   └── TROUBLESHOOTING.md   # Common issues
└── README.md
```

### Activation Script Template
```bash
#!/bin/bash
# scripts/activate-env.sh

# Activate conda environment
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ml-cuda

# Set CUDA paths
export CUDA_HOME=/usr/local/cuda
export CUDA_PATH=/usr/local/cuda
export CUDACXX=/usr/local/cuda/bin/nvcc
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify
echo "✓ Environment activated"
python -c "import torch; print(f'  GPU: {torch.cuda.get_device_name(0)}')"
```

---

## Reusability

### Make Environments Portable
```bash
# Export environment
conda env export > environment.yml

# Recreate on another machine
conda env create -f environment.yml
```

### Use Base Environment for Multiple Projects
```bash
# Don't create separate env for each project
# Instead, activate base ML env and install project-specific packages

source scripts/activate-ml-cuda.sh
pip install -r project-requirements.txt
```

### Document CUDA-Specific Settings
In `README.md` or `docs/SETUP.md`:
```markdown
## CUDA Requirements
- CUDA 12.1
- GPU: Compute capability 8.9+ (RTX 4060 or better)
- 8GB+ VRAM recommended
- WSL users: Set CMAKE_BUILD_PARALLEL_LEVEL=1
```

---

## Checklist for New ML Project

- [ ] Reuse existing conda installation
- [ ] Create named environment (`ml-cuda`)
- [ ] Install PyTorch with CUDA index URL
- [ ] Set CUDA environment variables via script
- [ ] Verify GPU access with test script
- [ ] Document environment in `environment.yml`
- [ ] Create activation script
- [ ] Test CPU vs GPU performance
- [ ] Document GPU requirements in README

---

## References

- PyTorch CUDA: https://pytorch.org/get-started/locally/
- NVIDIA CUDA: https://developer.nvidia.com/cuda-downloads
- Conda environments: https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html
- GPU architectures: https://en.wikipedia.org/wiki/CUDA#GPUs_supported

---

**Created:** 2026-01-31  
**Based on:** ML-CUDA environment setup experience
