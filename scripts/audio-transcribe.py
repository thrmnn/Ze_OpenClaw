#!/usr/bin/env python3
"""
Local audio transcription using Hugging Face models
Optimized for CPU/limited resources (WSL)
"""

import sys
import argparse
from pathlib import Path

def setup_whisper():
    """Install and setup lightweight Whisper model"""
    try:
        from transformers import pipeline
        import torch
    except ImportError:
        print("Installing required packages...")
        import subprocess
        subprocess.run([
            sys.executable, "-m", "pip", "install", 
            "transformers", "torch", "torchaudio", 
            "--quiet", "--no-cache-dir"
        ], check=True)
        from transformers import pipeline
        import torch
    
    return pipeline

def transcribe_audio(audio_path, model_id="openai/whisper-tiny", language="auto"):
    """
    Transcribe audio file using HF Whisper models
    
    Model options (size vs accuracy trade-off):
    - openai/whisper-tiny (~39M params, fastest, ~1GB RAM)
    - openai/whisper-base (~74M params, good balance, ~1.5GB RAM)
    - openai/whisper-small (~244M params, better quality, ~2GB RAM)
    
    For WSL: recommend tiny or base
    """
    pipeline_fn = setup_whisper()
    
    print(f"Loading model: {model_id}...")
    transcriber = pipeline_fn(
        "automatic-speech-recognition",
        model=model_id,
        device="cpu"  # Force CPU for WSL compatibility
    )
    
    print(f"Transcribing: {audio_path}...")
    
    # Transcribe
    kwargs = {}
    if language != "auto":
        kwargs["language"] = language
    
    result = transcriber(str(audio_path), **kwargs)
    
    return result["text"]

def main():
    parser = argparse.ArgumentParser(description="Transcribe audio files locally")
    parser.add_argument("audio_file", help="Path to audio file")
    parser.add_argument("--model", default="openai/whisper-tiny",
                       choices=["openai/whisper-tiny", "openai/whisper-base", "openai/whisper-small"],
                       help="Whisper model size (default: tiny)")
    parser.add_argument("--language", default="auto", 
                       help="Language code (en, pt, fr) or 'auto' for detection")
    parser.add_argument("--output", "-o", help="Output text file (default: stdout)")
    
    args = parser.parse_args()
    
    audio_path = Path(args.audio_file)
    if not audio_path.exists():
        print(f"Error: File not found: {audio_path}", file=sys.stderr)
        return 1
    
    try:
        text = transcribe_audio(audio_path, model_id=args.model, language=args.language)
        
        if args.output:
            Path(args.output).write_text(text)
            print(f"Transcription saved to: {args.output}")
        else:
            print("\n=== Transcription ===")
            print(text)
        
        return 0
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
