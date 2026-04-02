# 🎯 ComfyUI Revenue Stack - Focused & Profitable

> **Philosophy:** One service, mastered. ComfyUI for AI image generation. Everything else is support.

**Server:** yuserver | Linux Mint | Ryzen 9 9950X (32 cores), 60GB RAM, RTX 3060 12GB
**Primary Revenue:** ComfyUI image generation for e-commerce
**Secondary:** n8n automation services (optional), LiteLLM API (optional)

---

## 🎨 Why ComfyUI First?

| Factor | ComfyUI | LLM API | Other Services |
|--------|---------|---------|----------------|
| **Revenue per Client** | R$497/month | R$97-297/month | Variable |
| **Client Demand** | High (e-commerce sellers) | Medium | Low-Medium |
| **Competition** | Low (technical barrier) | High | Very High |
| **Your Time** | 30 min/day | 5 min/day | Variable |
| **Setup Complexity** | Low | Low | High |
| **Scalability** | High (can handle 10+ clients) | Medium | Low |

**Bottom line:** ComfyUI delivers R$2,000-4,000/month with 3-5 clients and <30 min/day work.

---

## 📂 Repository Structure

```
apps-to-make-money/
├── infra/
│   ├── services/
│   │   ├── comfyui/          # 🎯 PRIMARY - Image generation
│   │   ├── landing-page/     # 🌐 Client-facing website (ativadata.com)
│   │   ├── n8n/              # Automation workflows
│   │   └── litellm/          # Optional LLM API gateway
│   ├── monitoring/           # Health checks, Telegram alerts
│   ├── n8n-workflows/        # Pre-built automation workflows
│   ├── PAYMENT-SETUP.md      # Payment processing setup guide
│   └── stripe-links.md       # Stripe payment links & IDs
├── GUIA-COMPLETO.md         # Complete operational guide (PT-BR)
├── PARA-LEIGOS.md           # Non-technical explanation (PT-BR)
└── README.md                # This file
```

---

## 🚀 Quick Start (15 Minutes)

### 1. Start ComfyUI

```bash
cd infra/services/comfyui

# Download model (one-time, ~8GB)
mkdir -p models/checkpoints
cd models/checkpoints
wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell-fp8.safetensors
cd ../..

# Start service
docker compose up -d

# Access
open http://localhost:8188
```

### 2. Start Supporting Services (Optional)

```bash
# n8n (for automation)
cd ../n8n
cp .env.example .env
docker compose up -d

# LiteLLM (for API business)
cd ../litellm
cp .env.example .env
nano .env  # Set database password
docker compose up -d
```

### 3. Get Your First Client

See [`infra/services/comfyui/README.md`](infra/services/comfyui/README.md) for:
- Where to find clients (Mercado Livre sellers, Facebook groups)
- Sales scripts (Portuguese)
- Pricing strategies
- Workflow optimization

**Target:** 3 clients in first month = R$1,500/month

---

## 💰 Revenue Projections (Conservative)

### Month 1-2: R$1,000-2,000
- 2-3 ComfyUI clients (one-time or monthly starter)
- Focus: Perfect workflow, get testimonials
- Time: 1-2 hours/week

### Month 3-6: R$3,000-5,000
- 5-8 ComfyUI monthly clients
- 1-2 n8n automation projects (if interested)
- Time: 2-3 hours/week

### Month 6+: R$5,000-8,000
- 10+ ComfyUI clients (can handle with batch processing)
- Recurring n8n retainers
- Consider hiring VA for client communication
- Time: 3-5 hours/week (mostly processing)

**Passive Income (runs separately):**
- Golem compute: R$100-400/month
- Bandwidth sharing: R$100-200/month

---

## 🏗️ Architecture (Simplified)

```
┌─────────────────────────────────────────────┐
│  CLIENT                                     │
│  Sends product photo via WhatsApp/email    │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  YOU (15-30 min/day)                        │
│  - Load image in ComfyUI                    │
│  - Apply workflow (white bg, lifestyle)     │
│  - Generate variations                      │
│  - Export images                            │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  COMFYUI (GPU)                              │
│  RTX 3060 12GB                              │
│  - Processes 15-30 sec/image                │
│  - FLUX.1-schnell model                     │
│  - Outputs to ./output/                     │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  DELIVERY                                   │
│  Google Drive link or email attachment      │
│  (can automate with n8n later)             │
└─────────────────────────────────────────────┘
```

**Optional Services:**
- **n8n:** Automate client notifications, order processing, payment provisioning
- **LiteLLM + Ollama:** Sell LLM API access (secondary revenue)
- **Landing Page:** Client-facing website at ativadata.com with pricing & payment links

---

## 💳 Payment Processing

Fully automated payment pipeline — zero manual intervention for API subscriptions:

1. **Landing page** (ativadata.com) shows services and pricing
2. **Stripe** processes payments via payment links
3. **n8n** receives webhooks and provisions services automatically
4. **Resend** sends credentials/confirmation emails
5. **Telegram** alerts owner of new orders

### Setup

```bash
# Deploy landing page
./infra/deploy.sh landing-page

# Import n8n workflows
# See infra/PAYMENT-SETUP.md for complete instructions
```

See [`infra/PAYMENT-SETUP.md`](infra/PAYMENT-SETUP.md) for complete setup.

---

## 🎯 Focus Strategy

### Do This (High ROI)

1. **Master ComfyUI workflows** for common e-commerce needs:
   - White background product photos
   - Lifestyle/scene placement
   - Batch processing
   - Quick variations

2. **Build client acquisition** system:
   - Daily: Check Mercado Livre for bad product photos
   - 2x/week: Post in Facebook e-commerce groups
   - Weekly: Refine pitch based on what works

3. **Optimize delivery process**:
   - Templates for common products (shoes, electronics, etc.)
   - Batch processing for multi-product clients
   - Google Drive folders per client

### Don't Do This (Low ROI / Distraction)

1. ❌ Setting up complex GPU scheduling
2. ❌ Running multiple GPU services (vLLM, MoneyPrinter, etc.)
3. ❌ Building features clients didn't ask for
4. ❌ Competing on price (compete on quality/speed instead)
5. ❌ Chasing latest AI models (FLUX.1-schnell is good enough)

---

## 📊 Monitoring

### Daily Check (1 minute)

```bash
# Is ComfyUI running?
docker ps | grep comfyui

# GPU temperature OK?
nvidia-smi
```

### Automated (every 15 min via cron)

```bash
# Health check runs automatically
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log
```

Telegram alerts configured in `infra/monitoring/telegram-alert.sh`

---

## 📚 Documentation

| File | Purpose | Language |
|------|---------|----------|
| [`infra/services/comfyui/README.md`](infra/services/comfyui/README.md) | ComfyUI setup, client acquisition, workflows | EN |
| [`infra/services/landing-page/README.md`](infra/services/landing-page/README.md) | Landing page deployment | EN |
| [`infra/services/n8n/README.md`](infra/services/n8n/README.md) | n8n automation setup | EN |
| [`infra/services/litellm/README.md`](infra/services/litellm/README.md) | LiteLLM API gateway setup | EN |
| [`infra/PAYMENT-SETUP.md`](infra/PAYMENT-SETUP.md) | Payment processing setup guide | EN |
| [`infra/stripe-links.md`](infra/stripe-links.md) | Stripe payment links & price IDs | EN |
| [`GUIA-COMPLETO.md`](GUIA-COMPLETO.md) | Complete operational guide | PT-BR |
| [`PARA-LEIGOS.md`](PARA-LEIGOS.md) | Non-technical explanation | PT-BR |

---

## 🆘 Troubleshooting

### ComfyUI Won't Start

```bash
# Check GPU availability
nvidia-smi

# Check logs
docker logs comfyui

# Restart
cd infra/services/comfyui
docker compose restart
```

### Out of Disk Space

```bash
# Clean old Docker images
docker system prune -a

# Check model sizes
du -sh infra/services/comfyui/models/*

# Clean old outputs
rm -rf infra/services/comfyui/output/old-*
```

### Need Help?

1. Check service-specific README in `infra/services/<service>/`
2. Review `GUIA-COMPLETO.md` for Portuguese documentation
3. Check health logs: `~/income-services/shared/logs/`

---

## 🎓 Learning Path

**Week 1:** Master ComfyUI basics
- Load images, apply workflows
- Understand nodes (Load Image → Remove BG → Save)
- Generate 20 sample images (practice)

**Week 2:** Get first clients
- Identify 10 Mercado Livre sellers with bad photos
- Send 10 DMs with offer
- Close 1-2 clients

**Week 3:** Optimize workflow
- Create templates for common categories
- Set up batch processing
- Reduce per-image time to <2 min

**Week 4:** Scale
- Aim for 5 active clients
- Set up recurring monthly packages
- Consider n8n automation for intake

---

## 🔐 Security Notes

- All `.env` files are gitignored (secrets never committed)
- Use `.env.example` as templates
- Cloudflare Tunnel (no open ports)
- ComfyUI has no authentication (internal only, Cloudflare for public)

---

## 🤝 Contributing

This is a personal revenue project, but you can:
- Fork for your own setup
- Open issues for bugs
- Share workflow optimizations

---

## 📄 License

MIT License - Use for your own income generation

---

**Last Updated:** 2026-04-02
**Status:** ✅ Payment processing fully automated
**Next Milestone:** 5 active ComfyUI clients (R$2,500/month)
