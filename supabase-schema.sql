-- ═══════════════════════════════════════════════════════════
--  AGENDIO SaaS — Schema do Supabase
--  Execute este SQL no Supabase > SQL Editor > New query
-- ═══════════════════════════════════════════════════════════

-- 1. NEGÓCIOS (um por cliente do Agendio)
create table if not exists businesses (
  id               uuid primary key default gen_random_uuid(),
  owner_uid        uuid not null,          -- ID do usuário no Supabase Auth
  owner_email      text,
  nome_negocio     text not null,
  slug             text not null unique,   -- URL: agendio.com/este-slug
  status           text default 'ativo',   -- ativo | vencido | cancelado
  data_vencimento  timestamptz,
  plano            text default 'teste',   -- teste | pioneiro | mensal
  config           jsonb default '{}',     -- todas as configurações do negócio
  created_at       timestamptz default now()
);

-- 2. AGENDAMENTOS (isolados por business_id)
create table if not exists appointments (
  id               uuid primary key default gen_random_uuid(),
  business_id      uuid not null references businesses(id) on delete cascade,
  date             text not null,          -- "2025-03-15"
  time             text not null,          -- "09:00"
  name             text,
  phone            text,
  code             text,                   -- código de cancelamento
  booked_at        bigint,
  arrived          boolean default false,
  freed            boolean default false,
  freed_at         bigint,
  countdown_start  bigint,
  cancelled        boolean default false,
  cancelled_at     bigint,
  unique(business_id, date, time)
);

-- 3. LOGS DE ERRO E EVENTOS
create table if not exists logs (
  id           uuid primary key default gen_random_uuid(),
  business_id  uuid references businesses(id) on delete set null,
  type         text,                       -- error | info | warn
  message      text,
  data         text,                       -- JSON stringificado
  created_at   timestamptz default now()
);

-- 4. LOG DE PAGAMENTOS (para integração futura com Kiwify)
create table if not exists payments_log (
  id           uuid primary key default gen_random_uuid(),
  business_id  uuid references businesses(id) on delete set null,
  event        text,                       -- purchase | subscription_renewed | etc
  amount       numeric,
  payload      text,                       -- JSON do webhook
  created_at   timestamptz default now()
);

-- ── ÍNDICES para performance ─────────────────────────────────────
create index if not exists idx_appointments_business_date on appointments(business_id, date);
create index if not exists idx_businesses_slug            on businesses(slug);
create index if not exists idx_businesses_owner           on businesses(owner_uid);
create index if not exists idx_logs_business              on logs(business_id);

-- ── ROW LEVEL SECURITY (RLS) ─────────────────────────────────────
-- Garante que cada usuário só acessa dados do próprio negócio

alter table businesses   enable row level security;
alter table appointments enable row level security;
alter table logs         enable row level security;
alter table payments_log enable row level security;

-- Businesses: dono só vê/edita o próprio
create policy "owner_businesses" on businesses
  for all using (owner_uid = auth.uid());

-- Appointments: dono do negócio acessa todos os agendamentos do seu business
create policy "owner_appointments" on appointments
  for all using (
    business_id in (select id from businesses where owner_uid = auth.uid())
  );

-- Clientes (anon) podem inserir e ler agendamentos do negócio que estão visitando
create policy "anon_read_appointments" on appointments
  for select using (true);

create policy "anon_insert_appointments" on appointments
  for insert with check (true);

create policy "anon_update_appointments" on appointments
  for update using (true);

-- Businesses: leitura pública por slug (para a página pública funcionar)
create policy "public_read_businesses" on businesses
  for select using (true);

-- Logs: apenas o sistema insere, dono lê
create policy "insert_logs" on logs
  for insert with check (true);

create policy "owner_read_logs" on logs
  for select using (
    business_id in (select id from businesses where owner_uid = auth.uid())
  );
