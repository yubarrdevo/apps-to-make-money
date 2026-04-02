# LiteLLM - Simplified LLM API Gateway

LiteLLM provides an OpenAI-compatible API gateway for local models via Ollama.

## Simplified Architecture

**CPU-Only Setup:**
- Ollama (systemd service) runs on CPU with llama3.1:8b
- LiteLLM proxies requests to Ollama
- No GPU inference, no vLLM
- Simple, reliable, low resource usage

## What It Does

- Provides OpenAI-compatible API endpoint
- Tracks usage and costs per API key
- Manages client API keys and rate limits
- Works with existing OpenAI client libraries

## Setup

### 1. Configure Environment

```bash
cd infra/services/litellm
cp .env.example .env
nano .env  # Set DATABASE_URL password
```

### 2. Ensure Ollama is Running

```bash
# Ollama should be running as systemd service
systemctl status ollama

# Check models are available
ollama list
# Should see: llama3.1:8b, nomic-embed-text
```

### 3. Start LiteLLM

```bash
docker compose up -d
```

### 4. Test

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-9c2d72..." \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Client API Keys

### Create New Client Key

```bash
curl http://localhost:4000/key/generate \
  -H "Authorization: Bearer sk-9c2d72b2..." \
  -H "Content-Type: application/json" \
  -d '{
    "models": ["gpt-3.5-turbo"],
    "max_budget": 50,
    "duration": "30d",
    "key_alias": "client-name"
  }'
```

### View Usage

```bash
curl http://localhost:4000/spend/logs \
  -H "Authorization: Bearer sk-9c2d72b2..."
```

## Available Models

| Client Uses | Backend | Speed | Use Case |
|-------------|---------|-------|----------|
| `gpt-3.5-turbo` | llama3.1:8b | Fast | General chat, simple tasks |
| `fast` | llama3.1:8b | Fast | Alias for quick access |
| `text-embedding-ada-002` | nomic-embed-text | Very fast | Embeddings |
| `embed` | nomic-embed-text | Very fast | Embeddings alias |

## Public Access

Exposed via Cloudflare Tunnel:
- https://llm.ativadata.com
- https://api.ativadata.com

Both point to `localhost:4000`

## Client Integration

Python example:

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://llm.ativadata.com/v1",
    api_key="sk-client-key-here"
)

response = client.chat.completions.create(
    model="gpt-3.5-turbo",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

## Revenue Model

**Basic Plan - R$97/month:**
- Access to gpt-3.5-turbo (llama3.1:8b)
- 100k tokens/day limit
- Email support

**Pro Plan - R$297/month:**
- Higher rate limits (500k tokens/day)
- Priority support
- Custom integrations

**Target:** 3-5 clients = R$291-1,485/month recurring revenue

## Notes

- **No GPU required** - all models run on CPU via Ollama
- **Simple maintenance** - no complex GPU scheduling
- **Reliable** - systemd ensures Ollama always runs
- **Cost-effective** - no cloud API costs

## Monitoring

```bash
# Check status
docker ps | grep litellm

# View logs
docker logs litellm-proxy --tail 50

# Check database
docker exec -it litellm-db psql -U litellm -d litellm -c "SELECT COUNT(*) FROM spend_logs;"
```

## Troubleshooting

**"Connection refused" to Ollama:**
```bash
# Check Ollama is running
systemctl status ollama

# Test direct access
curl http://localhost:11434/api/tags
```

**Database connection error:**
```bash
# Check database is healthy
docker exec litellm-db pg_isready -U litellm
```

---

**Focus:** LiteLLM is supporting infrastructure for optional API revenue. ComfyUI is the primary focus.
