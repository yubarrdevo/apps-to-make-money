# ComfyUI - AI Image Generation Service

ComfyUI is the **primary revenue-generating service** for AI-powered image generation.

## What It Does

- Professional product photography with white backgrounds
- E-commerce lifestyle images
- Image variations for A/B testing
- Batch image processing for multiple products

## Revenue Streams

| Service | Price | Volume Target |
|---------|-------|---------------|
| Single product photo (white bg) | R$15 | 20-50/month |
| 10-image pack | R$120 | 5-10/month |
| Monthly package (20 photos) | R$497 | 3-5 clients |
| **Expected Monthly Revenue** | | **R$2,000-4,000** |

## Setup

### 1. Download Models

Models are large (5-20GB each). Download only what you need:

```bash
cd infra/services/comfyui/models/checkpoints

# FLUX (fastest, best quality) - 8GB
wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell-fp8.safetensors

# OR Stable Diffusion XL (alternative) - 6.5GB
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
```

### 2. Start Service

```bash
cd infra/services/comfyui
docker compose up -d
```

### 3. Access

- Local: http://localhost:8188
- Public (via Cloudflare Tunnel): https://studio.atividata.com.br

## Client Workflow

1. **Client sends product photo** (email, WhatsApp, or upload form)
2. **You load image in ComfyUI** → apply workflow → generate
3. **Export processed images** from `./output/`
4. **Deliver via Google Drive or email**

## Pre-built Workflows

Save these in ComfyUI for quick client work:

- `white-background-product.json` - Remove background, add white
- `lifestyle-scene.json` - Place product in attractive setting
- `variation-generator.json` - Create 4-8 variations
- `batch-processor.json` - Process multiple products at once

## Finding Clients

### Where to Find Them

1. **Mercado Livre sellers with bad photos**
   - Search products in your niche
   - Find listings with phone photos or messy backgrounds
   - DM: "Oi! Suas fotos de produto ficam com fundo profissional por R$15 cada. Interesse?"

2. **E-commerce Facebook Groups**
   - "Vendedores Mercado Livre Brasil"
   - "E-commerce Brasil"
   - Post sample before/after images

3. **Local businesses**
   - Small online stores
   - Instagram shops
   - Offer first 3 images free

### Sales Script (Portuguese)

```
Olá! Vejo que você vende [produto] online.

Ofereço fotos profissionais com fundo branco/lifestyle usando IA:
✅ R$15 por foto (ou R$120 pack de 10)
✅ Entrega em 24h
✅ Primeiras 3 grátis para testar

Posso te mostrar um exemplo com uma foto sua?
```

## Operations

### Daily Routine (15-30 min)

- Check for new client requests (email/WhatsApp)
- Process queued images (batch processing)
- Deliver completed work
- Follow up with prospects

### Monthly Package Management

For R$497/month clients (20 photos):

1. **Set up folder**: `~/comfyui-clients/[client-name]/`
2. **n8n workflow**: Auto-notification when client uploads
3. **Process weekly**: 5 images/week = 20/month
4. **Auto-delivery**: n8n → process → Google Drive → email

## Technical Notes

### GPU Usage

- RTX 3060 12GB can handle FLUX at 0.9 GPU memory utilization
- Average generation time: 15-30 seconds per image
- Can process 100+ images/day if needed

### Storage

- Models: ~10-20GB (one-time download)
- Input images: ~50MB per client batch
- Output images: ~200MB per client batch
- Use external drive if needed

### Monitoring

```bash
# Check if running
docker ps | grep comfyui

# View logs
docker logs comfyui --tail 50

# GPU usage
nvidia-smi

# Restart if needed
docker compose restart
```

## Scaling Revenue

### Month 1-2: R$500-1,500
- 3-5 one-time clients
- Focus on quality, get testimonials

### Month 3-6: R$2,000-3,000
- 2-3 monthly package clients
- Word of mouth referrals
- Consistent presence in FB groups

### Month 6+: R$3,000-5,000
- 5+ monthly packages
- Consider hiring VA for client communication
- You only do processing (30 min/day)

## Troubleshooting

**GPU out of memory:**
```bash
# Reduce GPU memory in docker-compose.yml
# Or use smaller model (SDXL instead of FLUX)
```

**Slow generation:**
```bash
# Check GPU usage: nvidia-smi
# Restart ComfyUI: docker compose restart
```

**Models not loading:**
```bash
# Check models exist:
ls -lh models/checkpoints/
# Re-download if needed
```

## Next Steps

1. ✅ Set up ComfyUI (this guide)
2. ⏳ Download at least one model (FLUX recommended)
3. ⏳ Test with sample product image
4. ⏳ Post in first Facebook group with before/after
5. ⏳ Get first 3 clients
6. ⏳ Refine workflow based on feedback
7. ⏳ Create monthly package offering

---

**Focus**: ComfyUI is your main income source. Master it, perfect the workflow, and scale client acquisition. Everything else is secondary.
