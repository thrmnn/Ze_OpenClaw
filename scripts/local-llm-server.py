#!/usr/bin/env python3
"""
Local LLM Server - OpenAI-compatible API for local Qwen models
Runs on localhost:8000 for OpenClaw integration

Usage:
  python local-llm-server.py                        # default: Qwen2.5-14B
  python local-llm-server.py --model qwen3.5-0.8b  # lightweight model
  python local-llm-server.py --model qwen2.5-14b   # explicit 14B
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Any
from llama_cpp import Llama
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import uvicorn
import time

# Model registry
MODELS = {
    "qwen2.5-14b": {
        "path": str(Path.home() / "models" / "Qwen2.5-14B-Instruct-Q4_K_M.gguf"),
        "n_ctx": 32768,
        "n_gpu_layers": 35,  # 35/48 layers fit in 8GB VRAM alongside OS
        "display": "Qwen2.5-14B-Instruct-Q4_K_M",
    },
    "qwen3.5-0.8b": {
        "path": str(Path.home() / "models" / "Qwen3.5-0.8B-Q4_K_M.gguf"),
        "n_ctx": 32768,
        "n_gpu_layers": -1,  # tiny model - all layers in VRAM
        "display": "Qwen3.5-0.8B-Q4_K_M",
    },
}

parser = argparse.ArgumentParser()
parser.add_argument("--model", default="qwen2.5-14b", choices=list(MODELS.keys()))
parser.add_argument("--port", type=int, default=8000)
args = parser.parse_args()

MODEL_KEY = args.model
MODEL_CFG = MODELS[MODEL_KEY]
MODEL_PATH = MODEL_CFG["path"]
HOST = "127.0.0.1"
PORT = args.port
N_CTX = MODEL_CFG["n_ctx"]
N_GPU_LAYERS = MODEL_CFG["n_gpu_layers"]

# Initialize FastAPI
app = FastAPI(title="Local LLM Server", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model
print(f"Loading model: {MODEL_CFG['display']} from {MODEL_PATH}...")
llm = Llama(
    model_path=MODEL_PATH,
    n_ctx=N_CTX,
    n_gpu_layers=N_GPU_LAYERS,
    verbose=True,
    n_threads=8,
)
print("Model loaded successfully!")

@app.get("/")
async def root():
    return {"status": "running", "model": MODEL_CFG["display"]}

@app.get("/v1/models")
async def list_models():
    return {
        "object": "list",
        "data": [
            {
                "id": MODEL_KEY,
                "object": "model",
                "created": 1709251200,
                "owned_by": "local"
            }
        ]
    }

@app.post("/v1/chat/completions")
@app.post("/chat/completions")
async def chat_completion(request: Request):
    payload = await request.json()
    return _generate_openai_response(payload, "chat")

@app.post("/v1/completions")
@app.post("/completions")
async def completion(request: Request):
    payload = await request.json()
    return _generate_openai_response(payload, "completion")

def _generate_openai_response(payload: Dict[str, Any], mode: str) -> Any:
    try:
        model = str(payload.get("model", "qwen2.5-14b"))
        temperature = float(payload.get("temperature", 0.7))
        max_tokens = payload.get("max_completion_tokens") or payload.get("max_tokens") or 2048
        messages = _payload_to_messages(payload)
        if not messages:
            raise HTTPException(status_code=400, detail="Missing messages, prompt, or input")

        prompt = format_qwen_prompt(messages)
        response = llm(
            prompt,
            max_tokens=int(max_tokens),
            temperature=temperature,
            stop=["<|im_end|>", "<|endoftext|>"],
            echo=False
        )
        text = response["choices"][0]["text"].strip()
        usage = response.get("usage", {})
        created = int(time.time())

        if mode == "completion":
            return {
                "id": f"cmpl-{created}",
                "object": "text_completion",
                "created": created,
                "model": model,
                "choices": [
                    {
                        "index": 0,
                        "text": text,
                        "finish_reason": "stop"
                    }
                ],
                "usage": {
                    "prompt_tokens": usage.get("prompt_tokens", 0),
                    "completion_tokens": usage.get("completion_tokens", 0),
                    "total_tokens": usage.get("total_tokens", 0)
                }
            }

        if bool(payload.get("stream")):
            chunk_id = f"chatcmpl-{created}"

            def _event_stream():
                first = {
                    "id": chunk_id,
                    "object": "chat.completion.chunk",
                    "created": created,
                    "model": model,
                    "choices": [
                        {
                            "index": 0,
                            "delta": {"role": "assistant", "content": text},
                            "finish_reason": None
                        }
                    ]
                }
                yield f"data: {json.dumps(first, ensure_ascii=True)}\n\n"

                final = {
                    "id": chunk_id,
                    "object": "chat.completion.chunk",
                    "created": created,
                    "model": model,
                    "choices": [
                        {
                            "index": 0,
                            "delta": {},
                            "finish_reason": "stop"
                        }
                    ]
                }
                yield f"data: {json.dumps(final, ensure_ascii=True)}\n\n"
                yield "data: [DONE]\n\n"

            return StreamingResponse(_event_stream(), media_type="text/event-stream")

        return {
            "id": f"chatcmpl-{created}",
            "object": "chat.completion",
            "created": created,
            "model": model,
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": text
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": usage.get("prompt_tokens", 0),
                "completion_tokens": usage.get("completion_tokens", 0),
                "total_tokens": usage.get("total_tokens", 0)
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def _payload_to_messages(payload: Dict[str, Any]) -> List[Dict[str, Any]]:
    messages = payload.get("messages")
    if isinstance(messages, list) and messages:
        return messages

    prompt = payload.get("prompt")
    if isinstance(prompt, str) and prompt.strip():
        return [{"role": "user", "content": prompt}]

    input_field = payload.get("input")
    if isinstance(input_field, str) and input_field.strip():
        return [{"role": "user", "content": input_field}]
    if isinstance(input_field, list):
        converted: List[Dict[str, Any]] = []
        for item in input_field:
            if isinstance(item, dict) and "role" in item:
                converted.append(item)
            elif isinstance(item, str):
                converted.append({"role": "user", "content": item})
        if converted:
            return converted

    return []

def _message_content_to_text(content: Any) -> str:
    """Convert OpenAI-style content variants to plain text."""
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict):
                # Support OpenAI content parts: [{"type":"text","text":"..."}]
                if item.get("type") == "text":
                    parts.append(str(item.get("text", "")))
                elif "text" in item:
                    parts.append(str(item.get("text", "")))
                elif "content" in item:
                    parts.append(str(item.get("content", "")))
            else:
                parts.append(str(item))
        return "".join(parts)
    if isinstance(content, dict):
        return str(content.get("text", content.get("content", "")))
    return str(content)

def format_qwen_prompt(messages: List[Dict[str, Any]]) -> str:
    """Format messages in Qwen's chat template format"""
    prompt = "<|im_start|>system\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\n"
    
    for msg in messages:
        role = str(msg.get("role", "user"))
        content = _message_content_to_text(msg.get("content"))
        prompt += f"<|im_start|>{role}\n{content}<|im_end|>\n"
    
    prompt += "<|im_start|>assistant\n"
    return prompt

if __name__ == "__main__":
    print(f"Starting Local LLM Server on {HOST}:{PORT}")
    print(f"Model: {MODEL_CFG['display']} ({MODEL_PATH})")
    print(f"Context window: {N_CTX} tokens")
    print(f"GPU layers: {N_GPU_LAYERS} on RTX 4060")
    uvicorn.run(app, host=HOST, port=PORT)
