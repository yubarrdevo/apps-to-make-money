# Notes for Local Run on yuserver

Everything in this repo can be committed and pushed by the agent.
The commands below **must be run manually on yuserver** because they either
require server-side state (running containers, GPU, systemd) or secrets that
live outside the repo.

---

## 1 — Pull the latest repo changes

```bash
cd ~/apps-to-make-money
git pull
```

---

## 2 — Full automated deployment (run once on a fresh machine)

```bash
cd ~/apps-to-make-money/infra
bash deploy.sh --full
```

This will:
- Create `~/income-services/{litellm,n8n,vllm,ai-content,...}` directories
- Write `.env` files with the real credentials
- Start n8n + LiteLLM via docker compose
- Install `gpu-scheduler.service` and `golem-provider.service` as system services
- Install cron jobs (health-check, git-autopush, log-cleanup)
- Install Cloudflare tunnel as a systemd user service

If services are already running, use targeted modes instead:

```bash
bash deploy.sh --services     # restart Docker services only
bash deploy.sh --automation   # reinstall systemd + cron only
bash deploy.sh --verify       # check that everything is up
```

---

## 3 — Copy vLLM config to the service directory

`deploy.sh` already does this automatically, but if you need to do it manually:

```bash
cp ~/apps-to-make-money/infra/services/vllm/docker-compose.yml \
   ~/income-services/vllm/docker-compose.yml
```

vLLM is **not** started here — the GPU scheduler starts it on demand when
a `gpt-4` request arrives.

---

## 4 — Fix Telegram chat_id (required for all alerts)

```bash
source ~/income-services/shared/.gpu-scheduler.env
curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates" | python3 -c "
import sys,json; data=json.load(sys.stdin)
for u in data.get('result',[]):
    chat=u.get('message',{}).get('chat',{})
    print('Chat ID:', chat.get('id'), '| Nome:', chat.get('first_name',''))
"
```

Then update the file:

```bash
nano ~/income-services/shared/.gpu-scheduler.env
# Set: TELEGRAM_CHAT_ID=<the id from above>
```

Restart the GPU scheduler to pick up the new value:

```bash
sudo systemctl restart gpu-scheduler
```

---

## 5 — Start ComfyUI + download models

```bash
# Download models (skips files that already exist)
bash ~/apps-to-make-money/infra/services/comfyui/download-models.sh

# Start ComfyUI
cd ~/income-services/ai-content
docker compose up -d
```

---

## 6 — Verify everything is healthy

```bash
bash ~/apps-to-make-money/infra/deploy.sh --verify

# Individual checks
docker ps
nvidia-smi
sudo systemctl status gpu-scheduler
systemctl --user status cloudflared
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log
```

---

## 7 — GPU scheduler logs

```bash
sudo journalctl -u gpu-scheduler -f
# or
tail -f ~/income-services/shared/logs/gpu-scheduler.log
```

---

## 8 — Resend (email delivery for client onboarding)

1. Go to https://resend.com → sign up
2. Verify domain `ativadata.com` — add TXT and MX records in Cloudflare
3. Create an API key
4. In n8n (https://n8n.atividata.com.br) → Settings → Variables → add `RESEND_API_KEY`

---

## 9 — Stripe (payment processing)

1. Go to https://stripe.com → create account → verify identity
2. Create 3 products: R$97 / R$297 / R$597 per month
3. Add webhook:
   - URL: `https://n8n.atividata.com.br/webhook/stripe-payment`
   - Events: `checkout.session.completed`, `invoice.payment_succeeded`
4. Copy the webhook signing secret into n8n → Credentials → Stripe

---

## 10 — Activate n8n workflows

After Telegram + Resend + Stripe credentials are all set in n8n:

1. Open https://n8n.atividata.com.br
2. Workflows → `Daily Video Generator` → toggle Active ✅
3. Workflows → `Stripe Client Provisioning` → toggle Active ✅

---

## 11 — money4band (bandwidth sharing passive income)

```bash
cd ~/income-services/bandwidth/money4band
nano .env   # fill in Honeygain, EarnApp, Pawns.app, PacketStream, Peer2Profit, Repocket, Grass creds
source venvm4b/bin/activate
python3 main.py   # one-time interactive setup → generates docker-compose.yml
docker compose up -d
```

---

## 12 — Landing page

The HTML is at `infra/services/landing-page/index.html`.  
Add a DNS record and Cloudflare tunnel route, then start the container:

```bash
cloudflared tunnel route dns 89c19e13-75a3-4b76-8ff8-e66639df30d3 ativadata.com
# Add to ~/.cloudflared/config.yml under ingress (before the catch-all):
#   - hostname: ativadata.com
#     service: http://localhost:3000

cp ~/apps-to-make-money/infra/services/landing-page/docker-compose.yml \
   ~/income-services/landing-page/docker-compose.yml
cp ~/apps-to-make-money/infra/services/landing-page/index.html \
   ~/income-services/landing-page/index.html
cp ~/apps-to-make-money/infra/services/landing-page/nginx.conf \
   ~/income-services/landing-page/nginx.conf

cd ~/income-services/landing-page
docker compose up -d

systemctl --user restart cloudflared
```
