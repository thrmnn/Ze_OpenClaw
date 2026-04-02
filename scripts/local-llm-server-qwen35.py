#!/usr/bin/env python3
"""
Local LLM Server - OpenAI-compatible API for Qwen3.5-0.8B
Uses transformers backend (llama-cpp doesn't support qwen35 architecture yet)
Runs on localhost:8000 for OpenClaw integration
"""

import json
import time
from typing import List, Dict, Any

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import uvicorn

MODEL_ID = "Qwen/Qwen3.5-0.8B"
MODEL_KEY = "qwen3.5-0.8b"
HOST = "127.0.0.1"
PORT = 8000

app = FastAPI(title="Local LLM Server (Qwen3.5-0.8B)", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print(f"Loading {MODEL_ID} on GPU...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
model = AutoModelForCausalLM.from_pretrained(
    MODEL_ID,
    dtype=torch.float16,
    device_map="cuda",
)
model.eval()
print("Model ready!")


@app.get("/")
async def root():
    return {"status": "running", "model": MODEL_KEY}


@app.get("/v1/models")
async def list_models():
    return {
        "object": "list",
        "data": [{"id": MODEL_KEY, "object": "model", "created": 1709251200, "owned_by": "local"}],
    }


@app.post("/v1/chat/completions")
@app.post("/chat/completions")
async def chat_completion(request: Request):
    payload = await request.json()
    return _generate(payload)


@app.post("/v1/completions")
@app.post("/completions")
async def completion(request: Request):
    payload = await request.json()
    return _generate(payload, mode="completion")


def _generate(payload: Dict[str, Any], mode: str = "chat") -> Any:
    try:
        temperature = float(payload.get("temperature", 0.7))
        max_tokens = int(payload.get("max_completion_tokens") or payload.get("max_tokens") or 512)
        messages = _extract_messages(payload)
        if not messages:
            raise HTTPException(status_code=400, detail="Missing messages or prompt")

        text = tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
        inputs = tokenizer(text, return_tensors="pt").to("cuda")
        with torch.no_grad():
            output_ids = model.generate(
                **inputs,
                max_new_tokens=max_tokens,
                temperature=temperature if temperature > 0 else None,
                do_sample=temperature > 0,
                pad_token_id=tokenizer.eos_token_id,
            )
        # Decode only newly generated tokens
        new_ids = output_ids[0][inputs["input_ids"].shape[1]:]
        reply = tokenizer.decode(new_ids, skip_special_tokens=True).strip()

        created = int(time.time())
        prompt_tokens = inputs["input_ids"].shape[1]
        completion_tokens = len(new_ids)

        if mode == "completion":
            return {
                "id": f"cmpl-{created}",
                "object": "text_completion",
                "created": created,
                "model": MODEL_KEY,
                "choices": [{"index": 0, "text": reply, "finish_reason": "stop"}],
                "usage": {
                    "prompt_tokens": prompt_tokens,
                    "completion_tokens": completion_tokens,
                    "total_tokens": prompt_tokens + completion_tokens,
                },
            }

        if payload.get("stream"):
            def _stream():
                chunk = {
                    "id": f"chatcmpl-{created}",
                    "object": "chat.completion.chunk",
                    "created": created,
                    "model": MODEL_KEY,
                    "choices": [{"index": 0, "delta": {"role": "assistant", "content": reply}, "finish_reason": None}],
                }
                yield f"data: {json.dumps(chunk)}\n\n"
                done = {
                    "id": f"chatcmpl-{created}",
                    "object": "chat.completion.chunk",
                    "created": created,
                    "model": MODEL_KEY,
                    "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
                }
                yield f"data: {json.dumps(done)}\n\n"
                yield "data: [DONE]\n\n"
            return StreamingResponse(_stream(), media_type="text/event-stream")

        return {
            "id": f"chatcmpl-{created}",
            "object": "chat.completion",
            "created": created,
            "model": MODEL_KEY,
            "choices": [{"index": 0, "message": {"role": "assistant", "content": reply}, "finish_reason": "stop"}],
            "usage": {
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
                "total_tokens": prompt_tokens + completion_tokens,
            },
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def _extract_messages(payload: Dict[str, Any]) -> List[Dict[str, Any]]:
    messages = payload.get("messages")
    if isinstance(messages, list) and messages:
        return [{"role": m.get("role", "user"), "content": _content_to_str(m.get("content", ""))} for m in messages]
    prompt = payload.get("prompt") or payload.get("input")
    if isinstance(prompt, str) and prompt.strip():
        return [{"role": "user", "content": prompt}]
    return []


def _content_to_str(content: Any) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(p.get("text", "") if isinstance(p, dict) else str(p) for p in content)
    return str(content or "")


if __name__ == "__main__":
    print(f"Starting Qwen3.5-0.8B server on {HOST}:{PORT}")
    uvicorn.run(app, host=HOST, port=PORT)
