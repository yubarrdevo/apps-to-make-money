# Stripe Payment Links

## LLM API Subscriptions

| Plano | Preço | Link |
|---|---|---|
| Básico | R$97/mês | https://buy.stripe.com/fZu14g5OlaZ9cxGfMz8bS00 |
| Pro | R$297/mês | https://buy.stripe.com/4gMcMY0u10kv1T243R8bS01 |
| Custom | R$597/mês | https://buy.stripe.com/28E4gsccJ1oz0OY2ZN8bS02 |

### IDs
- Price Básico: price_1TFfwZ4igpRBqrATcXJj7myA
- Price Pro: price_1TFfwj4igpRBqrAThXwUMUO7
- Price Custom: price_1TFfwk4igpRBqrAT0mgh5Rel
- Webhook: we_1TFfx24igpRBqrATr8Hi5QOS

### Metadata (add to each payment link)
- `plan` = `basic` / `pro` / `custom`

## ComfyUI Image Packages

Create these payment links in Stripe Dashboard → Payment Links:

| Pacote | Preço | Metadata |
|---|---|---|
| Foto Avulsa | R$15 | `package=single` |
| Pacote 10 Fotos | R$120 | `package=pack10` |
| Mensal 20 Fotos | R$497/mês | `package=monthly20` |
| Mensal 50 Fotos | R$997/mês | `package=monthly50` |

### Setup Instructions
1. Go to Stripe Dashboard → Products → Create Product for each package
2. Create Payment Links with the metadata above
3. Update the landing page (`infra/services/landing-page/index.html`) with the generated links
4. Add webhook endpoint: `https://n8n.atividata.com.br/webhook/comfyui-order`

## Webhook Configuration

| Endpoint | Events | Workflow |
|---|---|---|
| `https://n8n.atividata.com.br/webhook/stripe-webhook` | `checkout.session.completed` | LLM API provisioning |
| `https://n8n.atividata.com.br/webhook/comfyui-order` | `checkout.session.completed` | ComfyUI order processing |

See `infra/PAYMENT-SETUP.md` for complete setup instructions.
