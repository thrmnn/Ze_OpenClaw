# Project — AI Agency MVP

> Extracted from MEMORY.md on 2026-04-02

## Location & Stack
- Location: `~/projects/ai-agency/mvp/`
- Stack: Qdrant (Docker) + LlamaIndex + OpenAI embeddings + Claude + Streamlit
- UI at: http://localhost:8501

## Launch
```bash
docker-compose up -d
pip install -r requirements.txt
python ingest.py
streamlit run app.py
```

## Credentials
- OpenAI key: `~/clawd/credentials/openai-api-key.txt` + `~/projects/ai-agency/mvp/.env`
- Needs `.env` with OPENAI_API_KEY + ANTHROPIC_API_KEY

## Demo Materials
- `DEMO_SCRIPT.md`, `PITCH_DECK_OUTLINE.md`, `sample_queries.md`
- Makefile + tests + `.env.example` all created

## Outreach (2026-03-19)
- Outreach tracker created
- 3 LinkedIn DMs drafted: Hyperlex, Leeway, Predictice (French legal-tech)
- Pitch angle: RAG for legal document processing
- Upwork profile polish + pitch deck + cold email in progress

## Status
- Production-ready MVP as of 2026-03-18
- Current priority: maintenance mode (job hunt takes 70% of energy)
