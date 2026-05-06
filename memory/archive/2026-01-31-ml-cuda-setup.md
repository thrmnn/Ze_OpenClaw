# ML-CUDA Environment Setup - 2026-01-31

## Goal
Create robust, reusable ML/AI environment with PyTorch + CUDA 12.1 support for QMD and future projects.

---

## Environment Setup ✅

### Conda Environment: ml-cuda
- **Location:** `~/miniconda3/envs/ml-cuda`
- **Python:** 3.11.14
- **PyTorch:** 2.5.1+cu121
- **CUDA:** 12.1
- **GPU:** NVIDIA GeForce RTX 4060 Laptop GPU (8GB VRAM)

### Installation
```bash
# Created from existing miniconda3
conda create -n ml-cuda python=3.11 -y
conda activate ml-cuda
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Verification
```python
import torch
torch.cuda.is_available()  # True
torch.cuda.get_device_name(0)  # 'NVIDIA GeForce RTX 4060 Laptop GPU'
```

**Status:** ✅ PyTorch + CUDA working perfectly

---

## QMD CUDA Build ⏳

### Challenge
QMD uses node-llama-cpp which needs to compile from source with CUDA support.

### Initial Attempts
1. **Attempt 1:** Default build with all CUDA architectures
   - Result: SIGKILL (OOM during compilation)
   - Issue: Compiling for multiple GPU architectures (50-89) uses too much memory in WSL

2. **Attempt 2:** Limited to RTX 4060 architecture (compute_89), 4 parallel jobs
   - Result: Build started but CUDA libraries not generated
   - Issue: Still hitting memory limits

### Current Approach (In Progress)
```bash
export NODE_LLAMA_CPP_CUDA_ARCHS="89"  # RTX 4060 only
export CMAKE_ARGS="-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=89"
export CMAKE_BUILD_PARALLEL_LEVEL=1  # Sequential build to avoid OOM
bun install -g https://github.com/tobi/qmd
```

**Status:** ⏳ Building (slow but should avoid OOM)

---

## Documentation Created

### Scripts
1. `scripts/activate-ml-cuda.sh` - One-command environment activation
   - Activates conda env
   - Sets CUDA environment variables
   - Verifies setup
   
2. `scripts/build-qmd-cuda.sh` - Automated QMD CUDA build
   - Clean, build, test workflow
   - Proper CUDA flags
   
3. `scripts/test-qmd-cuda.sh` - Performance benchmarking
   - BM25 search (CPU baseline)
   - Vector search (GPU test)
   - Embedding performance
   - GPU monitoring

### Documentation
1. `docs/ML-CUDA-ENV.md` - Complete environment guide
   - Installation instructions
   - Usage examples
   - Troubleshooting
   - Best practices
   
2. `envs/ml-cuda.yml` - Environment specification (for future reproducibility)

---

## Reusability

### Key Principles Followed
1. ✅ Uses existing miniconda3 (not a separate install)
2. ✅ Reproducible via conda environment
3. ✅ Proper CUDA environment variables in activation script
4. ✅ Documented for future projects
5. ✅ Portable across ML/AI workloads

### For Future Projects
```bash
# Activate for any ML project
source ~/clawd/scripts/activate-ml-cuda.sh

# Or clone environment
conda create --name new-project --clone ml-cuda
```

---

## Next Steps (After Build Completes)

1. **Verify CUDA Build**
   ```bash
   ls ~/.bun/install/global/node_modules/node-llama-cpp/llama/localBuilds/linux-x64-cuda/bin/
   # Should see libggml-cuda.so
   ```

2. **Test Performance**
   ```bash
   chmod +x ~/clawd/scripts/test-qmd-cuda.sh
   ~/clawd/scripts/test-qmd-cuda.sh
   ```

3. **Re-generate Embeddings with GPU**
   ```bash
   cd ~/clawd
   qmd embed -f
   # Monitor: watch -n 1 nvidia-smi
   ```

4. **Benchmark CPU vs CUDA**
   - Embedding speed: Expect 5-10x speedup
   - Vector search: Expect 3-5x speedup
   - Document results

5. **Update Documentation**
   - Add benchmark results
   - Note any WSL-specific issues
   - Document optimal build settings

---

## Lessons Learned

### WSL Memory Constraints
- CUDA compilation is memory-intensive
- Need to limit parallel jobs in WSL
- Building for single GPU architecture reduces memory usage significantly

### node-llama-cpp Build Process
- Prebuilt binaries not compatible with WSL CUDA setup
- Must build from source
- CMAKE_BUILD_PARALLEL_LEVEL=1 is key for avoiding OOM
- Target specific GPU architecture with NODE_LLAMA_CPP_CUDA_ARCHS

### Best Practices
1. Always use conda for ML environments (better than venv for CUDA)
2. Set CUDA environment variables consistently via script
3. Document build flags for reproducibility
4. Test incrementally (PyTorch first, then complex builds)
5. Monitor GPU during compilation (nvidia-smi)

---

## Files Created

### Configuration
- `envs/ml-cuda.yml` - Environment specification

### Scripts
- `scripts/activate-ml-cuda.sh` - Environment activation
- `scripts/build-qmd-cuda.sh` - QMD CUDA build
- `scripts/test-qmd-cuda.sh` - Performance testing

### Documentation
- `docs/ML-CUDA-ENV.md` - Full environment guide
- `docs/CUDA-SETUP.md` - CUDA configuration (created earlier)
- `docs/QMD-USAGE.md` - QMD usage guide (created earlier)
- `memory/2026-01-31-ml-cuda-setup.md` - This file

---

**Status:** Environment ready ✅, QMD CUDA build in progress ⏳

**Expected Completion:** ~15-30 minutes (sequential build)

**Next Update:** When build completes and tests pass
