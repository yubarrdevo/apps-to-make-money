# 🚀 Deployment Guide — apps-to-make-money Stack

Complete deployment guide for the home server monetization stack.

---

## 📋 Prerequisites

### Hardware Requirements
- CPU: Multi-core processor (Ryzen 9 or similar recommended)
- RAM: Minimum 32GB (60GB recommended)
- Storage: 500GB+ NVMe SSD
- GPU: NVIDIA GPU with 12GB+ VRAM (RTX 3060 or better)
- Network: High-speed internet (1Gbps+ recommended)

### Software Requirements
- OS: Linux (Ubuntu 22.04 LTS, Linux Mint, or similar)
- Docker & Docker Compose v2
- Python 3.9+
- NVIDIA drivers & CUDA
- Git
- curl

### External Accounts Needed
- Cloudflare account (for tunnel)
- GitHub account (for code repository)
- Telegram account (for alerts)
- Optional: Stripe, Resend, bandwidth sharing platforms

---

## 🛠️ Quick Start Deployment

### Option 1: Automated Full Deployment

```bash
# Clone the repository
cd ~
git clone https://github.com/yubarrdevo/apps-to-make-money.git
cd apps-to-make-money

# Run automated deployment
bash infra/deploy.sh --full
```

This will:
1. ✅ Verify all prerequisites
2. ✅ Create directory structure
3. ✅ Setup environment files
4. ✅ Copy service configurations
5. ✅ Deploy Docker services (n8n, LiteLLM)
6. ✅ Install systemd services (GPU scheduler, Golem)
7. ✅ Install cron jobs (monitoring, backups)
8. ✅ Setup Cloudflare tunnel
9. ✅ Verify deployment

### Option 2: Manual Step-by-Step Deployment

Follow the sections below for manual deployment.

---

## 📂 Step 1: Directory Structure Setup

```bash
# Create main services directory
mkdir -p ~/income-services/{litellm,n8n,vllm,ai-content,bandwidth/money4band,compute,shared/{logs,backups}}

# Clone the repository
cd ~
git clone https://github.com/yubarrdevo/apps-to-make-money.git
```

Directory layout:
```
~/income-services/
├── litellm/          # LiteLLM API gateway
├── n8n/              # n8n automation
├── vllm/             # vLLM GPU inference
├── ai-content/       # ComfyUI
├── bandwidth/        # Bandwidth sharing
├── compute/          # Golem provider
└── shared/
    ├── logs/         # All logs
    ├── backups/      # Backups
    └── .gpu-scheduler.env  # Shared configuration

~/apps-to-make-money/ # This repository
└── infra/            # Infrastructure configs
```

---

## 🔐 Step 2: Environment Configuration

### 2.1 GPU Scheduler & Telegram Configuration

```bash
# Copy template
cp ~/apps-to-make-money/infra/services/shared/.gpu-scheduler.env.example \
   ~/income-services/shared/.gpu-scheduler.env

# Edit with your credentials
nano ~/income-services/shared/.gpu-scheduler.env
```

Fill in:
- `TELEGRAM_TOKEN` - Get from @BotFather on Telegram
- `TELEGRAM_CHAT_ID` - Get from @userinfobot on Telegram

**How to get Telegram credentials:**
1. Open Telegram → search `@BotFather`
2. Send `/newbot` and follow instructions
3. Copy the token (format: `1234567890:ABCdef...`)
4. Search `@userinfobot` → send `/start`
5. Copy the ID number shown

**Test Telegram:**
```bash
source ~/income-services/shared/.gpu-scheduler.env
bash ~/apps-to-make-money/infra/monitoring/telegram-alert.sh "Test alert from yuserver"
```

### 2.2 LiteLLM Configuration

```bash
cd ~/income-services/litellm

# Copy docker-compose
cp ~/apps-to-make-money/infra/services/litellm/docker-compose.yml .

# Create .env file
cat > .env << 'EOF'
DATABASE_URL=postgresql://litellm:9a0ac34fd8e5e7a7e8ebdf53e6dadbd9@litellm-db:5432/litellm
POSTGRES_PASSWORD=9a0ac34fd8e5e7a7e8ebdf53e6dadbd9
EOF

# Create config.yaml (see infra/deploy.sh for full config)
# Or copy from the deploy script
```

### 2.3 n8n Configuration

```bash
cd ~/income-services/n8n

# Copy docker-compose
cp ~/apps-to-make-money/infra/services/n8n/docker-compose.yml .

# Create .env file
cat > .env << EOF
N8N_USER=admin
N8N_PASSWORD=1833d549f04774aa51b5c56b
DB_POSTGRESDB_PASSWORD=dcefd4c5605b426522e3cc3316fef7c8
POSTGRES_PASSWORD=dcefd4c5605b426522e3cc3316fef7c8
N8N_ENCRYPTION_KEY=edc3fc948d0d27ed8aa1db04af452e43f6d585af61e6f47667236cc9fc685605
N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -hex 32)
EOF
```

### 2.4 vLLM Configuration

```bash
cd ~/income-services/vllm

# Copy docker-compose
cp ~/apps-to-make-money/infra/services/vllm/docker-compose.yml .

# vLLM is auto-managed by GPU scheduler, no .env needed
```

---

## 🐳 Step 3: Deploy Docker Services

### Deploy n8n

```bash
cd ~/income-services/n8n
docker compose up -d

# Verify
docker compose ps
docker compose logs -f
```

Access: http://localhost:5678 (or https://n8n.atividata.com.br via tunnel)
Login: admin / 1833d549f04774aa51b5c56b

### Deploy LiteLLM

```bash
cd ~/income-services/litellm
docker compose up -d

# Verify
docker compose ps
curl http://localhost:4000/health
```

Access: http://localhost:4000 (or https://llm.ativadata.com via tunnel)

### vLLM (Auto-Started by GPU Scheduler)

vLLM will be automatically started by the GPU scheduler when needed. Don't start it manually.

---

## ⚙️ Step 4: Install Automation

### Option A: Automated Installation

```bash
cd ~/apps-to-make-money
bash infra/install-automation.sh all
```

### Option B: Manual Installation

#### 4.1 Install Systemd Services

```bash
# Copy service files
sudo cp ~/apps-to-make-money/infra/gpu-scheduler/gpu-scheduler.service /etc/systemd/system/
sudo cp ~/apps-to-make-money/infra/golem/golem-provider.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start GPU scheduler
sudo systemctl enable gpu-scheduler.service
sudo systemctl start gpu-scheduler.service

# Enable and start Golem provider
sudo systemctl enable golem-provider.service
sudo systemctl start golem-provider.service

# Check status
sudo systemctl status gpu-scheduler
sudo systemctl status golem-provider
```

#### 4.2 Install Cloudflare Tunnel (User Service)

```bash
# Create user systemd directory
mkdir -p ~/.config/systemd/user

# Copy cloudflared service
cat > ~/.config/systemd/user/cloudflared.service << 'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloudflared tunnel run income-services
Restart=always
RestartSec=10
StandardOutput=append:/tmp/cloudflared.log
StandardError=append:/tmp/cloudflared.log

[Install]
WantedBy=default.target
EOF

# Reload user systemd
systemctl --user daemon-reload

# Enable and start
systemctl --user enable cloudflared.service
systemctl --user start cloudflared.service

# Check status
systemctl --user status cloudflared
```

#### 4.3 Install Cron Jobs

```bash
# Edit crontab
crontab -e

# Add these lines:
*/15 * * * * bash /home/yuri/apps-to-make-money/infra/monitoring/health-check.sh
0 * * * * bash /home/yuri/apps-to-make-money/infra/monitoring/git-autopush.sh
0 3 1 * * find ~/income-services/shared/logs -name '*.log' -mtime +30 -delete
```

---

## 🌐 Step 5: Configure Cloudflare Tunnel

### 5.1 Create Tunnel

```bash
# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create income-services

# Note the UUID from output (e.g., 89c19e13-75a3-4b76-8ff8-e66639df30d3)
```

### 5.2 Configure Tunnel

```bash
# Copy template
cp ~/apps-to-make-money/infra/cloudflared-config.yml.example ~/.cloudflared/config.yml

# Edit config
nano ~/.cloudflared/config.yml
```

Replace `YOUR_TUNNEL_UUID` with your actual tunnel UUID.

### 5.3 Route DNS

```bash
# Replace YOUR_TUNNEL_UUID with your tunnel UUID
TUNNEL_UUID="your-tunnel-uuid-here"

# Route all domains
cloudflared tunnel route dns $TUNNEL_UUID llm.ativadata.com
cloudflared tunnel route dns $TUNNEL_UUID api.ativadata.com
cloudflared tunnel route dns $TUNNEL_UUID n8n.atividata.com.br
cloudflared tunnel route dns $TUNNEL_UUID studio.atividata.com.br
cloudflared tunnel route dns $TUNNEL_UUID moneyprinter.atividata.com.br
cloudflared tunnel route dns $TUNNEL_UUID moneyprinter-api.atividata.com.br
cloudflared tunnel route dns $TUNNEL_UUID emby.atividata.com.br
cloudflared tunnel route dns $TUNNEL_UUID coolify.atividata.com.br
cloudflared tunnel route dns $TUNNEL_UUID portainer.atividata.com.br
```

### 5.4 Start Tunnel

The tunnel should already be running via the systemd user service. If not:

```bash
systemctl --user start cloudflared
systemctl --user status cloudflared
```

---

## ✅ Step 6: Verify Deployment

### Check Docker Containers

```bash
docker ps

# Should see:
# - n8n
# - n8n-db
# - litellm-proxy
# - litellm-db
```

### Check Systemd Services

```bash
sudo systemctl status gpu-scheduler
sudo systemctl status golem-provider
systemctl --user status cloudflared
```

### Check HTTP Endpoints

```bash
# Local endpoints
curl http://localhost:4000/health  # LiteLLM
curl http://localhost:5678/healthz # n8n
curl http://localhost:11434/api/tags  # Ollama

# Public endpoints (via tunnel)
curl https://llm.ativadata.com/health
curl https://n8n.atividata.com.br/healthz
```

### Check Logs

```bash
# GPU scheduler
journalctl -u gpu-scheduler -f

# Golem provider
journalctl -u golem-provider -f

# Cloudflare tunnel
journalctl --user -u cloudflared -f

# Docker services
docker logs litellm-proxy -f
docker logs n8n -f

# Health check logs
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log
```

---

## 🔧 Step 7: Post-Deployment Configuration

### 7.1 Import n8n Workflows

1. Open https://n8n.atividata.com.br
2. Login: admin / 1833d549f04774aa51b5c56b
3. Go to Workflows → Import from File
4. Import these files:
   - `~/apps-to-make-money/infra/n8n-workflows/daily-video-generator.json`
   - `~/apps-to-make-money/infra/n8n-workflows/stripe-client-provisioning.json`

### 7.2 Configure n8n Variables

In n8n: Settings → Variables, add:
- `LITELLM_MASTER_KEY`: `sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6`
- `TELEGRAM_CHAT_ID`: Your Telegram chat ID
- `RESEND_API_KEY`: Get from resend.com (free tier)

### 7.3 Setup Resend (Email)

1. Go to https://resend.com → Sign up
2. Domains → Add Domain → `ativadata.com`
3. Add DNS records to Cloudflare (TXT + MX records shown by Resend)
4. Verify domain in Resend
5. API Keys → Create API Key
6. Add to n8n variables: `RESEND_API_KEY`

### 7.4 Setup Stripe (Payments)

1. Go to https://stripe.com → Create account
2. Complete identity verification
3. Create products:
   - Básico: R$97/month — "API LLM Privada — 100k tokens/dia"
   - Pro: R$297/month — "API LLM Multi-modelo — 500k tokens/dia"
   - Custom: R$597/month — "Pipeline RAG dedicado"
4. Developers → Webhooks → Add endpoint:
   - URL: `https://n8n.atividata.com.br/webhook/stripe-payment`
   - Events: `checkout.session.completed`, `invoice.payment_succeeded`
5. Copy Webhook Secret → Add to n8n Credentials → Stripe Trigger

---

## 📊 Monitoring & Maintenance

### View Service Status

```bash
# All Docker containers
docker ps

# Systemd services
systemctl status gpu-scheduler
systemctl status golem-provider
systemctl --user status cloudflared

# GPU usage
nvidia-smi

# Disk usage
df -h
```

### View Logs

```bash
# Today's health check
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log

# GPU scheduler
journalctl -u gpu-scheduler -f

# Specific service
docker logs litellm-proxy --tail 100 -f
```

### Manual Health Check

```bash
bash ~/apps-to-make-money/infra/monitoring/health-check.sh
```

### Test Telegram Alerts

```bash
bash ~/apps-to-make-money/infra/monitoring/telegram-alert.sh "Test message"
```

---

## 🔄 Common Operations

### Restart a Service

```bash
# Docker service
cd ~/income-services/litellm
docker compose restart

# Systemd service
sudo systemctl restart gpu-scheduler

# Cloudflare tunnel
systemctl --user restart cloudflared
```

### Update Code

```bash
cd ~/apps-to-make-money
git pull origin main

# If scripts changed, reinstall automation
bash infra/install-automation.sh all
```

### View LiteLLM Usage

```bash
curl http://localhost:4000/spend/logs \
  -H "Authorization: Bearer sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6"
```

### Create LiteLLM API Key for Client

```bash
curl http://localhost:4000/key/generate \
  -H "Authorization: Bearer sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6" \
  -H "Content-Type: application/json" \
  -d '{
    "models": ["gpt-3.5-turbo"],
    "max_budget": 50,
    "duration": "30d"
  }'
```

---

## 🆘 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker logs <container-name>
journalctl -u <service-name> -n 50

# Check if port is already in use
sudo netstat -tulpn | grep <port>

# Restart Docker
sudo systemctl restart docker
```

### GPU Not Available

```bash
# Check NVIDIA drivers
nvidia-smi

# Check Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

### Cloudflare Tunnel Not Working

```bash
# Check status
systemctl --user status cloudflared

# Check logs
journalctl --user -u cloudflared -n 100

# Test tunnel
cloudflared tunnel info income-services

# Restart tunnel
systemctl --user restart cloudflared
```

### n8n Workflows Not Activating

1. Check Telegram credentials are configured in n8n
2. Check n8n variables are set (Settings → Variables)
3. Check workflow configuration
4. Check n8n logs: `docker logs n8n -f`

---

## 🚀 Next Steps

After deployment is complete:

1. ✅ Follow GUIA-COMPLETO.md for revenue stream setup
2. ✅ Read PARA-LEIGOS.md for simple explanations
3. ✅ Setup optional services (ComfyUI, money4band)
4. ✅ Create landing page at ativadata.com
5. ✅ Start client acquisition (LinkedIn, 99freelas)

---

## 📚 Additional Documentation

- **GUIA-COMPLETO.md** - Complete guide for getting clients and revenue
- **PARA-LEIGOS.md** - Simple explanations of all services
- **infra/gpu-scheduler/scheduler.py** - GPU scheduler logic
- **infra/monitoring/health-check.sh** - Health check script
- **.github/copilot-instructions.md** - Complete system reference

---

## 🔐 Security Notes

- All sensitive credentials are in `.env` files (never committed to git)
- `.env` files are in `.gitignore`
- Cloudflare Tunnel provides secure ingress (no open ports)
- Telegram bot tokens should be kept secret
- LiteLLM master key should only be used server-side

---

## 📝 Support & Issues

- GitHub Issues: https://github.com/yubarrdevo/apps-to-make-money/issues
- Documentation updates in this repo

---

*Last updated: 2026-03-27*
*Deployment tested on: Linux Mint, Ubuntu 22.04*
