# Agendio SaaS — Guia de Deploy

## Estrutura dos arquivos

```
agendio-netlify/
├── index.html              ← Página inicial (marketing / login)
├── netlify.toml            ← Roteamento do Netlify
├── public/
│   └── index.html          ← Página pública de agendamento (/nome-do-negocio)
├── admin/
│   └── index.html          ← Painel administrativo (/admin)
└── supabase-schema.sql     ← SQL para criar as tabelas (rode 1 vez)
```

---

## PASSO 1 — Criar as tabelas no Supabase

1. Acesse **supabase.com** → seu projeto `agendio-saas`
2. Menu lateral → **SQL Editor** → **New query**
3. Cole todo o conteúdo do arquivo `supabase-schema.sql`
4. Clique em **Run** (botão verde)
5. Deve aparecer "Success" para cada comando

---

## PASSO 2 — Deploy no Netlify

### Opção A — Arrastar e soltar (mais fácil)

1. Acesse **netlify.com** e crie uma conta grátis
2. No dashboard → clique em **"Add new site"** → **"Deploy manually"**
3. Arraste a pasta **agendio-netlify** inteira para a área de deploy
4. Aguarda 1 minuto
5. O Netlify gera uma URL como `https://random-name.netlify.app`

### Opção B — Via GitHub (recomendado para updates futuros)

1. Crie um repositório no GitHub com os arquivos
2. No Netlify → **"Add new site"** → **"Import from Git"**
3. Conecta o repositório
4. Build settings: deixa tudo vazio (é site estático)
5. Clica em **Deploy**

---

## PASSO 3 — Configurar domínio personalizado (opcional)

Se quiser usar `agendio.com.br` em vez do URL do Netlify:

1. Netlify → seu site → **Domain settings** → **Add custom domain**
2. Digite `agendio.com.br`
3. Aponta os DNS do seu domínio para o Netlify (instruções aparecem na tela)

---

## Como funciona o sistema

### Página pública
- URL: `seusite.netlify.app/nome-do-negocio`
- Qualquer pessoa acessa sem login
- Se assinatura vencida → mostra aviso, não desaparece

### Painel admin
- URL: `seusite.netlify.app/admin`
- Login com e-mail e senha (Supabase Auth)
- No primeiro acesso → tela de setup do negócio
- Cada usuário só vê dados do próprio negócio (multi-tenant)

### Assinatura de teste
- Ao criar a conta, o sistema dá **30 dias grátis automaticamente**
- Após 30 dias, redireciona para renovação via Kiwify
- Link de pagamento: `https://pay.kiwify.com.br/oRpQmq7`

---

## Integração futura com Kiwify (webhook)

Quando o cliente pagar, a Kiwify envia um webhook. Para processar automaticamente:

1. No Netlify → **Functions** → crie `netlify/functions/kiwify-webhook.js`
2. A função deve:
   - Receber o POST da Kiwify
   - Verificar o HMAC-SHA256 da assinatura
   - Buscar o negócio pelo e-mail do comprador
   - Atualizar `status = 'ativo'` e `data_vencimento = hoje + 30 dias`
   - Salvar na tabela `payments_log`

A tabela `payments_log` já está criada e pronta para isso.

---

## Suporte
WhatsApp: 5521973938044
