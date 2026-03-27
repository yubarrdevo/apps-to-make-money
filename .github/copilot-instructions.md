# Copilot Instructions

## Project Overview

Home server monetization stack — **fully automated, zero manual intervention required**.
Server: Linux Mint, hostname `yuserver`, Ryzen 9 9950X (32 threads), 60GB RAM, RTX 3060 12GB, 915GB NVMe, 2Gbps Ethernet.

All services run in Docker, exposed via Cloudflare Tunnel (no open ports). GPU allocation is managed automatically by a systemd daemon.

**GitHub repo:** `yubarrdevo/apps-to-make-money` (private) — auto-commits hourly via cron.
**Sudo password:** `0406`

---

## Domain Strategy

| Domain | Use |
|---|---|
| `ativadata.com` | **Client-facing** — API pública, landing page, o que você mostra/vende |
| `ativadata.com.br` | Já usada pela stack ativadata — **não rotear LiteLLM aqui** |
| `atividata.com.br` | **Infra interna** — nunca mostrar para cliente |

**IMPORTANT:** `api.ativadata.com.br` is already used by another stack. Do NOT route LiteLLM there.

---

## All Credentials

### Server Access
- **Sudo password:** `0406`
- **GitHub account:** `yubarrdevo` (not yuribarreira — no permission there)

### LiteLLM
- **Master key:** `sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6`
- **DB pass:** `9a0ac34fd8e5e7a7e8ebdf53e6dadbd9`
- **vLLM API key:** `bcf27c2b3fe913e8f526af69c9f9253d4539f452dc8caec42e594d27109e4d96`

### n8n
- **URL:** https://n8n.atividata.com.br
- **User:** `admin`
- **Pass:** `1833d549f04774aa51b5c56b`
- **DB pass:** `dcefd4c5605b426522e3cc3316fef7c8`
- **Encryption key:** `edc3fc948d0d27ed8aa1db04af452e43f6d585af61e6f47667236cc9fc685605`
- **API key:** `n8n_api_e2aef1e71eaf733f4f99b413a7786e30d9a7eef2d0cc1a34`

### Telegram (alerts)
- **Token:** `8618280280:AAEDYNbg1zzuZOqgomQwNR13bMucy815sSo`
- **Chat ID:** `8622146441` ⚠️ needs verification — send `/start` to bot then run getUpdates
- **Fix chat_id:**
```bash
source ~/income-services/shared/.gpu-scheduler.env
curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates" | python3 -c "
import sys,json; data=json.load(sys.stdin)
for u in data.get('result',[]):
    chat=u.get('message',{}).get('chat',{})
    print('Chat ID:', chat.get('id'), '| Nome:', chat.get('first_name',''))
"
```

### MoneyPrinter
- **Pexels API key:** `fovKNXvXW326MrNxcdTjOIQSdkI8wg57hK1Sid2SruLs81B1rdD0TUuy`
- **TikTok session:** `01ad420f7f5fea592736854ce3d2d202`

### Cloudflare Tunnel
- **Tunnel name:** `income-services`
- **UUID:** `89c19e13-75a3-4b76-8ff8-e66639df30d3`
- **Config:** `~/.cloudflared/config.yml`

---

## Public URLs (Cloudflare Tunnel)

### Client-Facing
| Service | URL |
|---|---|
| LiteLLM API | https://llm.ativadata.com |
| LiteLLM API (alt) | https://api.ativadata.com |

### Internal Infra
| Service | URL |
|---|---|
| n8n | https://n8n.atividata.com.br |
| ComfyUI | https://studio.atividata.com.br |
| MoneyPrinter UI | https://moneyprinter.atividata.com.br |
| MoneyPrinter API | https://moneyprinter-api.atividata.com.br |
| Emby | https://emby.atividata.com.br |
| Coolify | https://coolify.atividata.com.br |
| Portainer | https://portainer.atividata.com.br |

---

## Port Map (no conflicts)

| Port | Service |
|---|---|
| 8000 | Coolify — **DO NOT use for anything else** |
| 8001 | MoneyPrinter frontend |
| 8002 | vLLM (moved from 8000) |
| 8080 | MoneyPrinter backend |
| 8096 | Emby (host network) |
| 8188 | ComfyUI |
| 4000 | LiteLLM proxy |
| 5678 | n8n |
| 11434 | Ollama (systemd, not Docker) |
| 9443 | Portainer (HTTPS) |

---

## Currently Running Services

```
✅ coolify + coolify-db + coolify-realtime + coolify-redis
✅ n8n + n8n-db
✅ litellm-proxy + litellm-db
✅ backend + frontend + worker + postgres  (MoneyPrinter)
✅ emby
✅ portainer
✅ cloudflared (Coolify-managed, Emby only — separate from our tunnel)
✅ Ollama (systemd)
✅ Golem provider (crontab @reboot, sg kvm)
✅ GPU scheduler (systemd --user)
✅ Cloudflare tunnel income-services (systemd --user)
⏳ ComfyUI — needs: cd ~/income-services/ai-content && docker compose up -d
❌ money4band — needs account credentials in .env
❌ vLLM — auto-started by GPU scheduler on demand
```

---

## Crontab (active)

```
0 4 * * *    ~/income-services/shared/backup-daily.sh
0 5 * * 0    ~/income-services/shared/backup-weekly.sh
0 3 1 * *    find ~/income-services/shared/logs -name '*.log' -mtime +30 -delete
*/15 * * * * bash /home/yuri/apps-to-make-money/infra/monitoring/health-check.sh
@reboot      nohup cloudflared tunnel run income-services > /tmp/cloudflared.log 2>&1 &
0 * * * *    bash /home/yuri/apps-to-make-money/infra/monitoring/git-autopush.sh
@reboot      sleep 30 && sg kvm -c '/home/yuri/.local/bin/golemsp run >> /tmp/golem.log 2>&1' &
```

---

## Cloudflare Tunnel Config (~/.cloudflared/config.yml)

```yaml
tunnel: 89c19e13-75a3-4b76-8ff8-e66639df30d3
credentials-file: /home/yuri/.cloudflared/89c19e13-75a3-4b76-8ff8-e66639df30d3.json

ingress:
  # CLIENT-FACING (ativadata.com)
  - hostname: llm.ativadata.com
    service: http://localhost:4000
  - hostname: api.ativadata.com
    service: http://localhost:4000

  # INTERNAL INFRA (atividata.com.br)
  - hostname: n8n.atividata.com.br
    service: http://localhost:5678
  - hostname: studio.atividata.com.br
    service: http://localhost:8188
  - hostname: moneyprinter.atividata.com.br
    service: http://localhost:8001
  - hostname: moneyprinter-api.atividata.com.br
    service: http://localhost:8080
  - hostname: emby.atividata.com.br
    service: http://localhost:8096
  - hostname: coolify.atividata.com.br
    service: http://localhost:8000
  - hostname: portainer.atividata.com.br
    service: https://localhost:9443
    originRequest:
      noTLSVerify: true
  - service: http_status:404
```

To restart tunnel: `systemctl --user restart cloudflared`
To add DNS: `cloudflared tunnel route dns 89c19e13-75a3-4b76-8ff8-e66639df30d3 sub.domain.com`

**NOTE:** There is a separate Coolify-managed `cloudflared` Docker container (user 65532) pointing only to Emby:8096. Do not touch it.

---

## Automation Architecture

### GPU Scheduler (systemd --user: `gpu-scheduler.service`)
`infra/gpu-scheduler/scheduler.py` — polls every 30s:
- vLLM starts on `gpt-4` requests → stops after 10 min idle
- ComfyUI starts when queue has jobs or 02:00–07:00 (only when vLLM idle)

```bash
systemctl --user status gpu-scheduler
journalctl --user -u gpu-scheduler -f
```

### Client Provisioning (n8n)
Stripe webhook → LiteLLM key → Resend email → Telegram alert. Zero human involvement.
Webhook URL: `https://n8n.atividata.com.br/webhook/stripe-payment`

### Daily Content (n8n)
10 AM daily: LLM topics → MoneyPrinter API → YouTube Shorts → Telegram notify.

---

## Ollama Models

| Model | Size | Alias |
|---|---|---|
| llama3.1:8b | 4.9GB | gpt-3.5-turbo, fast |
| qwen2.5:14b-instruct-q4_K_M | 9.0GB | gpt-4, smart |
| nomic-embed-text | 274MB | embed |
| glm-4.7-flash:latest | 19GB | large |

---

## n8n Workflows

| ID | Name | Status |
|---|---|---|
| `3lCOjSDVxGbD37ti` | Daily Video Generator | imported, needs Telegram cred |
| `HMlgW56UAsEXkPZ3` | Stripe Client Provisioning | imported, needs Telegram + Resend + Stripe creds |

Required n8n variables (Settings → Variables):
- `LITELLM_MASTER_KEY`
- `TELEGRAM_CHAT_ID`
- `RESEND_API_KEY` — get from resend.com (free), verify domain `ativadata.com`

---

## Pending (next session)

1. **Fix Telegram chat_id** — send `/start` to bot → run getUpdates → update `.gpu-scheduler.env`
2. **Resend** — resend.com → verify `ativadata.com` → get API key → n8n variable
3. **Stripe** — create products (R$97/R$297/R$597) → webhook → n8n credential
4. **money4band** — create 7 accounts → fill `~/income-services/bandwidth/money4band/.env` → `python3 main.py` → `docker compose up -d`
5. **ComfyUI** — `cd ~/income-services/ai-content && docker compose up -d`
6. **Landing page** — `ativadata.com` with Stripe payment links
7. **First LinkedIn post** — see GUIA-COMPLETO.md section 2.1

---

## Golem Network

```bash
golemsp status
tail -f /tmp/golem.log
# restart: sg kvm -c "golemsp run" &
```
Node: `yuri-ativadata-node` | 8 cores, 16GiB RAM, 100GiB disk | mainnet ✅ publishing offers

---

## ComfyUI Models (downloaded, not yet serving)

- `~/income-services/ai-content/models/checkpoints/flux1-schnell-fp8.safetensors` (17GB)
- `~/income-services/ai-content/models/checkpoints/sd_xl_base_1.0.safetensors` (6.5GB)
- Image: `yanwk/comfyui-boot:cu130-slim-v2`

---

## money4band (bandwidth sharing — not yet running)

Fill credentials in `~/income-services/bandwidth/money4band/.env`:
Honeygain, EarnApp, Pawns.app, PacketStream, Peer2Profit, Repocket, Grass (needs Phantom wallet)

```bash
cd ~/income-services/bandwidth/money4band
source venvm4b/bin/activate && python3 main.py
docker compose up -d
```

---

## Monitoring

```bash
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log
~/income-services/shared/health-check.sh
~/income-services/shared/telegram-alert.sh "test"
docker ps
nvidia-smi
```

## Project Overview

Home server monetization stack — **fully automated, zero manual intervention required**.
Server: Linux Mint, hostname `yuserver`, Ryzen 9 9950X (32 threads), 60GB RAM, RTX 3060 12GB, 915GB NVMe, 2Gbps Ethernet.

All services run in Docker, exposed via Cloudflare Tunnel (no open ports). GPU allocation is managed automatically by a systemd daemon.

**GitHub repo:** `yubarrdevo/apps-to-make-money` (private) — auto-commits hourly via cron.
**Sudo password:** `0406`

---

## Domain Strategy

| Domain | Use |
|---|---|
| `ativadata.com` | **Client-facing** — API pública, landing page, o que você mostra/vende |
| `ativadata.com.br` | Clientes BR (LGPD, confiança local) — stack ativadata já usa `api.ativadata.com.br` |
| `atividata.com.br` | **Infra interna** — nunca mostrar para cliente |

**IMPORTANT:** `api.ativadata.com.br` is already used by another stack (ativadata). Do NOT route LiteLLM there.

---

## Key Credentials & Endpoints

| Service | Local Port | Public URL (client-facing) | Credentials/Key |
|---|---|---|---|
| LiteLLM (API GW) | 4000 | https://llm.ativadata.com | master: `sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6` |
| n8n | 5678 | https://n8n.atividata.com.br | admin / `1833d549f04774aa51b5c56b` |
| MoneyPrinter UI | 8001 | https://moneyprinter.atividata.com.br | none |
| MoneyPrinter API | 8080 | https://moneyprinter-api.atividata.com.br | none |
| ComfyUI | 8188 | https://studio.atividata.com.br | none |
| Coolify (PaaS) | 8000 | https://coolify.atividata.com.br | configured in Coolify |
| Portainer | 9443 | https://portainer.atividata.com.br | configured in Portainer |
| Emby | 8096 | https://emby.atividata.com.br | configured in Emby |
| Ollama | 11434 | internal only | none |
| vLLM | 8002 | via LiteLLM only | `bcf27c2b…` |

**n8n API key:** `n8n_api_e2aef1e71eaf733f4f99b413a7786e30d9a7eef2d0cc1a34`
**n8n encryption key:** `edc3fc948d0d27ed8aa1db04af452e43f6d585af61e6f47667236cc9fc685605`
**n8n DB pass:** `dcefd4c5605b426522e3cc3316fef7c8`
**LiteLLM DB pass:** in `~/income-services/litellm/.env`
**Pexels API key (MoneyPrinter):** `fovKNXvXW326MrNxcdTjOIQSdkI8wg57hK1Sid2SruLs81B1rdD0TUuy`

---

## Cloudflare Tunnel

Tunnel: `income-services` (UUID: `89c19e13-75a3-4b76-8ff8-e66639df30d3`)
Config: `~/.cloudflared/config.yml`
Runs as: **systemd user service** (`systemctl --user status cloudflared`)

```bash
systemctl --user restart cloudflared
journalctl --user -u cloudflared -n 20
# Add new DNS record:
cloudflared tunnel route dns 89c19e13-75a3-4b76-8ff8-e66639df30d3 sub.domain.com
```

**NOTE:** There is also a Coolify-managed `cloudflared` Docker container (user 65532) pointing only to Emby:8096. That is separate — do not touch it.

**Never expose ports via UFW for public services** — Cloudflare Tunnel is the only ingress.

---

## Telegram (alerts & n8n workflows)

Credentials in `~/income-services/shared/.gpu-scheduler.env`:
- `TELEGRAM_TOKEN` — bot token from @BotFather ✅ set
- `TELEGRAM_CHAT_ID` — needs correct ID from `getUpdates` after sending `/start` to bot

```bash
# Get correct chat_id after sending /start to bot:
source ~/income-services/shared/.gpu-scheduler.env
curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates" | python3 -c "
import sys,json; data=json.load(sys.stdin)
for u in data.get('result',[]):
    chat=u.get('message',{}).get('chat',{})
    print('Chat ID:', chat.get('id'), '| Nome:', chat.get('first_name',''))
"

# Send alert:
~/income-services/shared/telegram-alert.sh "message"
```

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
└── shared/
    ├── .gpu-scheduler.env   # TELEGRAM_TOKEN, TELEGRAM_CHAT_ID
    ├── gpu-lock.sh          # manual GPU management
    ├── health-check.sh      # runs every 15 min via cron
    ├── telegram-alert.sh    # send Telegram message
    └── logs/

~/moneyprinter/       # MoneyPrinter video engine (frontend+backend+worker+postgres)
~/MoneyPrinterV2/     # MoneyPrinterV2 CLI (YouTube Shorts, Twitter bot, affiliate)
~/apps-to-make-money/ # THIS REPO
```

---

## Port Map (critical — no conflicts)

| Port | Service | Notes |
|---|---|---|
| 8000 | Coolify | DO NOT use for anything else |
| 8001 | MoneyPrinter frontend | |
| 8002 | vLLM | moved from 8000 to avoid Coolify conflict |
| 8080 | MoneyPrinter backend (Flask) | |
| 8096 | Emby | host network |
| 8188 | ComfyUI | |
| 4000 | LiteLLM proxy | |
| 5678 | n8n | |
| 11434 | Ollama | systemd, not Docker |
| 9443 | Portainer | HTTPS |

---

## Automation Architecture

### GPU Scheduler (systemd: `gpu-scheduler.service`)
Python daemon (`infra/gpu-scheduler/scheduler.py`) polls every 30s:
- **vLLM starts** when LiteLLM detects `gpt-4` model requests
- **vLLM stops** after 10 min idle
- **ComfyUI starts** when queue has jobs OR 02:00–07:00, only when vLLM idle

```bash
systemctl --user status gpu-scheduler
journalctl --user -u gpu-scheduler -f
```

### Client Provisioning (n8n workflow)
Stripe webhook → parse plan → LiteLLM API key → Resend email → Telegram alert. Zero human involvement.

### Daily Content Engine (n8n workflow)
10 AM daily: LLM generates topics → MoneyPrinter generates YouTube Shorts → Telegram notify.

---

## Ollama Models

```bash
ollama list
# llama3.1:8b (4.9GB) — fast, always available
# qwen2.5:14b-instruct-q4_K_M (9.0GB) — gpt-4 alias
# nomic-embed-text (274MB) — embeddings
# glm-4.7-flash:latest (19GB) — large, high VRAM
```

## LiteLLM Model Aliases

- `gpt-3.5-turbo` / `fast` → Ollama llama3.1:8b
- `gpt-4` / `smart` → vLLM Qwen2.5-14B (GPU, auto-started)
- `embed` → nomic-embed-text

```bash
# Create client API key
curl http://localhost:4000/key/generate \
  -H "Authorization: Bearer sk-9c2d72..." \
  -d '{"models":["gpt-3.5-turbo"],"max_budget":50,"duration":"30d"}'
```

---

## Crontab (active)

```
*/15 * * * *  ~/income-services/shared/health-check.sh
@reboot       nohup cloudflared tunnel run income-services > /tmp/cloudflared.log 2>&1 &
@reboot       sg kvm -c 'golemsp run' > /tmp/golem.log 2>&1 &
0 * * * *     ~/apps-to-make-money/infra/monitoring/git-autopush.sh
```

---

## Golem Network

```bash
# Status
golemsp status
# Restart
sg kvm -c "golemsp run" &
# Logs
tail -f /tmp/golem.log
```
Node: `yuri-ativadata-node` | 8 cores, 16GiB RAM, 100GiB disk | mainnet

---

## ComfyUI

Models downloaded to `~/income-services/ai-content/models/checkpoints/`:
- `flux1-schnell-fp8.safetensors` (17GB)
- `sd_xl_base_1.0.safetensors` (6.5GB)

Image: `yanwk/comfyui-boot:cu130-slim-v2`
```bash
cd ~/income-services/ai-content && docker compose up -d
```

---

## money4band (bandwidth sharing)

Needs account credentials filled in `~/income-services/bandwidth/money4band/.env`:
- Honeygain, EarnApp, Pawns.app, PacketStream, Peer2Profit, Repocket, Grass

```bash
cd ~/income-services/bandwidth/money4band
source venvm4b/bin/activate
python3 main.py   # one-time interactive setup
docker compose up -d
```

---

## n8n Workflows

Imported (both `active=False` until Telegram credential configured in n8n UI):
- `3lCOjSDVxGbD37ti` — Daily Video Generator
- `HMlgW56UAsEXkPZ3` — Stripe Client Provisioning

Required n8n variables (Settings → Variables):
- `LITELLM_MASTER_KEY`
- `TELEGRAM_CHAT_ID`
- `RESEND_API_KEY` (resend.com free — verify `ativadata.com` domain)

Stripe webhook: `https://n8n.atividata.com.br/webhook/stripe-payment`

---

## Revenue Streams

| Stream | Automation | Client URL |
|---|---|---|
| LLM API (R$97-597/mês) | 100% — Stripe → n8n → LiteLLM key → Resend | https://llm.ativadata.com |
| n8n automation services | Semi (build once per client) | https://n8n.atividata.com.br |
| AI content/ComfyUI | 100% GPU scheduler | https://studio.atividata.com.br |
| YouTube Shorts | 100% daily cron | internal |
| Bandwidth sharing | 100% set-and-forget | — |
| Golem compute | 100% | — |

---

## Monitoring

```bash
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log
bash ~/income-services/shared/health-check.sh
docker ps
nvidia-smi
```

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
Golem running ✅. Fix was: user must be in `kvm` group (`sudo usermod -aG kvm yuri`) then run via `sg kvm -c "golemsp run"`.
Node configured: 8 cores, 16GiB RAM, 100GiB disk, node name `yuri-ativadata-node`.

### ComfyUI
Image pulling (`yanwk/comfyui-boot:cu130-slim-v2`). Models already downloaded:
- `~/income-services/ai-content/models/checkpoints/flux1-schnell-fp8.safetensors` (8GB)
- `~/income-services/ai-content/models/checkpoints/sd_xl_base_1.0.safetensors` (6.5GB)
Once image pull completes: `cd ~/income-services/ai-content && docker compose up -d`
