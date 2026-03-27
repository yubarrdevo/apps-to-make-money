# Copilot Instructions

## Project Overview

Home server monetization stack — **fully automated, zero manual intervention required**.
Server: Linux Mint, hostname `yuserver`, Ryzen 9 9950X (32 threads), 60GB RAM, RTX 3060 12GB, 915GB NVMe, 2Gbps Ethernet.

All services run in Docker, exposed via Cloudflare Tunnel (no open ports). GPU allocation is managed automatically by a systemd daemon.

---

## Key Credentials & Endpoints

| Service | Local URL | Public URL | Credentials/Key |
|---|---|---|---|
| Coolify (PaaS) | localhost:8000 | coolify.ativadata.com.br | configured in Coolify |
| LiteLLM (API GW) | localhost:4000 | api.ativadata.com / api.ativadata.com.br / api.atividata.com.br | `sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6` |
| n8n | localhost:5678 | n8n.ativadata.com.br / n8n.atividata.com.br | admin / 1833d549f04774aa51b5c56b |
| Ollama | localhost:11434 | (internal only — not public) | none |
| vLLM | localhost:8002 | via LiteLLM only | bcf27c2b… |
| MoneyPrinter UI | localhost:8001 | moneyprinter.ativadata.com.br | none |
| MoneyPrinter API | localhost:8080 | moneyprinter-api.ativadata.com.br | none |
| ComfyUI | localhost:8188 | studio.atividata.com.br | none |
| Portainer | localhost:9443 | portainer.ativadata.com.br | configured in Portainer |

---

## Directory Layout

```
~/income-services/
├── litellm/          # LiteLLM proxy (API key mgmt, usage tracking)
├── n8n/              # n8n + PostgreSQL automation
├── vllm/             # vLLM GPU inference (auto-managed by GPU scheduler)
├── ai-content/       # ComfyUI image gen (auto-managed by GPU scheduler)
├── bandwidth/        # money4band passive income stack
├── compute/          # Golem, Nosana decentralized compute
├── ollama/           # Caddy config (Ollama runs as systemd, not Docker)
└── shared/
    ├── .gpu-scheduler.env   # secrets for GPU scheduler + Telegram
    ├── logs/                # health-YYYYMMDD.log, gpu-scheduler.log
    └── backups/

~/moneyprinter/       # MoneyPrinter video engine (frontend+backend+worker+postgres)
~/MoneyPrinterV2/     # MoneyPrinterV2 CLI (YouTube Shorts, Twitter bot, affiliate)
~/llama.cpp/          # llama.cpp build (alternative inference)

~/apps-to-make-money/ # THIS REPO — infra configs, n8n workflows, monitoring
├── infra/
│   ├── gpu-scheduler/scheduler.py       # GPU automation daemon
│   ├── gpu-scheduler/gpu-scheduler.service  # systemd unit (installed)
│   ├── monitoring/health-check.sh       # runs every 15 min via cron
│   ├── monitoring/telegram-alert.sh     # send Telegram alert
│   └── n8n-workflows/                   # import these via n8n UI
│       ├── daily-video-generator.json   # LLM topics → MoneyPrinter → notify
│       └── stripe-client-provisioning.json  # payment → API key → email
```

---

## Automation Architecture

Everything is automated — no manual GPU switching, no manual client provisioning.

### GPU Scheduler (systemd: `gpu-scheduler.service`)
Python daemon (`infra/gpu-scheduler/scheduler.py`) polls every 30s:
- **vLLM starts** when LiteLLM detects `gpt-4` model requests (paid clients)
- **vLLM stops** after 10 min idle → GPU freed
- **ComfyUI starts** when queue has jobs OR during 02:00–07:00 (content window), only when vLLM is not running
- Sends Telegram alerts on all state changes

```bash
sudo systemctl status gpu-scheduler    # check status
sudo journalctl -u gpu-scheduler -f   # live logs
```

### Client Provisioning (n8n: `stripe-client-provisioning.json`)
Stripe webhook → parse plan → create LiteLLM API key with limits → email credentials via Resend → Telegram alert. Zero human involvement.

### Daily Content Engine (n8n: `daily-video-generator.json`)
10 AM daily: LLM generates 3 viral topics → MoneyPrinter API generates 3 YouTube Shorts → Telegram notification.

---

## Service Stack Details

### LiteLLM — The Only Public LLM Endpoint
All external LLM traffic goes through LiteLLM at port 4000. Direct Ollama/vLLM access is internal only.

Model aliases (clients use these):
- `gpt-3.5-turbo` / `fast` → Ollama llama3.1:8b (always available, CPU can handle)
- `gpt-4` / `smart` → vLLM Qwen2.5-14B-AWQ (GPU required, auto-started by scheduler)

Manage keys via LiteLLM API:
```bash
# Create client key
curl http://localhost:4000/key/generate \
  -H "Authorization: Bearer sk-9c2d72..." \
  -d '{"models":["gpt-3.5-turbo"],"max_budget":50,"duration":"30d"}'

# Check usage
curl http://localhost:4000/spend/logs -H "Authorization: Bearer sk-9c2d72..."
```

### MoneyPrinter — Video Content Engine
Queue-based YouTube Shorts generator. Trigger via API:
```bash
curl -X POST http://localhost:8080/api/generate \
  -H "Content-Type: application/json" \
  -d '{"videoSubject": "5 AI tools replacing jobs in 2025", "model": "llama3.1:8b"}'
# Returns: {"jobId": "...", "status": "success"}

# Poll job status
curl http://localhost:8080/api/jobs/{jobId}
```

### Ollama — Local LLM (systemd, always running)
```bash
systemctl status ollama
ollama list          # installed models
ollama pull <model>  # add model
```
Current models: `llama3.1:8b`, `glm-4.7-flash:latest`

### MoneyPrinterV2 — Advanced Automation (Twitter/YouTube/Affiliate)
CLI tool in `~/MoneyPrinterV2/`. Config pre-set: model=`llama3.1:8b`, imagemagick=`/usr/bin/convert`, headless=true.
Run specific jobs:
```bash
cd ~/MoneyPrinterV2 && source venv/bin/activate
python src/cron.py youtube <account_uuid> llama3.1:8b
python src/cron.py twitter <account_uuid> llama3.1:8b
```
Accounts stored in `~/MoneyPrinterV2/.mp/youtube.json` and `.mp/twitter.json`. Firefox profiles must be pre-authenticated.

---

## Docker Patterns

Each service in `~/income-services/` has its own `docker-compose.yml` + `.env`. Always `cd` first:
```bash
cd ~/income-services/n8n && docker compose up -d
cd ~/income-services/litellm && docker compose logs -f
```

GPU services use `deploy.resources.reservations.devices` (NOT `runtime: nvidia` at top level):
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

**vLLM uses host port 8002** (Coolify owns 8000, MoneyPrinter backend owns 8080).

Secrets: always in `.env` files, never hardcoded. Generate with `openssl rand -hex 32`.

---

## Cloudflare Tunnel

Tunnel: `income-services` (UUID: `89c19e13-75a3-4b76-8ff8-e66639df30d3`)
Config: `~/.cloudflared/config.yml`

Cloudflared runs as a background process (PID varies). On reboot, `@reboot` cron restarts it.
To restart manually:
```bash
kill $(pgrep cloudflared) && nohup cloudflared tunnel run income-services > /tmp/cloudflared.log 2>&1 &
```

**Never expose ports via UFW for public services** — Cloudflare Tunnel is the only ingress.

---

## Domains

| Domain | Use |
|---|---|
| `ativadata.com` | International brand |
| `ativadata.com.br` | Brazilian market |
| `atividata.com.br` | Brazilian brand (primary active) |

Subdomains are defined in `~/.cloudflared/config.yml`.

---

## Monitoring

Health check runs every 15 min:
```bash
# View today's health log
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log

# Run manually
bash ~/apps-to-make-money/infra/monitoring/health-check.sh

# Send Telegram alert manually
bash ~/apps-to-make-money/infra/monitoring/telegram-alert.sh "test message"
```

Set `TELEGRAM_TOKEN` and `TELEGRAM_CHAT_ID` in `~/income-services/shared/.gpu-scheduler.env` to enable alerts.

---

## Revenue Streams

| Stream | How | Automation Level |
|---|---|---|
| LLM API subscriptions | LiteLLM + Stripe → n8n auto-provisions | 100% |
| YouTube Shorts | n8n triggers MoneyPrinter daily | 100% |
| n8n automation services | Client pays → n8n workflow runs | Semi (client setup once) |
| AI content (ComfyUI) | GPU scheduler manages, n8n triggers | 100% |
| Bandwidth sharing | money4band Docker stack, set-and-forget | 100% |
| Decentralized compute | Golem/Nosana fill GPU/CPU idle | 100% |

---

## n8n Workflows Setup

Import via n8n UI (https://n8n.atividata.com.br) → Workflows → Import from File:
1. `infra/n8n-workflows/daily-video-generator.json` — daily YouTube Shorts
2. `infra/n8n-workflows/stripe-client-provisioning.json` — Stripe → API key → email

Required n8n environment variables (set in n8n Settings → Variables):
- `LITELLM_MASTER_KEY` — LiteLLM master key
- `TELEGRAM_CHAT_ID` — your Telegram chat ID
- `RESEND_API_KEY` — for sending credential emails (resend.com, free tier)

---

## Credentials Needed to Unlock Full Automation

Set these to activate all alerting and provisioning:

```bash
# Edit this file:
nano ~/income-services/shared/.gpu-scheduler.env
```

| Variable | Where to get it | Used by |
|---|---|---|
| `TELEGRAM_TOKEN` | @BotFather on Telegram | GPU scheduler alerts, health check, n8n |
| `TELEGRAM_CHAT_ID` | @userinfobot on Telegram | Same as above |
| `RESEND_API_KEY` | resend.com (free tier) | Stripe → email API credentials |

Then set in n8n (https://n8n.atividata.com.br → Settings → Variables):
- `TELEGRAM_CHAT_ID`
- `RESEND_API_KEY`

### money4band (bandwidth sharing)
Fill account credentials in `~/income-services/bandwidth/money4band/.env`, then:
```bash
cd ~/income-services/bandwidth/money4band
source venvm4b/bin/activate
python3 main.py   # one-time interactive setup, generates docker-compose.yml
docker compose up -d
```

### Golem Network
Golem provider installed (`golemsp` + `yagna` in `~/.local/bin/`). Testnet initialized.
Known issue: golemsp 0.17.6 crashes (exit 11) after connecting — upstream bug.
Workaround: re-run `curl -sSf https://join.golem.network/as-provider | bash` when they release a fix.
Node configured: 8 cores, 16GiB RAM, 100GiB disk, node name `yuri-ativadata-node`.

### ComfyUI
Image pulling (`yanwk/comfyui-boot:cu130-slim-v2`). Models already downloaded:
- `~/income-services/ai-content/models/checkpoints/flux1-schnell-fp8.safetensors` (8GB)
- `~/income-services/ai-content/models/checkpoints/sd_xl_base_1.0.safetensors` (6.5GB)
Once image pull completes: `cd ~/income-services/ai-content && docker compose up -d`
