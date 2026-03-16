# Whisper Audio Transcription Plan

## Goal
Enable Zé to transcribe voice messages from Telegram automatically using open-source Whisper.

## Options Analysis

### 1. **faster-whisper** (⭐ RECOMMENDED)
- **Pros:** 
  - 4x faster than OpenAI Whisper
  - Lower memory usage
  - Same accuracy
  - Active maintenance
  - Easy Python integration
- **Cons:** Requires CTranslate2 (C++ dependency)
- **Installation:** `pip install faster-whisper`

### 2. **OpenAI Whisper** (original)
- **Pros:**
  - Official implementation
  - Well documented
  - Widely tested
- **Cons:**
  - Slower (not optimized)
  - Higher memory usage
- **Installation:** `pip install openai-whisper`

### 3. **whisper.cpp**
- **Pros:**
  - Fastest (C++ native)
  - Lowest memory
  - No Python needed
- **Cons:**
  - Harder to integrate
  - Requires compilation
  - Less flexible

### 4. **OpenAI API** (cloud)
- **Pros:** 
  - Zero setup
  - Super fast
  - No local compute
- **Cons:**
  - Costs money ($0.006/minute)
  - Privacy concerns
  - Requires internet

---

## Recommended Approach: **faster-whisper**

### Model Size Selection

| Model | Memory | Speed | Accuracy | Use Case |
|-------|--------|-------|----------|----------|
| tiny | ~1 GB | Fastest | Good | Quick messages |
| base | ~1 GB | Very fast | Better | Default choice ⭐ |
| small | ~2 GB | Fast | Great | Accurate transcription |
| medium | ~5 GB | Slower | Excellent | High accuracy needed |
| large | ~10 GB | Slowest | Best | Critical accuracy |

**Recommendation:** Start with `base` (good balance), upgrade to `small` if accuracy issues.

---

## Implementation Plan

### Phase 1: Local Testing (30 min)
1. Install faster-whisper in a venv
2. Test transcription on the audio file you sent
3. Measure speed and accuracy
4. Verify it works in WSL

### Phase 2: Integration with Clawdbot (1-2 hours)
1. Create a transcription helper script
2. Add to Clawdbot's audio handling workflow
3. Cache transcriptions to avoid re-processing
4. Handle multiple languages (auto-detect vs explicit)

### Phase 3: Automation (30 min)
1. Auto-transcribe all voice messages on arrival
2. Store transcription alongside audio
3. Present transcription to Zé in message context

---

## Installation Steps

```bash
# Create virtual environment
cd /home/theo/clawd
python3 -m venv venv-whisper
source venv-whisper/bin/activate

# Install faster-whisper
pip install faster-whisper

# Test on your audio file
python3 << 'EOF'
from faster_whisper import WhisperModel

# Load model (downloads on first run)
model = WhisperModel("base", device="cpu", compute_type="int8")

# Transcribe
segments, info = model.transcribe(
    "/home/theo/.clawdbot/media/inbound/5a513e9b-bafe-4f01-b2c9-21ed689457a5.ogg",
    language="fr"  # or None for auto-detect
)

print(f"Detected language: {info.language} (probability: {info.language_probability})")
for segment in segments:
    print(f"[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}")
EOF
```

---

## Helper Script Design

**Location:** `/home/theo/clawd/scripts/transcribe.sh`

```bash
#!/bin/bash
# Transcribe audio file using faster-whisper

AUDIO_FILE="$1"
LANGUAGE="${2:-auto}"  # default: auto-detect

if [ -z "$AUDIO_FILE" ]; then
    echo "Usage: transcribe.sh <audio-file> [language]"
    exit 1
fi

source /home/theo/clawd/venv-whisper/bin/activate

python3 << EOF
from faster_whisper import WhisperModel
import sys

model = WhisperModel("base", device="cpu", compute_type="int8")
segments, info = model.transcribe("$AUDIO_FILE", language=$([[ "$LANGUAGE" == "auto" ]] && echo "None" || echo "\"$LANGUAGE\""))

for segment in segments:
    print(segment.text.strip(), end=" ")
print()
EOF
```

---

## Integration Points

### 1. Clawdbot Message Handler
When audio arrives:
```javascript
// Pseudocode
if (message.hasAudio()) {
  const audioPath = saveAudio(message.audio);
  const transcription = execSync(`/home/theo/clawd/scripts/transcribe.sh ${audioPath}`).toString();
  message.text = `<audio transcription> ${transcription}`;
}
```

### 2. Cache Transcriptions
Store in `/home/theo/.clawdbot/media/transcriptions/`:
```
5a513e9b-bafe-4f01-b2c9-21ed689457a5.txt
```

Check cache before running Whisper to avoid re-processing.

---

## Performance Expectations

**Base model on typical voice message (5-10 seconds):**
- First run: ~2-3 seconds (model loading)
- Subsequent: ~0.5-1 second (model cached in memory)
- Accuracy: 85-95% for clear audio

**Optimization:**
- Keep model loaded in memory (daemon process?)
- Use `tiny` for real-time, `base` for quality

---

## Testing Checklist

- [ ] Install faster-whisper in venv
- [ ] Transcribe test audio file (the one you sent)
- [ ] Verify French detection works
- [ ] Test English audio
- [ ] Measure speed (base model)
- [ ] Try tiny model for comparison
- [ ] Create transcribe.sh script
- [ ] Test from command line
- [ ] Integrate with Clawdbot (if possible)
- [ ] Add caching mechanism

---

## Alternative: Groq API (Fast & Free Tier)

If local proves too slow or problematic in WSL:
- Groq offers Whisper API
- Free tier: decent limits
- Very fast (optimized inference)
- Privacy: depends on comfort level

---

## Next Steps

1. **Test locally first** - make sure it works in WSL
2. **Benchmark speed** - is it fast enough for your workflow?
3. **Check accuracy** - test with French, English, Portuguese
4. **Decide integration method** - script, daemon, or Clawdbot skill?

---

## Questions to Resolve

1. **WSL compatibility** - does faster-whisper work well in WSL?
2. **Memory constraints** - how much RAM available?
3. **Real-time priority** - do transcriptions need to be instant?
4. **Language detection** - auto-detect or manually specify?
5. **Privacy level** - comfortable with cloud API as fallback?
