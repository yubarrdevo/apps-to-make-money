# Landing Page — ativadata.com

Client-facing landing page for **ativadata.com** with service descriptions, pricing, and Stripe payment links.

## Services Showcased

1. **LLM API** — OpenAI-compatible API with automatic key provisioning
2. **ComfyUI Image Generation** — Professional product photography for e-commerce

## Deployment

```bash
cd infra/services/landing-page
docker compose up -d
```

Or via the deploy script:

```bash
./infra/deploy.sh landing-page
```

Accessible at:
- Local: http://localhost:8080
- Public: https://ativadata.com (via Cloudflare Tunnel)

## Cloudflare Tunnel

Add to `~/.cloudflared/config.yml`:

```yaml
- hostname: ativadata.com
  service: http://localhost:8080
```

Then restart the tunnel:

```bash
systemctl --user restart cloudflared
```

## Customization

Edit `index.html` to update:
- Pricing tiers and Stripe payment links
- WhatsApp contact number (replace `5500000000000` with actual number)
- Service descriptions and FAQ items
- Brand colors and styling

## Port Note

The landing page uses port **8080**. If MoneyPrinter backend is also using 8080, change the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "8090:80"  # Use 8090 instead
```

And update the Cloudflare Tunnel config accordingly.
