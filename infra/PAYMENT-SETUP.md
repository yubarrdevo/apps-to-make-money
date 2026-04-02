# Payment Processing Setup

Complete guide to configure the payment processing pipeline for ativadata.com.

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    Client     │────▶│    Stripe    │────▶│     n8n      │────▶│   Service    │
│ (landing page)│     │  (payment)   │     │  (webhook)   │     │ (provision)  │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                                                │
                                          ┌─────┴─────┐
                                          ▼           ▼
                                    ┌──────────┐ ┌──────────┐
                                    │  Resend  │ │ Telegram │
                                    │ (email)  │ │ (alert)  │
                                    └──────────┘ └──────────┘
```

### Flow: LLM API Subscription

1. Client visits https://ativadata.com → clicks a plan
2. Stripe Checkout processes the payment
3. Stripe sends `checkout.session.completed` webhook to n8n
4. n8n verifies the webhook signature
5. n8n creates a LiteLLM API key with rate limits
6. n8n sends the API key via email (Resend)
7. n8n sends a Telegram alert to the owner

### Flow: ComfyUI Image Order

1. Client contacts via WhatsApp or landing page
2. Payment processed via Stripe (payment link or invoice)
3. Stripe sends webhook to n8n
4. n8n sends order confirmation email to client
5. n8n sends a Telegram alert with order details
6. Owner processes images in ComfyUI and delivers via email

## Prerequisites

- [Stripe account](https://stripe.com) with products created
- [Resend account](https://resend.com) with `ativadata.com` domain verified
- n8n running with Telegram credential configured
- LiteLLM running (for API subscription flow)

## Step 1: Stripe Configuration

### Products & Prices

Already created (see `infra/stripe-links.md`):

| Plan | Price | Price ID |
|------|-------|----------|
| Básico | R$97/mês | `price_1TFfwZ4igpRBqrATcXJj7myA` |
| Pro | R$297/mês | `price_1TFfwj4igpRBqrAThXwUMUO7` |
| Custom | R$597/mês | `price_1TFfwk4igpRBqrAT0mgh5Rel` |

### Webhook Setup

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://n8n.atividata.com.br/webhook/stripe-webhook`
3. Select events: `checkout.session.completed`
4. Copy the **Signing Secret** (starts with `whsec_`)

### Payment Link Metadata

When creating Stripe payment links, add metadata to identify the plan:

- For LLM API plans: `plan` = `basic` / `pro` / `custom`
- For ComfyUI orders: `package` = `single` / `pack10` / `monthly20` / `monthly50`

## Step 2: Resend Configuration

1. Sign up at [resend.com](https://resend.com)
2. Add and verify domain `ativadata.com`
3. Copy the API key

## Step 3: n8n Environment Variables

Set these in n8n → Settings → Variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `LITELLM_MASTER_KEY` | `sk-9c2d72...` | LiteLLM admin key for generating client keys |
| `TELEGRAM_CHAT_ID` | Your chat ID | For receiving alerts |
| `RESEND_API_KEY` | `re_...` | Resend API key for sending emails |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` | Stripe webhook signing secret |

## Step 4: Import n8n Workflows

Import both workflows via n8n UI (https://n8n.atividata.com.br → Workflows → Import):

1. **LLM API provisioning:** `infra/n8n-workflows/stripe-client-provisioning.json`
   - Webhook path: `/webhook/stripe-webhook`
   - Creates LiteLLM API keys automatically

2. **ComfyUI orders:** `infra/n8n-workflows/comfyui-order-processing.json`
   - Webhook path: `/webhook/comfyui-order`
   - Sends order confirmation + Telegram alert

After importing, activate both workflows.

## Step 5: Deploy Landing Page

```bash
./infra/deploy.sh landing-page
```

Then add to Cloudflare Tunnel config (`~/.cloudflared/config.yml`):

```yaml
- hostname: ativadata.com
  service: http://localhost:8090
```

Add DNS route and restart tunnel:

```bash
cloudflared tunnel route dns 89c19e13-75a3-4b76-8ff8-e66639df30d3 ativadata.com
systemctl --user restart cloudflared
```

## Step 6: Test the Flow

### Test LLM API Flow

```bash
# Simulate a Stripe webhook (use Stripe CLI for real testing)
stripe trigger checkout.session.completed \
  --add checkout_session:metadata[plan]=basic

# Or use Stripe CLI to forward webhooks locally
stripe listen --forward-to https://n8n.atividata.com.br/webhook/stripe-webhook
```

### Test ComfyUI Order Flow

```bash
stripe trigger checkout.session.completed \
  --add checkout_session:metadata[package]=pack10
```

### Verify

1. Check n8n execution history for successful runs
2. Check email inbox for credential/confirmation emails
3. Check Telegram for alerts
4. For LLM API: test the generated API key:

```bash
curl https://api.ativadata.com/v1/chat/completions \
  -H "Authorization: Bearer GENERATED_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"Hello!"}]}'
```

## Webhook Security

Both workflows include Stripe webhook signature verification:

- Validates the `stripe-signature` header using HMAC-SHA256
- Rejects events older than 5 minutes (replay attack protection)
- Falls back gracefully if `STRIPE_WEBHOOK_SECRET` is not set (for development)

Set `STRIPE_WEBHOOK_SECRET` in n8n variables for production use.

## Monitoring

Payment processing is monitored through:

- **n8n execution history** — see all webhook events and processing results
- **Telegram alerts** — instant notification on new orders/subscriptions
- **LiteLLM dashboard** — track API key usage and spending
- **Stripe Dashboard** — payment analytics and customer management

## Troubleshooting

### Webhook not receiving events

1. Check n8n is running: `docker ps | grep n8n`
2. Check Cloudflare Tunnel is up: `pgrep cloudflared`
3. Verify webhook URL in Stripe Dashboard
4. Check n8n execution log for errors

### Email not sending

1. Verify `RESEND_API_KEY` is set in n8n variables
2. Check domain verification status at resend.com
3. Check n8n execution log for Resend API errors

### API key not generated

1. Verify `LITELLM_MASTER_KEY` is set in n8n variables
2. Check LiteLLM is running: `curl http://localhost:4000/health`
3. Check n8n execution log for LiteLLM API errors

### Signature verification failing

1. Ensure `STRIPE_WEBHOOK_SECRET` matches the signing secret in Stripe Dashboard
2. Check server clock is synchronized (NTP)
3. Temporarily remove the secret to debug (development only)
