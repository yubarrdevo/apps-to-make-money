# 💰 Guia Completo — Stack ComfyUI (Foco & Lucro)

> **Filosofia:** Um serviço, dominado. Tudo gira em torno do ComfyUI.
> **Servidor:** yuserver | Ryzen 9 9950X, 60GB RAM, RTX 3060 12GB
> **Receita esperada:** R$2.000-4.000/mês com 30 min/dia de trabalho

---

## 🎯 Por Que ComfyUI?

| Fator | ComfyUI | API LLM | Outros |
|-------|---------|---------|--------|
| **Receita/Cliente** | R$497/mês | R$97-297/mês | Variável |
| **Demanda** | Alta (e-commerce) | Média | Baixa |
| **Concorrência** | Baixa (barreira técnica) | Alta | Muito Alta |
| **Seu Tempo** | 30 min/dia | 5 min/dia | Variável |
| **Setup** | Simples | Simples | Complexo |

**Conclusão:** Focar 100% em ComfyUI até ter R$2-3k/mês consistente. Depois, opcionalmente, adicionar outros serviços.

---

## 📋 PARTE 1: Setup Inicial (20 minutos)

### 1.1 Instalar ComfyUI

```bash
cd ~/apps-to-make-money/infra/services/comfyui

# Baixar modelo FLUX (8GB, uma vez só)
mkdir -p models/checkpoints
cd models/checkpoints
wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell-fp8.safetensors
cd ../..

# Subir serviço
docker compose up -d

# Verificar
docker ps | grep comfyui
```

Acesse: http://localhost:8188

### 1.2 Testar Geração de Imagem

1. Abra http://localhost:8188
2. Arraste uma imagem de produto qualquer
3. Clique no workflow "Remove Background"
4. Clique "Queue Prompt"
5. Imagem processada aparece em `./output/`

**Tempo médio:** 15-30 segundos por imagem

### 1.3 Configurar Telegram (Alertas)

```bash
# 1. Telegram: @BotFather → /newbot → copie o token
# 2. Telegram: @userinfobot → /start → copie o chat_id

nano ~/income-services/shared/.gpu-scheduler.env
# Preencha:
# TELEGRAM_TOKEN=seu_token
# TELEGRAM_CHAT_ID=seu_chat_id

# Teste
~/apps-to-make-money/infra/monitoring/telegram-alert.sh "✅ ComfyUI rodando!"
```

---

## 📋 PARTE 2: Conseguir Clientes (1 hora/semana)

### 2.1 Onde Encontrar

**🎯 Alvo principal: Vendedores do Mercado Livre com fotos ruins**

1. Acesse Mercado Livre
2. Busque produtos (eletrônicos, sapatos, roupas, decoração)
3. Identifique anúncios com:
   - Foto tirada no celular
   - Fundo bagunçado
   - Produto mal enquadrado

4. Anote o nome do vendedor/loja

**Outros locais:**
- Grupos Facebook: "Vendedores Mercado Livre Brasil", "E-commerce Brasil"
- Instagram: busque `#revendedora`, `#lojaonline`
- LinkedIn: donos de pequenas lojas online

### 2.2 Script de Abordagem

**DM Mercado Livre / WhatsApp / Instagram:**

```
Oi [Nome]! Vi seu anúncio de [produto].

Ofereço fotos profissionais com fundo branco usando IA:
✅ R$15 por foto (ou R$120 pack de 10)
✅ Entrega em 24h
✅ Primeira foto GRÁTIS para você testar

Posso te mostrar um exemplo com uma foto sua?
```

**Resposta se pedirem exemplo:**

```
Envia uma foto do produto que quero processar aqui.
Te mando o resultado em 10 minutos, sem compromisso!
```

### 2.3 Primeiro Cliente (Processo Completo)

1. **Cliente envia foto** (WhatsApp, email, DM)

2. **Você processa** (5 minutos):
   ```bash
   # Abra ComfyUI: http://localhost:8188
   # Arraste foto do cliente
   # Aplique workflow "White Background Product"
   # Queue Prompt
   # Salve resultado de ./output/
   ```

3. **Entrega**:
   - Manda foto processada via WhatsApp/email
   - Ou sobe no Google Drive e envia link

4. **Fechamento**:
   ```
   Gostou? Tenho 2 opções:
   • R$15 por foto avulsa
   • R$497/mês para 20 fotos (mais barato, R$24 cada)

   Qual funciona melhor para você?
   ```

### 2.4 Meta Primeira Semana

- [ ] 10 DMs enviados (Mercado Livre)
- [ ] 3 primeiras fotos grátis processadas
- [ ] 1-2 clientes fechados (avulso ou mensal)

**Receita esperada:** R$150-500 na primeira semana

---

## 📋 PARTE 3: Workflow Operacional

### 3.1 Rotina Diária (15-30 min)

| Horário | Ação | Tempo |
|---------|------|-------|
| Manhã (10h) | Checar pedidos pendentes (WhatsApp/email) | 5 min |
| Tarde (15h) | Processar imagens (batch) | 15-20 min |
| Noite (19h) | Entregar trabalhos finalizados | 5 min |

**Total:** ~30 min/dia

### 3.2 Organização de Arquivos

```
~/comfyui-clients/
├── cliente-joao-eletronicos/
│   ├── input/          # Fotos que ele mandou
│   ├── output/         # Fotos processadas
│   └── delivered/      # Já entregues
├── cliente-maria-roupas/
└── ...
```

### 3.3 Processamento em Lote

Se tiver 10 fotos do mesmo cliente:

1. Abra ComfyUI
2. Configure workflow uma vez
3. Arraste todas as 10 imagens
4. Queue Prompt (processa todas automaticamente)
5. Resultados em `./output/`

**Tempo:** ~5 minutos de setup + 15 segundos/imagem

### 3.4 Precificação Inteligente

| Serviço | Preço | Quando usar |
|---------|-------|-------------|
| Foto avulsa | R$15 | Cliente testando, pedido único |
| Pack 10 fotos | R$120 (R$12 cada) | Cliente com catálogo pequeno |
| Mensal 20 fotos | R$497 (R$24 cada) | Cliente recorrente |
| Mensal 50 fotos | R$997 (R$20 cada) | Loja grande |

**Meta:** 3-5 clientes mensais = R$1.491-2.485/mês

---

## 📋 PARTE 4: Escalar (Meses 2-6)

### 4.1 Mês 1: Aprender & Validar

- [ ] Processar 50+ fotos (prática)
- [ ] 2-3 clientes ativos
- [ ] Refinar workflows para categorias comuns (sapatos, eletrônicos, roupas)

**Receita esperada:** R$800-1.500

### 4.2 Mês 2-3: Padronizar

- [ ] Templates salvos para cada categoria
- [ ] Tempo/foto reduzido para <2 min
- [ ] 5-8 clientes ativos
- [ ] Postar 2x/semana em grupos Facebook

**Receita esperada:** R$1.500-3.000

### 4.3 Mês 4-6: Automatizar

- [ ] n8n workflow: cliente faz upload → Telegram notifica
- [ ] n8n workflow: processamento completo → auto-entrega via email
- [ ] 10+ clientes mensais
- [ ] Considerar contratar VA para comunicação com cliente

**Receita esperada:** R$3.000-5.000

**Seu tempo:** 30 min/dia → 15 min/dia (só processamento)

---

## 📋 PARTE 5: Serviços Opcionais (Depois de R$2k/mês no ComfyUI)

### 5.1 n8n (Automações)

**Quando adicionar:** Mês 3+, quando tiver demanda de clientes

**O que vender:**
- Pipeline de leads (Google Sheets → IA → CRM): R$800-1.500
- Monitor de preços (Mercado Livre): R$297/mês
- Auto-responder com IA: R$500 setup + R$297/mês

**Setup:**
```bash
cd ~/apps-to-make-money/infra/services/n8n
cp .env.example .env
nano .env  # Configure senhas
docker compose up -d
```

Acesse: http://localhost:5678

### 5.2 LiteLLM API (LLM Privada)

**Quando adicionar:** Mês 6+, se tiver demanda

**O que é:** API compatível com OpenAI, hospedada no seu servidor

**Quem paga:**
- Empresas que não querem enviar dados para fora do Brasil (LGPD)
- Startups que querem cortar custos

**Setup:**
```bash
cd ~/apps-to-make-money/infra/services/litellm
cp .env.example .env
nano .env  # Configure DATABASE_URL
docker compose up -d
```

Acesse: http://localhost:4000

**Preços:**
- Básico: R$97/mês (100k tokens/dia)
- Pro: R$297/mês (500k tokens/dia)

---

## 📋 PARTE 6: Monitoramento

### 6.1 Health Check Automático

```bash
# Roda a cada 15 minutos via cron
tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log
```

Recebe alerta no Telegram se algo cair.

### 6.2 Checagem Manual (1x/dia)

```bash
# ComfyUI rodando?
docker ps | grep comfyui

# GPU OK?
nvidia-smi

# Disco OK?
df -h /
```

### 6.3 Backup (Automático)

Já configurado via cron:
- Diário: 4h da manhã
- Semanal: Domingo 5h

Backups em: `~/income-services/shared/backups/`

---

## 📋 PARTE 7: Projeção Financeira Real

### Mês 1-2 (Começando)

| Fonte | Valor |
|-------|-------|
| ComfyUI (2-3 clientes) | R$800-1.500 |
| Golem + bandwidth | R$200-400 |
| **Total** | **R$1.000-1.900** |

### Mês 3-6 (Crescimento)

| Fonte | Valor |
|-------|-------|
| ComfyUI (5-8 clientes) | R$2.000-4.000 |
| n8n (1-2 projetos) | R$500-1.500 |
| Golem + bandwidth | R$200-400 |
| **Total** | **R$2.700-5.900** |

### Mês 6+ (Estável)

| Fonte | Valor |
|-------|-------|
| ComfyUI (10+ clientes) | R$4.000-8.000 |
| n8n retainers | R$800-2.000 |
| LiteLLM API | R$300-900 |
| Golem + bandwidth | R$300-600 |
| **Total** | **R$5.400-11.500** |

**Tempo de trabalho:** 1-2 horas/dia → pode contratar VA para atendimento

---

## 🆘 Troubleshooting

### ComfyUI não inicia

```bash
# Checar GPU
nvidia-smi

# Checar logs
docker logs comfyui

# Reiniciar
cd ~/apps-to-make-money/infra/services/comfyui
docker compose restart
```

### Disco cheio

```bash
# Limpar Docker antigo
docker system prune -a

# Limpar outputs antigos
rm -rf ~/apps-to-make-money/infra/services/comfyui/output/old-*
```

### Cliente reclamando de qualidade

1. Peça feedback específico
2. Ajuste parâmetros do workflow
3. Refaça grátis uma vez (fidelização)
4. Se persistir, ofereça reembolso (raríssimo)

---

## ✅ Checklist de Ativação

- [x] ComfyUI instalado e rodando
- [x] Modelo FLUX baixado
- [x] Telegram configurado para alertas
- [ ] Primeira foto de teste processada
- [ ] 10 DMs enviados (Mercado Livre)
- [ ] Primeiro cliente fechado
- [ ] 3 clientes mensais ativos (R$1.500/mês)
- [ ] n8n instalado (quando precisar de automação)
- [ ] 10+ clientes mensais (R$5.000+/mês)

---

## 🎓 Próximos Passos

1. **Hoje:** Processar 5 fotos de teste (prática)
2. **Amanhã:** Enviar 10 DMs no Mercado Livre
3. **Essa semana:** Fechar primeiro cliente
4. **Esse mês:** 3 clientes ativos
5. **Próximos 3 meses:** Escalar para 10+ clientes

**Foco:** Domine ComfyUI. Ignore o resto até ter R$2-3k/mês recorrente.

---

*Última atualização: 2026-03-28*
*Repo: https://github.com/yubarrdevo/apps-to-make-money*
