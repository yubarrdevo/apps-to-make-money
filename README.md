# 💰 Apps to Make Money — Home Server Monetization Stack

**Fully automated home server stack generating R$3,000-8,000/month with ~1 hour/week of active work.**

---

## 🎯 What Is This?

A complete infrastructure for monetizing a home server through:

1. **LLM API Services** (R$97-597/month per client)
   - Private AI API hosted in Brazil (LGPD compliant)
   - OpenAI-compatible endpoint via LiteLLM
   - Auto-provisioning via Stripe webhooks

2. **n8n Automation Services** (R$500-2,500/project + R$297-797/month retainer)
   - Workflow automation for businesses
   - Newsletter generation with AI curation
   - Price monitoring and alerts

3. **AI Content Generation** (R$15-497/package)
   - Product photography via ComfyUI
   - YouTube Shorts via MoneyPrinter
   - Automated daily content creation

4. **Passive Income Streams** (R$200-600/month)
   - Golem Network compute sharing
   - Bandwidth sharing (Honeygain, EarnApp, etc.)
   - 100% automated, zero maintenance

---

## 🚀 Quick Start

### Prerequisites

- Linux server with NVIDIA GPU (RTX 3060 or better)
- 32GB+ RAM, 500GB+ storage
- Docker, Python 3.9+, NVIDIA drivers
- Cloudflare account (for tunnel)

### Deploy Everything

```bash
# Clone repository
git clone https://github.com/yubarrdevo/apps-to-make-money.git
cd apps-to-make-money

# Run automated deployment
bash infra/deploy.sh --full
```

That's it! The script will:
- ✅ Setup all services (n8n, LiteLLM, vLLM, monitoring)
- ✅ Install systemd services (GPU scheduler, Golem)
- ✅ Configure cron jobs (health checks, backups, auto-commit)
- ✅ Setup Cloudflare tunnel
- ✅ Verify everything is running

---

## 📚 Documentation

- **[DEPLOY.md](DEPLOY.md)** - Complete deployment guide
- **[GUIA-COMPLETO.md](GUIA-COMPLETO.md)** - How to get clients and make money (Portuguese)
- **[PARA-LEIGOS.md](PARA-LEIGOS.md)** - Simple explanations for non-technical users (Portuguese)
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** - Complete system reference

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Cloudflare Tunnel (no open ports)                          │
│  ├─ llm.ativadata.com       → LiteLLM (4000)   [PUBLIC]    │
│  ├─ api.ativadata.com       → LiteLLM (4000)   [PUBLIC]    │
│  ├─ n8n.atividata.com.br    → n8n (5678)       [INTERNAL]  │
│  ├─ studio.atividata.com.br → ComfyUI (8188)   [INTERNAL]  │
│  └─ ... (more internal services)                            │
└─────────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐         ┌─────▼─────┐      ┌─────▼──────┐
   │ LiteLLM │         │    n8n    │      │  ComfyUI   │
   │  Proxy  │         │ Automation│      │  (on GPU)  │
   └────┬────┘         └─────┬─────┘      └────────────┘
        │                    │
   ┌────┴─────┬──────────────┴──────┬──────────────┐
   │          │                     │              │
┌──▼──┐   ┌──▼───┐          ┌──────▼──────┐  ┌───▼────┐
│Ollama│   │ vLLM │          │MoneyPrinter │  │ Stripe │
│(CPU) │   │(GPU) │          │   Videos    │  │Webhook │
└──────┘   └──┬───┘          └─────────────┘  └────────┘
              │
        ┌─────▼──────┐
        │GPU Scheduler│  ← Auto-manages GPU allocation
        └────────────┘
```

### Key Components

- **LiteLLM**: OpenAI-compatible API gateway (routes to Ollama/vLLM)
- **n8n**: Automation platform (client provisioning, content generation)
- **vLLM**: GPU-accelerated LLM inference (auto-started on demand)
- **ComfyUI**: AI image generation (product photos)
- **MoneyPrinter**: Automated YouTube Shorts generation
- **GPU Scheduler**: Intelligent GPU allocation (vLLM → ComfyUI → Golem)
- **Golem Provider**: Decentralized compute sharing

---

## 🔧 What's Automated

| Task | Frequency | Script |
|------|-----------|--------|
| GPU allocation (vLLM/ComfyUI) | Every 30s | GPU Scheduler (systemd) |
| Health monitoring | Every 15 min | health-check.sh (cron) |
| Git auto-commit | Hourly | git-autopush.sh (cron) |
| Client provisioning | On payment | n8n workflow (Stripe webhook) |
| Daily content generation | 10 AM daily | n8n workflow (scheduled) |
| Golem compute sharing | 24/7 | golem-provider (systemd) |
| Telegram alerts | Real-time | All monitoring scripts |

**Zero manual intervention required after setup.**

---

## 💡 Revenue Streams

### Month 1-2 (getting started)
- Golem + bandwidth: R$200
- 1 API client: R$97
- 1 n8n project: R$800
- Photo packages: R$450
- **Total: ~R$1,550/month**

### Month 3-6 (growing)
- Golem + bandwidth: R$300
- 3 API clients: R$991
- 2 n8n retainers: R$800
- 3 price monitors: R$891
- Content services: R$600
- **Total: ~R$3,576/month**

### Month 6+ (autopilot)
- Golem + bandwidth: R$400
- 5 API clients: R$1,485
- 3 n8n retainers: R$1,500
- 5 monitors: R$1,485
- Content + YouTube: R$1,300
- **Total: ~R$6,558/month**

**With less than 1 hour/week of active work** (just bringing in clients).

---

## 🎮 Service Management

### View Status
```bash
docker ps                          # Docker containers
systemctl status gpu-scheduler     # GPU scheduler
systemctl --user status cloudflared # Cloudflare tunnel
nvidia-smi                         # GPU usage
```

### View Logs
```bash
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log
journalctl -u gpu-scheduler -f
docker logs litellm-proxy -f
```

### Restart Services
```bash
cd ~/income-services/litellm && docker compose restart
systemctl restart gpu-scheduler
systemctl --user restart cloudflared
```

---

## 🔐 Security

- All services behind Cloudflare Tunnel (no exposed ports)
- Secrets in `.env` files (not in git)
- HTTPS everywhere via Cloudflare
- Telegram alerts for anomalies
- Automated health checks

---

## 📊 Public Endpoints

### Client-Facing (safe to share)
- `https://llm.ativadata.com` - LLM API
- `https://api.ativadata.com` - LLM API (alt)

### Internal Admin (never share)
- `https://n8n.atividata.com.br` - n8n automation
- `https://studio.atividata.com.br` - ComfyUI
- All other `*.atividata.com.br` subdomains

---

## 🤝 Contributing

This is a private repository for the yuserver monetization stack. For issues or improvements:

1. Open an issue
2. Document the problem
3. Propose a solution

---

## 📝 License

Private repository - all rights reserved.

---

## 🆘 Support

- Full deployment guide: [DEPLOY.md](DEPLOY.md)
- Revenue guide: [GUIA-COMPLETO.md](GUIA-COMPLETO.md)
- System reference: [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

**Built for yuserver | Ryzen 9 9950X | RTX 3060 12GB | 60GB RAM | 2Gbps**
