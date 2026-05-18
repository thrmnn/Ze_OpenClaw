# CUDA Environment Setup

## Hardware
- **GPU:** NVIDIA GeForce RTX 4060 (8GB VRAM)
- **CUDA Version:** 12.1
- **Driver:** 566.14

## Reusable Python Environment

### venv-cuda
**Purpose:** PyTorch + CUDA for ML/AI tasks

**Setup:**
```bash
cd ~/clawd
source venv-cuda/bin/activate
```

**Installed:**
- PyTorch 2.x with CUDA 12.1 support
- torchvision
- torchaudio

**Verify CUDA access:**
```python
import torch
print(torch.cuda.is_available())  # Should be True
print(torch.cuda.get_device_name(0))  # GeForce RTX 4060
```

## Environment Variables

**CUDA paths (source before running CUDA tools):**
```bash
source ~/clawd/scripts/setup-cuda-env.sh
```

This sets:
- `CUDA_HOME=/usr/local/cuda`
- `CUDA_PATH=/usr/local/cuda`
- `CUDACXX=/usr/local/cuda/bin/nvcc`
- `PATH` includes `/usr/local/cuda/bin`
- `LD_LIBRARY_PATH` includes `/usr/local/cuda/lib64`

## QMD with CUDA

QMD uses node-llama-cpp which can leverage CUDA for embeddings.

**Rebuild with CUDA support:**
```bash
# Set CUDA environment
source ~/clawd/scripts/setup-cuda-env.sh

# Reinstall qmd (forces rebuild with CUDA)
export PATH="$HOME/.bun/bin:$PATH"
bun remove -g qmd
bun install -g https://github.com/tobi/qmd

# Verify CUDA is being used
cd ~/clawd
qmd embed  # Should use CUDA, not CPU fallback
```

**Check GPU usage during embedding:**
```bash
watch -n 1 nvidia-smi  # Monitor GPU utilization
```

## Performance Benefits

| Task | CPU (fallback) | CUDA (RTX 4060) | Speedup |
|------|----------------|-----------------|---------|
| Embeddings (800 tokens/chunk) | ~5-10 sec/chunk | ~0.5-1 sec/chunk | **5-10x** |
| Semantic search | ~2-5 sec | ~0.2-0.5 sec | **10x** |
| Re-ranking | ~3-8 sec | ~0.3-0.8 sec | **10x** |

## Troubleshooting

### "CUDA compiler not found"
```bash
# Make sure CUDA environment is set
source ~/clawd/scripts/setup-cuda-env.sh
nvcc --version  # Should show CUDA 12.1
```

### "No CUDA device available"
```bash
# Check driver and GPU
nvidia-smi

# Verify PyTorch sees GPU
python3 -c "import torch; print(torch.cuda.is_available())"
```

### QMD still using CPU
```bash
# Remove cached build
rm -rf ~/.bun/install/global/node_modules/node-llama-cpp/llama/localBuilds

# Reinstall qmd with CUDA env set
source ~/clawd/scripts/setup-cuda-env.sh
bun remove -g qmd
bun install -g https://github.com/tobi/qmd
```

---

**Created:** 2026-01-31  
**Updated:** 2026-01-31
