# O Que Está Rodando Nesse Servidor? — Para Leigos

> Explicação simples de cada serviço, sem termos técnicos.

---

## O Servidor

Imagina um computador muito potente, ligado 24 horas por dia, na casa do Yuri em São Paulo.
Ele tem uma placa de vídeo profissional (a mesma usada para jogos pesados e IA), 60GB de memória e conexão de 2Gbps — mais rápido que qualquer escritório normal.

Em vez de ficar parado, esse computador está **trabalhando e gerando dinheiro o tempo todo**, em vários serviços ao mesmo tempo.

---

## Os Serviços, Explicados Simples

---

### 🤖 API de Inteligência Artificial Privada
**Link:** https://llm.ativadata.com

**O que é:**
É como o ChatGPT, mas hospedado aqui no Brasil, no servidor do Yuri.

**Por que alguém pagaria por isso:**
- Empresas que usam o ChatGPT mandam os dados dos seus clientes para os EUA toda vez que fazem uma pergunta.
- Com essa API, os dados ficam em São Paulo. Isso é obrigatório para muitas empresas por causa da LGPD (lei de proteção de dados brasileira).
- Desenvolvedores podem trocar o ChatGPT por essa API **sem mudar nada no código** — só mudam um endereço.

**Quem usa:** Empresas de tecnologia, escritórios de advocacia, agências de marketing, e-commerces.

**Quanto custa para o cliente:** R$97 a R$597 por mês.

---

### ⚙️ n8n — Automação de Processos
**Link:** https://n8n.atividada.com.br (uso interno)

**O que é:**
É uma ferramenta que conecta sistemas e automatiza tarefas repetitivas. Pensa nela como um "robô de escritório" que faz coisas sozinho.

**Exemplos do que ela faz aqui:**
- Quando um cliente paga, ela automaticamente cria o acesso dele e manda as credenciais por email — sem ninguém precisar fazer nada
- Todo dia às 10h, ela manda pedidos para gerar vídeos automaticamente
- Ela pode pegar uma planilha de produtos e escrever descrições para todos eles usando IA

**Quem usa:** Empresas que querem automatizar relatórios, envios de email, atualização de sistemas, etc.

**Quanto custa para o cliente:** R$500 a R$2.500 para construir + R$297/mês para manutenção.

---

### 🎬 MoneyPrinter — Gerador de Vídeos Automático
**Link:** https://moneyprinter.atividata.com.br (uso interno)

**O que é:**
Um sistema que cria vídeos curtos (tipo YouTube Shorts ou Reels) de forma totalmente automática, usando IA.

**Como funciona:**
1. A IA escolhe um assunto em alta
2. Escreve o roteiro
3. Gera as imagens
4. Monta o vídeo com narração
5. Entrega pronto para publicar

**Por que existe:** Para gerar conteúdo no YouTube que, com o tempo, gera receita de publicidade (AdSense) sem trabalho manual.

---

### 🎨 ComfyUI — Gerador de Imagens com IA
**Link:** https://studio.atividata.com.br

**O que é:**
Um estúdio de criação de imagens com inteligência artificial. Pensa no Photoshop, mas em vez de editar, você descreve o que quer e a IA cria.

**O que produz:**
- Fotos de produto com fundo branco profissional (para vender no Mercado Livre, Shopee, etc.)
- Imagens de lifestyle (produto em cenários bonitos)
- Variações de imagem para A/B test de anúncios

**Quem usa:** Vendedores de e-commerce que precisam de fotos profissionais sem contratar fotógrafo.

**Quanto custa para o cliente:** R$15 por imagem, R$497/mês por pacote.

---

### 📊 Coolify — Gerenciador do Servidor
**Link:** https://coolify.atividata.com.br (uso interno)

**O que é:**
É o "painel de controle" do servidor. Igual ao cPanel de hospedagem, mas muito mais poderoso.

**Para que serve:**
Permite subir novos serviços, ver o que está rodando, configurar domínios, tudo por uma interface visual. Só o Yuri acessa.

---

### 🐳 Portainer — Gerenciador de Containers
**Link:** https://portainer.atividata.com.br (uso interno)

**O que é:**
Mostra todos os "programas" (containers) que estão rodando no servidor, quanto de memória e CPU cada um usa, e permite reiniciar ou parar qualquer um.

Analogia: é como o Gerenciador de Tarefas do Windows, mas para o servidor todo.

---

### 🎵 Emby — Servidor de Mídia
**Link:** https://emby.atividata.com.br

**O que é:**
É como um Netflix pessoal. Armazena filmes, séries e músicas no servidor e permite assistir de qualquer lugar, em qualquer dispositivo.

---

### 🌐 Golem Network — Computação Descentralizada
*Sem link público — funciona nos bastidores*

**O que é:**
Uma rede global onde pessoas alugam poder computacional umas das outras, como um Airbnb de computadores.

**O que o servidor faz:**
Quando a placa de vídeo e o processador não estão ocupados com outros serviços, eles ficam disponíveis nessa rede. Outras pessoas ao redor do mundo alugam esse poder para rodar programas pesados, e o servidor recebe pagamento em criptomoeda automaticamente.

**Quanto gera:** R$100 a R$450/mês de forma completamente passiva.

---

### 📡 Bandwidth Sharing — Compartilhamento de Internet
*Sem link público — funciona nos bastidores*

**O que é:**
O servidor compartilha uma pequena parte da sua conexão de internet com empresas que precisam de IPs residenciais brasileiros para pesquisa de mercado, verificação de preços, etc.

**Analogia:** É como alugar um quarto vazio — você não usa, mas alguém paga para ter acesso.

**Plataformas:** Honeygain, EarnApp, Pawns, PacketStream e outras.

**Quanto gera:** R$115 a R$230/mês sem fazer absolutamente nada.

---

## Como Tudo Se Conecta

```
Cliente quer API de IA
    → Paga via cartão (Stripe)
    → Sistema detecta o pagamento automaticamente
    → Cria o acesso do cliente sem ninguém precisar fazer nada
    → Manda as credenciais por email automaticamente
    → Cliente começa a usar a API

Enquanto isso, nos bastidores:
    → Vídeos sendo gerados automaticamente todo dia
    → Golem gerando renda com poder computacional ocioso
    → Bandwidth sharing gerando renda com internet ociosa
    → Sistema monitorando tudo e mandando alertas no Telegram se algo der errado
```

---

## O Que É Totalmente Automático

| O quê | Frequência |
|---|---|
| Geração de vídeos para YouTube | Todo dia às 10h |
| Monitoramento de saúde dos serviços | A cada 15 minutos |
| Backup dos dados | Todo dia às 4h |
| Atualização do código no GitHub | A cada hora |
| Provisão de novos clientes | Imediatamente ao pagar |
| Alertas de problema no Telegram | Em tempo real |
| Renda do Golem | Contínua |
| Renda de bandwidth | Contínua |

---

## Resumo Financeiro Esperado

| Fonte | Quando começa | Estimativa mensal |
|---|---|---|
| Golem (computação) | Já está rodando | R$100–400 |
| Bandwidth sharing | Após criar contas | R$100–200 |
| API de IA (1 cliente básico) | Após primeiro cliente | R$97/mês |
| API de IA (1 cliente pro) | Após primeiro cliente | R$297/mês |
| API de IA (1 cliente custom) | Após primeiro cliente | R$597/mês |
| Automação n8n (projeto único) | Após primeiro projeto | R$500–2.500 único |
| Retainer n8n (manutenção) | Após fechar contrato | R$297–797/mês |
| Monitor de preços (por loja) | Após primeiro cliente | R$297/mês |
| Newsletter IA (por nicho) | Após primeiro cliente | R$97/mês |
| Fotos de produto (por imagem) | Após ComfyUI subir | R$15–50/imagem |
| Pacote fotos mensal | Após ComfyUI subir | R$497/mês por cliente |
| Vídeo de produto | Após ComfyUI subir | R$97–297 por vídeo |
| YouTube Shorts (AdSense) | 30–90 dias para monetizar | R$50–500/mês |

### Cenários Reais

**Mês 1–2 (começando do zero, só 1 cliente de cada):**
| O quê | Valor |
|---|---|
| Golem + bandwidth | R$200 |
| 1 cliente API básica | R$97 |
| 1 projeto n8n | R$800 |
| 3 packs de foto | R$450 |
| **Total** | **~R$1.550/mês** |

**Mês 3–6 (base de clientes crescendo):**
| O quê | Valor |
|---|---|
| Golem + bandwidth | R$300 |
| 3 clientes API (1 básico + 1 pro + 1 custom) | R$991 |
| 2 retainers n8n | R$800 |
| 3 monitores de preço | R$891 |
| 2 newsletters IA | R$194 |
| Fotos/vídeos avulsos | R$600 |
| **Total** | **~R$3.776/mês** |

**Mês 6+ (no piloto automático):**
| O quê | Valor |
|---|---|
| Golem + bandwidth | R$400 |
| 5 clientes API | R$1.485 |
| 3 retainers n8n | R$1.500 |
| 5 monitores de preço | R$1.485 |
| 4 newsletters IA | R$388 |
| Fotos/vídeos | R$1.000 |
| YouTube AdSense | R$300 |
| **Total** | **~R$6.558/mês** |

> 💡 Com menos de 1 hora de trabalho por semana — o servidor faz o resto.

---

*Este servidor foi configurado e está sendo mantido automaticamente.*
*Dúvidas: fala com o Yuri.*
