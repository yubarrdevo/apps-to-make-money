# 💰 Guia Completo — Stack de Renda Automatizada
> Servidor: yuserver | Hardware: Ryzen 9 9950X, 60GB RAM, RTX 3060 12GB, 2Gbps
> Tudo já está rodando. Este guia mostra o que fazer para o dinheiro entrar.

---

## 🌐 Domínios

| Domínio | Uso |
|---|---|
| `ativadata.com` | **Vitrine para clientes** — API pública, landing page |
| `ativadata.com.br` | Clientes BR (LGPD, confiança local) |
| `atividata.com.br` | **Infra interna** — nunca mostrar para cliente |

---

## 🚦 URLs de Acesso

### Para Clientes (mostrar/vender)
| Serviço | URL |
|---|---|
| **LLM API** (OpenAI-compatible) | https://llm.ativadata.com |
| **LLM API** (alt BR) | https://api.ativadata.com |

### Infra Interna (só você acessa)
| Serviço | URL | Login |
|---|---|---|
| **n8n** (automações) | https://n8n.atividata.com.br | admin / ver .env |
| **ComfyUI** (imagens IA) | https://studio.atividada.com.br | sem login |
| **MoneyPrinter** | https://moneyprinter.atividata.com.br | sem login |
| **Coolify** (PaaS) | https://coolify.atividata.com.br | sem login |
| **Portainer** (Docker) | https://portainer.atividata.com.br | sem login |
| **Emby** (media) | https://emby.atividata.com.br | sem login |

---

## 📋 PARTE 1: Credenciais que Precisa (1x, depois é automático)

### 1.1 Telegram Bot (5 minutos)
> Libera: todos os alertas do servidor, notificações de pagamento, ativação dos workflows n8n

**Passo a passo:**
1. Abra o Telegram no celular
2. Pesquise `@BotFather` → clique → `/newbot`
3. Escolha um nome: ex. `Yuri Server Bot`
4. Escolha um username: ex. `yuriserver_bot`
5. Copie o **token** que aparece (formato: `1234567890:ABCdef...`) → esse é o `TELEGRAM_TOKEN`
6. Pesquise `@userinfobot` → `/start` → anote o número que aparece em "Id:" → esse é o `TELEGRAM_CHAT_ID`
7. **Abra o bot e clique em /start** (obrigatório antes de testar)

**Cole no servidor:**
```bash
nano ~/income-services/shared/.gpu-scheduler.env
# Preencha:
# TELEGRAM_TOKEN=seu_token_aqui
# TELEGRAM_CHAT_ID=seu_id_aqui
```

**Pegar o chat_id correto após clicar /start:**
```bash
source ~/income-services/shared/.gpu-scheduler.env
curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates" | python3 -c "
import sys,json
data=json.load(sys.stdin)
for u in data.get('result',[]):
    chat=u.get('message',{}).get('chat',{})
    print('Chat ID:', chat.get('id'), '| Nome:', chat.get('first_name',''))
"
```

**Teste:**
```bash
~/income-services/shared/telegram-alert.sh "✅ Servidor funcionando!"
```

---

### 1.2 Resend (email automático para clientes) — 10 minutos
> Libera: envio automático de credenciais quando cliente paga via Stripe

1. Acesse [resend.com](https://resend.com) → Sign up (grátis)
2. Clique em **Domains** → Add Domain → digite `ativadata.com`
3. Adicione os registros DNS no Cloudflare (TXT + MX que o Resend mostrar)
4. Volte no Resend → Verify → deve ficar verde
5. Vá em **API Keys** → Create API Key → copie

**Cole no n8n:**
```
n8n (https://n8n.atividata.com.br) → Settings → Variables → RESEND_API_KEY
```

---

### 1.3 Stripe (receber pagamentos) — 15 minutos
> Libera: provisionamento automático de clientes, assinaturas recorrentes

1. Acesse [stripe.com](https://stripe.com) → criar conta
2. Complete verificação de identidade (CPF, endereço)
3. Crie os produtos:
   - **Básico**: R$97/mês → "API LLM Privada — 100k tokens/dia"
   - **Pro**: R$297/mês → "API LLM Multi-modelo — 500k tokens/dia"
   - **Custom**: R$597/mês → "Pipeline RAG dedicado"
4. **Developers** → Webhooks → Add endpoint:
   - URL: `https://n8n.atividata.com.br/webhook/stripe-payment`
   - Events: `checkout.session.completed`, `invoice.payment_succeeded`
5. Copie o **Webhook Secret** (`whsec_...`)

**No n8n:** Credentials → New → Stripe Trigger → cole o Webhook Secret

---

### 1.4 Contas de Bandwidth Sharing — 20 minutos
> Renda passiva: $20-40/mês sem fazer nada

| Plataforma | Link | Pagamento |
|---|---|---|
| Honeygain | [honeygain.com](https://honeygain.com) | PayPal / crypto |
| EarnApp | [earnapp.com](https://earnapp.com) | PayPal |
| Pawns.app | [pawns.app](https://pawns.app) | PayPal / crypto |
| PacketStream | [packetstream.io](https://packetstream.io) | PayPal |
| Peer2Profit | [peer2profit.com](https://peer2profit.com) | crypto |
| Repocket | [repocket.co](https://repocket.co) | PayPal |
| Grass | [getgrass.io](https://getgrass.io) | Solana (baixe Phantom) |

**Após criar todas as contas:**
```bash
nano ~/income-services/bandwidth/money4band/.env
# Preencha cada email/senha/token
cd ~/income-services/bandwidth/money4band
source venvm4b/bin/activate
python3 main.py       # setup interativo único
docker compose up -d  # sobe e fica rodando sozinho
```

---

## 📋 PARTE 2: Como Conseguir Clientes

### 2.1 API LLM Privada — R$97-597/mês por cliente

**Post LinkedIn (copie e cole):**
```
🔐 Sua empresa usa ChatGPT? Seus dados passam pelos EUA.

Ofereço API de IA privada hospedada em São Paulo:
✅ Seus dados ficam no Brasil
✅ Compatível com OpenAI (só muda a base_url, sem alterar código)
✅ Modelos: equivalente ao GPT-3.5 e GPT-4
✅ R$97/mês — 100k tokens/dia

Endpoint: https://llm.ativadata.com
7 dias grátis. Me chama no DM.

#IA #LLM #LGPD #Tech #Automação
```

**Quem abordar:**
- Escritórios de advocacia (LGPD os assusta)
- Agências de marketing (copy em escala)
- E-commerces Mercado Livre (descrições de produto)
- Startups usando OpenAI que querem cortar custo

**DM LinkedIn:**
```
Oi [Nome], vi que vocês usam IA no processo de [X].
Tenho uma API LLM privada hospedada no Brasil — dados nunca saem do país.
Compatível com OpenAI, R$97/mês. Posso te dar 7 dias grátis pra testar?
```

**Como o cliente conecta:**
```python
from openai import OpenAI
client = OpenAI(
    base_url="https://llm.ativadata.com/v1",
    api_key="sk-chave-gerada-automaticamente"
)
```

---

### 2.2 Automações n8n — R$500-2.500 projeto + R$297-797/mês retainer

**Poste no 99freelas.com.br e Workana:**
```
Título: Automações n8n — Integração de sistemas, relatórios automáticos, IA

Crio workflows de automação que economizam horas de trabalho manual.

Exemplos:
• Pipeline de enriquecimento de leads (Google Sheets → IA → CRM)
• Gerador de descrições de produto com IA em PT-BR
• Monitor de preços Mercado Livre com alertas
• Auto-responder de suporte com classificação por IA

Valores:
• Template pronto: R$150-500
• Workflow personalizado: R$500-2.500
• Manutenção mensal: R$297-797
```

---

### 2.3 Conteúdo IA — Fotos e vídeos de produto

**Após ComfyUI subir** (https://studio.atividata.com.br):

- Foto com fundo branco profissional: R$15/imagem
- Pack 10 imagens: R$120
- Vídeo produto 15-30s: R$97
- Pacote mensal (20 fotos + 4 vídeos): R$497/mês

**Onde anunciar:**
- Grupos Facebook: "Vendedores Mercado Livre Brasil"
- Contato direto: busque produtos no ML com fotos ruins → DM o vendedor

---

### 2.4 Arbitragem de Automação — Renda Recorrente Passiva

**Produto 1: Monitor de Preços** — R$297/mês por loja
```
n8n (6h/6h) → scrapa ML → compara catálogo → email digest
```

**Produto 2: Newsletter com curadoria IA** — R$97/mês
```
n8n (diário) → RSS feeds → LLM resume → Resend envia
```

**Nichos BR que pagam bem:** Agro, Jurídico, E-commerce, Finanças

---

## 📋 PARTE 3: Loop de Venda Automático

```
Cliente acessa llm.ativadata.com →
  Stripe (R$97-597/mês) →
    n8n webhook →
      LiteLLM gera API key →
        Resend envia credenciais →
          Cliente usa API →
            GPU gera receita →
              Telegram te avisa
```
**Zero intervenção manual por cliente.**

---

## 📋 PARTE 4: Rotina Semanal

| Dia | Ação | Tempo |
|---|---|---|
| Segunda | Post LinkedIn (copie templates acima) | 10 min |
| Terça | Responder DMs e leads | 20 min |
| Quarta | Atualizar gig no 99freelas/Workana | 10 min |
| Quinta | DM 5 vendedores ML com fotos ruins | 15 min |
| Sexta | Ver resumo semanal (Telegram envia) | 5 min |

**Total: ~1h/semana. O servidor faz o resto.**

---

## 📋 PARTE 5: Monitoramento (automático)

```bash
# Ver status agora
docker ps
nvidia-smi
~/income-services/shared/health-check.sh

# Ver logs de qualquer serviço
docker logs n8n --tail 50
docker logs litellm-proxy --tail 50
```

Alertas automáticos via Telegram a cada 15 minutos.

---

## 📋 PARTE 6: Projeção Financeira

### Mês 1-2
| Fonte | Valor |
|---|---|
| Golem compute | R$100-400 |
| Bandwidth sharing | R$100-200 |
| 1 cliente API LLM | R$97-297 |
| 1 projeto n8n | R$500-1.000 |
| **Total** | **R$800-1.900** |

### Mês 6+
| Fonte | Valor |
|---|---|
| Golem + bandwidth | R$200-600 |
| 3 clientes API recorrentes | R$291-1.791 |
| 2 retainers n8n | R$594-1.594 |
| Conteúdo IA | R$500-1.500 |
| Arbitragem (newsletters/monitores) | R$194-994 |
| **Total** | **R$1.779-6.479** |

---

## 🆘 Troubleshooting

```bash
# Serviço caiu
docker ps
cd ~/income-services/[serviço] && docker compose up -d

# GPU travada
~/income-services/shared/gpu-lock.sh status
~/income-services/shared/gpu-lock.sh [serviço] stop

# Golem parou
sg kvm -c "golemsp run" &

# n8n workflow não ativa
# → Configure credencial Telegram em: n8n → Credentials → Telegram
```

---

## ✅ Checklist de Ativação

- [ ] **1. Telegram** — @BotFather → /start no bot → pegar chat_id correto → `.gpu-scheduler.env`
- [ ] **2. Resend** — resend.com → verificar `ativadata.com` → API key → n8n variable
- [ ] **3. Stripe** — criar produtos → webhook → credencial no n8n
- [ ] **4. money4band** — criar 7 contas → preencher .env → python3 main.py → docker compose up -d
- [ ] **5. Landing page** — `ativadata.com` com planos e links Stripe
- [ ] **6. Primeiro post LinkedIn** — copiar template da seção 2.1
- [ ] **7. Primeiro gig no 99freelas** — copiar template da seção 2.2
- [ ] **8. ComfyUI** — `cd ~/income-services/ai-content && docker compose up -d`

---

*Repo: https://github.com/yubarrdevo/apps-to-make-money*

> Servidor: yuserver | Domínios: ativadata.com / ativadata.com.br / atividata.com.br
> Tudo já está rodando. Este guia mostra o que fazer para o dinheiro entrar.

---

## 🚦 Status Atual dos Serviços

| Serviço | URL | Status |
|---|---|---|
| LiteLLM API (LLM privada) | https://api.ativadata.com | ✅ Online |
| n8n (automações) | https://n8n.atividata.com.br | ✅ Online |
| MoneyPrinter (vídeos) | http://localhost:8001 | ✅ Online |
| Ollama (modelos locais) | interno | ✅ Online |
| Golem (compute descentralizado) | mainnet | ✅ Publicando ofertas |
| ComfyUI (imagens IA) | http://localhost:8188 | ⏳ Aguardando start |
| Bandwidth sharing | — | ❌ Precisa de credenciais |

---

## 📋 PARTE 1: Credenciais que Precisa (1x, depois é automático)

### 1.1 Telegram Bot (5 minutos)
> Libera: todos os alertas do servidor, notificações de pagamento, ativação dos workflows n8n

**Passo a passo:**
1. Abra o Telegram no celular
2. Pesquise `@BotFather` → clique → `/newbot`
3. Escolha um nome: ex. `Yuri Server Bot`
4. Escolha um username: ex. `yuriserver_bot`
5. Copie o **token** que aparece (formato: `1234567890:ABCdef...`) → esse é o `TELEGRAM_TOKEN`
6. Pesquise `@userinfobot` → `/start` → anote o número que aparece em "Id:" → esse é o `TELEGRAM_CHAT_ID`

**Depois, cole no servidor:**
```bash
nano ~/income-services/shared/.gpu-scheduler.env
# Preencha:
# TELEGRAM_TOKEN=seu_token_aqui
# TELEGRAM_CHAT_ID=seu_id_aqui
```

**Teste:**
```bash
~/income-services/shared/telegram-alert.sh "✅ Servidor funcionando!"
```

---

### 1.2 Resend (email automático para clientes) — 10 minutos
> Libera: envio automático de credenciais quando cliente paga via Stripe

1. Acesse [resend.com](https://resend.com) → Sign up (grátis)
2. Clique em **Domains** → Add Domain → digite `ativadata.com`
3. Eles mostram registros DNS para adicionar — acesse o Cloudflare:
   - Faça login em [dash.cloudflare.com](https://dash.cloudflare.com)
   - Domínio `ativadata.com` → DNS → adicione os registros que o Resend mostrou (TXT + MX)
   - Volte no Resend → Verify → deve ficar verde
4. Vá em **API Keys** → Create API Key → copie

**Cole no servidor:**
```bash
# No n8n: Settings → Variables → adicione:
# RESEND_API_KEY = re_xxxxxxxxxxxx
```

---

### 1.3 Stripe (receber pagamentos) — 15 minutos
> Libera: provisionamento automático de clientes API, assinaturas recorrentes

1. Acesse [stripe.com](https://stripe.com) → criar conta
2. Complete verificação de identidade (CPF, endereço)
3. Crie os produtos:
   - **Básico**: R$97/mês → "API LLM Privada — 100k tokens/dia"
   - **Pro**: R$297/mês → "API LLM Multi-modelo — 500k tokens/dia"
   - **Custom**: R$597/mês → "Pipeline RAG dedicado"
4. Vá em **Developers** → Webhooks → Add endpoint:
   - URL: `https://n8n.atividata.com.br/webhook/stripe-payment`
   - Events: `checkout.session.completed`, `invoice.payment_succeeded`
5. Copie o **Webhook Secret** (formato: `whsec_...`)

**Cole no n8n:**
```
n8n UI → Credentials → New → Stripe Trigger
→ cole o Webhook Secret
```

---

### 1.4 Contas de Bandwidth Sharing — 20 minutos
> Renda passiva: $20-40/mês sem fazer nada, só deixar rodando

Crie conta em cada um (email + senha, gratuito):

| Plataforma | Link | Pagamento |
|---|---|---|
| Honeygain | [honeygain.com](https://honeygain.com) | PayPal / crypto |
| EarnApp | [earnapp.com](https://earnapp.com) | PayPal |
| Pawns.app | [pawns.app](https://pawns.app) | PayPal / crypto |
| PacketStream | [packetstream.io](https://packetstream.io) | PayPal |
| Peer2Profit | [peer2profit.com](https://peer2profit.com) | crypto |
| Repocket | [repocket.co](https://repocket.co) | PayPal |
| Grass | [getgrass.io](https://getgrass.io) | Solana (baixe Phantom no celular) |

**Depois de criar todas as contas:**
```bash
nano ~/income-services/bandwidth/money4band/.env
# Preencha cada email/senha/token
# Depois:
cd ~/income-services/bandwidth/money4band
source venvm4b/bin/activate
python3 main.py  # setup interativo único
docker compose up -d  # sobe e fica rodando sozinho
```

---

## 📋 PARTE 2: Como Conseguir Clientes (sem depender de ninguém)

### 2.1 API LLM Privada — Alvo: empresas BR que não querem mandar dados pro exterior

**Post LinkedIn (copie e cole, adapte o nome):**
```
🔐 Sua empresa usa ChatGPT? Seus dados passam pelos EUA.

Ofereço API de IA privada hospedada em São Paulo:
✅ Seus dados ficam no Brasil
✅ Compatível com OpenAI (troca de base_url, sem mudar código)
✅ Modelos: equivalente ao GPT-3.5 e GPT-4
✅ R$97/mês — 100k tokens/dia

7 dias grátis. Me chama no DM.

#IA #LLM #LGPD #Tech #Automação
```

**Quem abordar:**
- Escritórios de advocacia (LGPD os assusta)
- Agências de marketing (precisam de geração de copy em escala)
- E-commerces no Mercado Livre (descrições de produto)
- Startups que usam OpenAI e querem cortar custo

**Como abordar (DM LinkedIn):**
```
Oi [Nome], vi que vocês usam IA no processo de [X].
Tenho uma API LLM privada hospedada no Brasil — dados nunca saem do país.
Compatível com OpenAI, R$97/mês. Posso te dar 7 dias grátis pra testar?
```

---

### 2.2 Automações n8n — Alvo: agências, e-commerce, qualquer empresa com processo repetitivo

**Poste no 99freelas.com.br e Workana:**
```
Título: Automações n8n — Integração de sistemas, relatórios automáticos, IA

Descrição:
Crio workflows de automação usando n8n que economizam horas de trabalho manual.

Exemplos do que já construí:
• Pipeline de enriquecimento de leads (Google Sheets → IA → CRM)
• Gerador automático de descrições de produto com IA
• Monitor de preços de concorrentes (Mercado Livre) com alertas
• Auto-responder de suporte com classificação por IA

Valores:
• Template pronto: R$150-500
• Workflow personalizado: R$500-2.500
• Manutenção mensal: R$297-797

Respondo em 1 hora.
```

**DM direto para agências de marketing no LinkedIn:**
```
Oi [Nome], vocês fazem relatórios de performance manualmente?
Consigo automatizar isso completamente — dados chegam, relatório sai.
Posso mostrar como funciona numa call de 15 min?
```

---

### 2.3 Conteúdo IA (imagens + vídeos) — Alvo: vendedores Mercado Livre, Shopee

**Após ComfyUI subir, o workflow é:**
1. Cliente manda foto do produto
2. ComfyUI gera versão com fundo branco profissional + variações
3. MoneyPrinter gera vídeo para redes sociais
4. Entrega via Google Drive ou email automático

**Precificar:**
- Foto com fundo removido + background profissional: R$15/imagem
- Pack de 10 imagens: R$120
- Vídeo produto (15-30s): R$97
- Pacote mensal (20 fotos + 4 vídeos): R$497/mês

**Onde anunciar:**
- Grupos Facebook: "Vendedores Mercado Livre Brasil", "E-commerce Brasil"
- Grupos WhatsApp de vendedores
- Contato direto: busque produtos no ML com fotos ruins → DM o vendedor

---

### 2.4 Arbitragem de Automação — Renda Recorrente Passiva

**Produto 1: Monitor de Preços para E-commerce**
```
n8n roda a cada 6h → scrapa preços dos concorrentes no Mercado Livre →
  compara com catálogo do cliente → envia digest por email
```
Cobrar: R$297/mês por loja

**Para montar:**
1. n8n já está rodando em https://n8n.atividata.com.br
2. Crie workflow: HTTP Request (ML API) → Code (comparação) → Gmail/Resend (email)
3. Primeiro cliente fecha → duplica o workflow com os dados dele

**Produto 2: Newsletter de nicho com curadoria IA**
```
n8n diário → agrega RSS feeds do nicho →
  LLM resume e ranqueia → formata → envia via Resend
```
Cobrar: R$97/mês por newsletter

**Nichos que funcionam no Brasil:**
- Agro (fazendeiros pagam bem)
- Jurídico (advogados assinam tudo)
- Finanças pessoais
- E-commerce / dropshipping

---

## 📋 PARTE 3: Infraestrutura de Vendas (configure 1x)

### 3.1 Landing Page (já tem domínio, falta conteúdo)

Acesse o Coolify em http://localhost:8000 e crie um novo serviço estático, ou use Netlify:

```
ativadata.com  →  página de serviços
Seções:
1. Hero: "IA Privada no Brasil"
2. API LLM: planos R$97 / R$297 / R$597 (botão Stripe)
3. Automações n8n: portfólio + preços
4. Conteúdo IA: antes/depois de fotos de produto
5. Contato: formulário → n8n webhook → você recebe no Telegram
```

### 3.2 Link de Pagamento Stripe

Após criar os produtos no Stripe:
- Cada produto gera um **Payment Link** (stripe.com/pay/xxx)
- Cole esses links na landing page
- Quando alguém paga → webhook → n8n provisiona automaticamente → Resend envia credenciais

**Zero intervenção manual.**

---

## 📋 PARTE 4: Rotina Semanal (única coisa que você faz)

O servidor cuida de si mesmo. Sua única tarefa é **trazer clientes.**

| Dia | Ação | Tempo |
|---|---|---|
| Segunda | Postar no LinkedIn (copie templates acima) | 10 min |
| Terça | Responder DMs e leads do LinkedIn | 20 min |
| Quarta | Postar no 99freelas/Workana (atualizar gig) | 10 min |
| Quinta | Abordar 5 vendedores ML com fotos ruins | 15 min |
| Sexta | Ver relatório semanal (Telegram vai mandar) | 5 min |
| Fim de semana | Nada — servidor trabalha por você | — |

**Total: ~1 hora por semana de trabalho ativo.**

---

## 📋 PARTE 5: Monitoramento (automático)

O servidor já monitora tudo e te avisa no Telegram:

```
✅ Serviços: checados a cada 15 minutos
✅ GPU: temperatura e uso monitorados
✅ Falhas: auto-restart + alerta Telegram
✅ Git: commit automático a cada hora
✅ Golem: roda na inicialização automaticamente
```

**Para ver status agora:**
```bash
~/income-services/shared/health-check.sh
# ou
docker ps
nvidia-smi
```

---

## 📋 PARTE 6: Projeção Financeira

### Mês 1-2 (com esforço mínimo)
| Fonte | Valor |
|---|---|
| Golem compute | R$100-400 |
| Bandwidth sharing | R$100-200 |
| 1 cliente API LLM | R$97-297 |
| 1 projeto n8n | R$500-1.000 |
| **Total** | **R$800-1.900** |

### Mês 3-6 (com base de clientes)
| Fonte | Valor |
|---|---|
| Golem + bandwidth | R$200-600 |
| 3 clientes API recorrentes | R$291-891 |
| 2 retainers n8n | R$594-1.594 |
| Conteúdo IA (fotos/vídeos) | R$500-1.500 |
| 2 arbitragens (newsletters/monitores) | R$194-594 |
| **Total** | **R$1.779-5.179** |

### Mês 6+ (no piloto automático)
**R$3.000-8.000/mês com ~1h/semana de trabalho ativo**

---

## 🆘 Problemas Comuns

**Serviço caiu:**
```bash
docker ps  # ver o que está rodando
docker compose up -d  # na pasta do serviço
```

**GPU travada:**
```bash
~/income-services/shared/gpu-lock.sh status
~/income-services/shared/gpu-lock.sh [serviço] stop
```

**n8n workflow não ativa:**
- Verifique se a credencial Telegram está configurada no n8n
- n8n → Credentials → New → Telegram → cole o token

**Golem parou:**
```bash
sg kvm -c "golemsp run" &
```

**Ver logs de qualquer serviço:**
```bash
docker logs [nome-container] --tail 50
# Exemplos: n8n, litellm-proxy, cloudflared
```

---

## ✅ Checklist de Ativação (faça em ordem)

- [ ] **1. Telegram** — @BotFather → token + chat_id → nano ~/.gpu-scheduler.env
- [ ] **2. Resend** — resend.com → verificar domínio ativadata.com → API key → n8n variable
- [ ] **3. Stripe** — criar produtos → webhook → credencial no n8n
- [ ] **4. money4band** — criar 7 contas → preencher .env → python3 main.py → docker compose up -d
- [ ] **5. Landing page** — ativadata.com com links Stripe
- [ ] **6. Primeiro post LinkedIn** — copiar template da seção 2.1
- [ ] **7. Primeiro gig no 99freelas** — copiar template da seção 2.2
- [ ] **8. ComfyUI** — `cd ~/income-services/ai-content && docker compose up -d`

**Depois disso: o sistema funciona sozinho. Você só traz clientes.**

---

*Última atualização: gerado automaticamente pelo Copilot CLI*
*Repo: https://github.com/yubarrdevo/apps-to-make-money*
