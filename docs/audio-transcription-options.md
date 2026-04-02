# Audio Transcription Options - Technical Analysis

**Date:** 2026-01-28  
**Context:** Voice message transcription for Telegram integration  
**Test file:** `/home/theo/.clawdbot/media/inbound/18a79d1f-0c38-4c34-b5d8-a38435461050.ogg`

---

## Problem Statement

Need reliable audio transcription for Telegram voice messages in a WSL environment with limited resources.

## Attempted Solutions

### ❌ Hugging Face Transformers + Whisper (Local)
**Status:** Failed due to dependency conflicts

**Issues encountered:**
- Python 3.8 + numpy version incompatibility
- TensorFlow/transformers API mismatches
- `numpy.typeDict` deprecated in numpy 2.x
- Memory constraints (~2GB for model loading)

**Dependencies attempted:**
```bash
pip3 install transformers torch torchaudio
```

**Errors:**
```
RuntimeError: module compiled against API version 0xf but this version of numpy is 0xd
Failed to import transformers.pipelines
module 'numpy' has no attribute 'typeDict'
```

**Conclusion:** Not viable in current WSL Python 3.8 environment without major dependency cleanup.

---

## Recommended Solutions

### ✅ Option 1: OpenAI Whisper API (Recommended)
**Best for:** Reliability, simplicity, no local setup

**Pros:**
- No local dependencies
- Fast and accurate
- Multilingual support (FR/EN/PT)
- Simple API integration
- Proven reliability

**Cons:**
- Requires OpenAI API key
- Cost: ~$0.006/minute (voice messages typically <1 min = <$0.01)

**Implementation:**
```python
import openai
from pathlib import Path

def transcribe_audio(audio_path):
    with open(audio_path, 'rb') as audio_file:
        transcript = openai.Audio.transcribe(
            model="whisper-1",
            file=audio_file
        )
    return transcript.text
```

**Setup:**
1. Get OpenAI API key
2. Save to `credentials/openai.env`
3. Update `scripts/audio-transcribe.py` to use API

**Cost estimate:** 
- Average voice message: 30 seconds
- ~100 messages/month = $0.30/month
- Negligible cost for your use case

---

### ✅ Option 2: Groq Whisper API
**Best for:** Free tier, fast inference

**Pros:**
- Free tier available
- Very fast inference (faster than OpenAI)
- Same Whisper model
- Good for testing

**Cons:**
- Requires Groq API key
- Free tier limits (may change)
- Less established than OpenAI

**Implementation:**
```python
from groq import Groq

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def transcribe_audio(audio_path):
    with open(audio_path, "rb") as file:
        transcription = client.audio.transcriptions.create(
            file=(audio_path, file.read()),
            model="whisper-large-v3",
            response_format="text"
        )
    return transcription
```

**Setup:**
1. Get Groq API key: https://console.groq.com
2. Save to `credentials/groq.env`
3. Update transcription script

**Free tier:** Check current limits on Groq website

---

### ⚠️ Option 3: faster-whisper (Local)
**Best for:** Privacy, offline usage

**Pros:**
- Runs locally (privacy)
- CTranslate2 backend (faster than transformers)
- No API costs
- Offline capable

**Cons:**
- Still requires local setup (~1-2GB)
- WSL environment challenges
- May hit same dependency issues
- Slower than API options

**Implementation:**
```python
from faster_whisper import WhisperModel

model = WhisperModel("tiny", device="cpu")

def transcribe_audio(audio_path):
    segments, info = model.transcribe(audio_path)
    return " ".join([segment.text for segment in segments])
```

**Setup:**
1. Install: `pip install faster-whisper`
2. First run downloads model (~39MB for tiny)

**Worth trying if:** You have strict privacy requirements or need offline capability.

---

### ❌ Option 4: Local Transformers (Attempted)
**Status:** Not recommended

Already attempted and failed due to WSL Python 3.8 dependency conflicts. Would require:
- Python environment upgrade (3.10+)
- Complete dependency cleanup
- Significant troubleshooting time

**Not worth the effort** given API options are simpler and more reliable.

---

## Recommendation Matrix

| Use Case | Best Option | Reason |
|----------|-------------|--------|
| Production (default) | **OpenAI API** | Most reliable, trivial cost |
| Testing/Development | **Groq API** | Free tier, fast |
| Privacy-critical | **faster-whisper** | Local processing |
| Offline requirement | **faster-whisper** | No internet needed |

---

## Proposed Implementation

### Phase 1: Quick Win (Today)
Use **OpenAI Whisper API** for immediate functionality:

```bash
# Setup
echo "OPENAI_API_KEY=your_key" > credentials/openai.env

# Update script
scripts/audio-transcribe-api.py
```

### Phase 2: Optional Optimization (Later)
If privacy or cost becomes a concern:
- Test `faster-whisper` in a clean Python 3.10+ venv
- Profile performance and reliability
- Switch if benefits outweigh setup complexity

---

## Next Steps

**Immediate:**
1. ✅ Document options (this file)
2. ⏸️ Get OpenAI API key (or use existing if available)
3. ⏸️ Create `scripts/audio-transcribe-api.py` using OpenAI
4. ⏸️ Test with voice message `18a79d1f-0c38-4c34-b5d8-a38435461050.ogg`
5. ⏸️ Integrate into Telegram handler

**Future:**
- Monitor API costs (should be <$1/month)
- Consider faster-whisper if usage scales significantly
- Add language detection for auto-language selection

---

## Technical Notes

**Audio format:** Telegram sends `.ogg` (Opus codec)  
**Supported by:** All options (OpenAI, Groq, Whisper models)  
**No conversion needed**

**Languages needed:** French, English, Portuguese  
**All Whisper models support multilingual**

**Average transcription time:**
- OpenAI API: ~2-5 seconds
- Groq API: ~1-2 seconds
- Local (faster-whisper tiny): ~10-15 seconds on CPU

---

## Conclusion

**Go with OpenAI Whisper API.** It's the pragmatic choice:
- Works immediately (no dependency hell)
- Reliable and accurate
- Cost is negligible for your use case (~$0.30/month)
- Frees up time for more impactful work

The local solution would be a distraction at this stage. Focus on functionality first, optimize later if needed.
