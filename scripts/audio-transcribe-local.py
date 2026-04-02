#!/usr/bin/env python3
"""
Local audio transcription using faster-whisper
Privacy-focused, runs offline on CPU
"""

import sys
import argparse
from pathlib import Path

def setup_faster_whisper():
    """Install and setup faster-whisper"""
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print("Installing faster-whisper...")
        import subprocess
        subprocess.run([
            sys.executable, "-m", "pip", "install", 
            "faster-whisper", 
            "--quiet"
        ], check=True)
        from faster_whisper import WhisperModel
    
    return WhisperModel

def transcribe_audio(audio_path, model_size="tiny", language=None):
    """
    Transcribe audio file using faster-whisper
    
    Model sizes (speed vs accuracy):
    - tiny: ~39MB, fastest (recommended for WSL)
    - base: ~74MB, good balance
    - small: ~244MB, better quality
    - medium: ~769MB, high quality (slow on CPU)
    - large-v3: ~1550MB, best quality (very slow on CPU)
    
    For WSL: recommend tiny or base
    """
    WhisperModel = setup_faster_whisper()
    
    print(f"Loading model: {model_size} (this may take a minute on first run)...")
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    
    print(f"Transcribing: {audio_path}...")
    
    # Transcribe
    kwargs = {}
    if language:
        kwargs["language"] = language
    
    segments, info = model.transcribe(str(audio_path), beam_size=5, **kwargs)
    
    # Detected language
    if not language:
        print(f"Detected language: {info.language} (probability: {info.language_probability:.2f})")
    
    # Combine segments
    text = " ".join([segment.text for segment in segments])
    
    return text

def main():
    parser = argparse.ArgumentParser(description="Transcribe audio files locally (faster-whisper)")
    parser.add_argument("audio_file", help="Path to audio file")
    parser.add_argument("--model", default="tiny",
                       choices=["tiny", "base", "small", "medium", "large-v3"],
                       help="Whisper model size (default: tiny)")
    parser.add_argument("--language", 
                       help="Language code (en, pt, fr) or auto-detect if not specified")
    parser.add_argument("--output", "-o", help="Output text file (default: stdout)")
    
    args = parser.parse_args()
    
    audio_path = Path(args.audio_file)
    if not audio_path.exists():
        print(f"Error: File not found: {audio_path}", file=sys.stderr)
        return 1
    
    try:
        text = transcribe_audio(audio_path, model_size=args.model, language=args.language)
        
        if args.output:
            Path(args.output).write_text(text)
            print(f"\n✅ Transcription saved to: {args.output}")
        else:
            print("\n=== Transcription ===")
            print(text)
        
        return 0
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())
