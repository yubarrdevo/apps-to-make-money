# n8n - Workflow Automation Platform

n8n is a **supporting service** for automating client workflows and business processes.

## What It Does

- Automates repetitive tasks (email responses, notifications, data processing)
- Connects different services (Stripe → LiteLLM → Resend email)
- Schedules recurring jobs (daily content generation, reports)
- Webhook endpoints for integrations

## Use Cases for This Stack

### 1. ComfyUI Client Management

**Client Upload Notification:**
- Client uploads image to Google Drive → n8n detects → Telegram alert
- Automatic folder organization per client
- Track pending vs. completed work

**Auto-Delivery:**
- ComfyUI finishes → n8n moves files to Google Drive → sends email with link
- No manual file management

### 2. API Client Provisioning (LiteLLM)

**Stripe → API Key → Email (Fully Automated):**
1. Client pays via Stripe
2. Webhook triggers n8n workflow
3. n8n calls LiteLLM API to create key
4. n8n sends credentials via Resend email
5. Telegram notification for tracking

**Zero manual intervention per client.**

### 3. Revenue Monitoring

**Daily Report:**
- Aggregate ComfyUI orders processed
- LiteLLM API usage by client
- Telegram summary every evening

## Setup

### 1. Configure Environment

```bash
cd infra/services/n8n
cp .env.example .env
nano .env
```

Set:
- `N8N_USER` - Your username (default: admin)
- `N8N_PASSWORD` - Strong password
- `DB_POSTGRESDB_PASSWORD` - Database password

### 2. Start Service

```bash
docker compose up -d
```

### 3. Access

- Local: http://localhost:5678
- Public (via Cloudflare Tunnel): https://n8n.atividata.com.br

Login with credentials from `.env`

### 4. Import Workflows

Workflows are in `infra/n8n-workflows/`:

1. Open n8n UI
2. Click **Workflows** → **Import from File**
3. Select workflow JSON file
4. Configure credentials (Telegram, Resend, LiteLLM)
5. Activate workflow

## Available Workflows

### `stripe-client-provisioning.json`
Automates client onboarding for LiteLLM API:
- Listens for Stripe webhook
- Creates API key in LiteLLM
- Sends credentials via email
- Notifies you via Telegram

### `daily-video-generator.json`
(Optional - if you add video services later)
Generates YouTube Shorts automatically

## Configuration

### Required Credentials

Configure these in n8n UI (Settings → Credentials):

1. **Telegram**
   - Token: Get from @BotFather
   - Chat ID: Get from @userinfobot

2. **Resend** (for sending emails)
   - API Key: Get from resend.com
   - Verify domain: ativadata.com

3. **Stripe** (for payment webhooks)
   - Webhook Secret: From Stripe Dashboard → Webhooks

4. **HTTP Authorization** (for LiteLLM)
   - Type: Bearer Token
   - Token: Your LiteLLM master key

### Environment Variables

Set these in n8n UI (Settings → Variables):

- `LITELLM_MASTER_KEY` - LiteLLM admin key
- `TELEGRAM_CHAT_ID` - Your Telegram chat ID
- `RESEND_API_KEY` - Resend email API key

## Revenue Potential

n8n itself doesn't generate revenue directly, but enables:

### 1. Automation Services (R$500-2,500/project)

Offer custom automations:
- Lead enrichment pipeline (Google Sheets → LLM → CRM)
- Auto-generated product descriptions
- Price monitoring for competitors
- Support ticket classification

**Where to sell:**
- 99freelas.com.br
- Workana
- LinkedIn (DM agencies)

### 2. SaaS-like Products (R$97-297/month each)

Build once, sell many times:

**Price Monitor for E-commerce:**
- Scrape competitor prices every 6 hours
- Email digest with changes
- R$297/month per client

**Newsletter with AI Curation:**
- Aggregate RSS feeds
- LLM summarizes top stories
- Send via Resend
- R$97/month per subscriber

**Target:** 3-5 clients = R$500-1,500/month recurring

## Operations

### Creating a New Client Workflow

1. **Duplicate template workflow**
   - Right-click workflow → Duplicate
   - Rename: "Client - [Name]"

2. **Configure client-specific data**
   - Email addresses
   - Custom parameters
   - Schedule/triggers

3. **Test**
   - Use "Execute Workflow" button
   - Check logs for errors

4. **Activate**
   - Toggle "Active" in top-right

### Monitoring

```bash
# Check n8n status
docker ps | grep n8n

# View logs
docker logs n8n --tail 50

# Check database
docker exec -it n8n-db psql -U n8n -d n8n -c "SELECT name, active FROM workflow_entity;"
```

### Backup

Workflows are stored in PostgreSQL. To backup:

```bash
docker exec n8n-db pg_dump -U n8n n8n > n8n-backup-$(date +%Y%m%d).sql
```

## Troubleshooting

### Workflow not triggering

1. Check workflow is **Active** (toggle in UI)
2. Check logs: docker logs n8n --tail 100
3. Verify webhook URL is correct (for Stripe webhooks)
4. Test manually: "Execute Workflow" button

### Credential errors

1. Re-add credential in Settings → Credentials
2. Test connection before saving
3. Check environment variables in `.env`

### Database connection issues

```bash
# Check database health
docker exec n8n-db pg_isready -U n8n

# Restart if needed
docker compose restart
```

## Scaling

### When to Use n8n

✅ **Use for:**
- Automating client onboarding (Stripe → API key)
- Scheduled reports/summaries
- Webhook integrations (Stripe, Typeform, etc.)
- Multi-step workflows (A → B → C → notify)

❌ **Don't use for:**
- Simple HTTP requests (just use curl)
- One-time data migrations (use scripts)
- Real-time processing (too slow)
- Heavy computation (use dedicated services)

### Resource Usage

- n8n: ~100-200MB RAM
- PostgreSQL: ~50-100MB RAM
- Negligible CPU (only active during workflow execution)

Can easily handle 100+ workflows and 1000+ executions/day.

## Next Steps

1. ✅ Set up n8n (this guide)
2. ⏳ Import Stripe provisioning workflow
3. ⏳ Configure Telegram, Resend credentials
4. ⏳ Test client provisioning end-to-end
5. ⏳ Create ComfyUI notification workflow
6. ⏳ Consider building automation SaaS products

---

**Focus:** n8n is supporting infrastructure. Don't spend too much time here until ComfyUI revenue is consistent (R$2k+/month).
