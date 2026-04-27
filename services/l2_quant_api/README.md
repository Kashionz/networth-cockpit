# L2 Quant API (FastAPI Skeleton)

## Run locally

```bash
cd services/l2_quant_api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

## Endpoints

- `GET /health`
- `POST /analysis/monthly`
- `POST /classify/merchant`

## Optional LLM mode

Set `OPENAI_API_KEY` (and optional `OPENAI_MODEL`) to enable remote LLM output.
If no key is provided, the API always returns a template fallback insight.
