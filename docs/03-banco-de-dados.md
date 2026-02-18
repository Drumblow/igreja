# 🗄️ Banco de Dados — Igreja Manager

## 1. Visão Geral

O banco de dados utiliza **PostgreSQL 15+** com as seguintes extensões habilitadas:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- Geração de UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";     -- Funções criptográficas
CREATE EXTENSION IF NOT EXISTS "unaccent";     -- Busca sem acentos
```

**Convenções:**
- Todas as tabelas possuem `id` UUID como chave primária
- Todas as tabelas possuem `created_at` e `updated_at` com timezone
- Soft delete via coluna `deleted_at` (quando aplicável)
- Coluna `church_id` em todas as tabelas de dados (multi-tenancy)
- Nomes de tabelas no plural e em snake_case

---

## 2. Diagrama Entidade-Relacionamento (Simplificado)

```
┌──────────────┐       ┌──────────────┐       ┌──────────────────┐
│   churches   │       │    users     │       │     roles        │
│──────────────│       │──────────────│       │──────────────────│
│ id (PK)      │◄──┐   │ id (PK)      │       │ id (PK)          │
│ name         │   │   │ church_id(FK)│───┐   │ name             │
│ cnpj         │   │   │ email        │   │   │ permissions      │
│ ...          │   │   │ password_hash│   │   └──────────────────┘
└──────────────┘   │   │ role_id (FK) │───┘
                   │   └──────────────┘
                   │
    ┌──────────────┼──────────────────────────────────┐
    │              │                                   │
    ▼              ▼                                   ▼
┌──────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────────┐
│ members  │  │financial_    │  │  assets   │  │ ebd_classes  │
│          │  │  entries     │  │          │  │              │
│ id (PK)  │  │ id (PK)      │  │ id (PK)  │  │ id (PK)      │
│church_id │  │ church_id    │  │church_id │  │ church_id    │
│ name     │  │ type         │  │ name     │  │ name         │
│ ...      │  │ amount       │  │ category │  │ teacher_id   │
└────┬─────┘  │ member_id    │  │ value    │  └──────┬───────┘
     │        └──────────────┘  └──────────┘         │
     │                                                │
     ▼                                                ▼
┌──────────┐                               ┌──────────────────┐
│ families │                               │ ebd_attendances  │
│          │                               │                  │
│ id (PK)  │                               │ id (PK)          │
│ name     │                               │ class_id (FK)    │
│ head_id  │                               │ member_id (FK)   │
└──────────┘                               │ date             │
                                           └──────────────────┘
```

---

## 3. Schemas Detalhados

### 3.1 Tabelas de Sistema (Schema `public`)

#### `churches` — Igrejas/Congregações

```sql
CREATE TABLE churches (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(200) NOT NULL,
    legal_name      VARCHAR(200),
    cnpj            VARCHAR(18) UNIQUE,
    email           VARCHAR(150),
    phone           VARCHAR(20),
    website         VARCHAR(200),
    
    -- Endereço
    zip_code        VARCHAR(10),
    street          VARCHAR(200),
    number          VARCHAR(20),
    complement      VARCHAR(100),
    neighborhood    VARCHAR(100),
    city            VARCHAR(100),
    state           CHAR(2),
    
    -- Configurações
    logo_url        VARCHAR(500),
    denomination    VARCHAR(100),        -- Denominação (Assembleia de Deus, Batista, etc.)
    founded_at      DATE,
    pastor_name     VARCHAR(150),
    
    -- Metadados
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    settings        JSONB DEFAULT '{}',  -- Configurações personalizadas
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_churches_cnpj ON churches(cnpj) WHERE cnpj IS NOT NULL;
CREATE INDEX idx_churches_active ON churches(is_active);
```

#### `roles` — Papéis de Acesso

```sql
CREATE TABLE roles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(50) NOT NULL UNIQUE,
    display_name    VARCHAR(100) NOT NULL,
    description     TEXT,
    permissions     JSONB NOT NULL DEFAULT '[]',  -- Array de permissões
    is_system       BOOLEAN NOT NULL DEFAULT FALSE, -- Roles padrão não editáveis
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Roles padrão
INSERT INTO roles (name, display_name, permissions, is_system) VALUES
('super_admin', 'Super Administrador', '["*"]', TRUE),
('pastor', 'Pastor/Líder', '["members:*", "financial:read", "financial:write", "assets:*", "ebd:*", "reports:*", "settings:read"]', TRUE),
('secretary', 'Secretário(a)', '["members:*", "ebd:*", "reports:members", "reports:ebd"]', TRUE),
('treasurer', 'Tesoureiro(a)', '["financial:*", "reports:financial"]', TRUE),
('asset_manager', 'Gestor de Patrimônio', '["assets:*", "reports:assets"]', TRUE),
('ebd_teacher', 'Professor(a) EBD', '["ebd:read", "ebd:attendance"]', TRUE),
('member', 'Membro', '["profile:read", "profile:write"]', TRUE);
```

#### `users` — Usuários do Sistema

```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    member_id       UUID,             -- Vínculo opcional com membro
    email           VARCHAR(150) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    role_id         UUID NOT NULL REFERENCES roles(id),
    
    -- Controle de acesso
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    email_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at   TIMESTAMPTZ,
    failed_attempts INT NOT NULL DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    
    -- Metadados
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(email, church_id)
);

CREATE INDEX idx_users_church ON users(church_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role_id);
```

#### `refresh_tokens` — Tokens de Refresh

```sql
CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT refresh_tokens_token_hash_unique UNIQUE(token_hash)
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);
```

#### `audit_logs` — Logs de Auditoria

```sql
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    user_id         UUID REFERENCES users(id),
    action          VARCHAR(50) NOT NULL,      -- CREATE, UPDATE, DELETE
    entity_type     VARCHAR(50) NOT NULL,      -- member, financial_entry, etc.
    entity_id       UUID NOT NULL,
    old_values      JSONB,
    new_values      JSONB,
    ip_address      INET,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_church ON audit_logs(church_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);
```

---

### 3.2 Tabelas do Módulo de Membros

#### `members` — Membros da Igreja

```sql
CREATE TABLE members (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id           UUID NOT NULL REFERENCES churches(id),
    family_id           UUID,             -- FK definida após criar families
    
    -- Dados pessoais
    full_name           VARCHAR(200) NOT NULL,
    social_name         VARCHAR(200),
    birth_date          DATE,
    gender              VARCHAR(20) NOT NULL CHECK (gender IN ('masculino', 'feminino')),
    marital_status      VARCHAR(20) CHECK (marital_status IN ('solteiro', 'casado', 'divorciado', 'viuvo', 'uniao_estavel')),
    cpf                 VARCHAR(14),
    rg                  VARCHAR(20),
    email               VARCHAR(150),
    phone_primary       VARCHAR(20),
    phone_secondary     VARCHAR(20),
    photo_url           VARCHAR(500),
    
    -- Endereço
    zip_code            VARCHAR(10),
    street              VARCHAR(200),
    number              VARCHAR(20),
    complement          VARCHAR(100),
    neighborhood        VARCHAR(100),
    city                VARCHAR(100),
    state               CHAR(2),
    
    -- Dados adicionais
    profession          VARCHAR(100),
    workplace           VARCHAR(150),
    birthplace_city     VARCHAR(100),
    birthplace_state    CHAR(2),
    nationality         VARCHAR(50) DEFAULT 'Brasileiro(a)',
    education_level     VARCHAR(50),
    blood_type          VARCHAR(5),
    
    -- Dados eclesiásticos
    conversion_date     DATE,
    water_baptism_date  DATE,
    spirit_baptism_date DATE,
    origin_church       VARCHAR(200),
    entry_date          DATE,
    entry_type          VARCHAR(30) CHECK (entry_type IN ('batismo', 'transferencia', 'aclamacao', 'reconciliacao', 'fundador')),
    role_position       VARCHAR(50) CHECK (role_position IN ('pastor', 'evangelista', 'presbitero', 'diacono', 'cooperador', 'membro', 'congregado')),
    ordination_date     DATE,
    
    -- Status
    status              VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'transferido', 'desligado', 'falecido', 'visitante', 'congregado')),
    status_changed_at   TIMESTAMPTZ,
    status_reason       TEXT,
    
    -- Observações
    notes               TEXT,
    
    -- Metadados
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

-- Índices
CREATE INDEX idx_members_church ON members(church_id);
CREATE INDEX idx_members_family ON members(family_id) WHERE family_id IS NOT NULL;
CREATE INDEX idx_members_status ON members(church_id, status);
CREATE INDEX idx_members_name ON members(church_id, full_name);
CREATE INDEX idx_members_birth ON members(church_id, birth_date);
CREATE INDEX idx_members_entry_date ON members(church_id, entry_date);
CREATE INDEX idx_members_role ON members(church_id, role_position);
CREATE INDEX idx_members_deleted ON members(deleted_at) WHERE deleted_at IS NULL;

-- Índice para busca textual sem acentos
CREATE INDEX idx_members_name_search ON members 
    USING gin(to_tsvector('portuguese', unaccent(full_name)));
```

#### `families` — Famílias

```sql
CREATE TABLE families (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    name            VARCHAR(100) NOT NULL,          -- Ex: "Família Silva"
    head_id         UUID REFERENCES members(id),    -- Responsável da família
    
    -- Endereço da família (compartilhado)
    zip_code        VARCHAR(10),
    street          VARCHAR(200),
    number          VARCHAR(20),
    complement      VARCHAR(100),
    neighborhood    VARCHAR(100),
    city            VARCHAR(100),
    state           CHAR(2),
    
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Adicionar FK de members.family_id
ALTER TABLE members ADD CONSTRAINT fk_members_family 
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE SET NULL;

CREATE INDEX idx_families_church ON families(church_id);
```

#### `family_relationships` — Relacionamentos Familiares

```sql
CREATE TABLE family_relationships (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id       UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    member_id       UUID NOT NULL REFERENCES members(id),
    relationship    VARCHAR(30) NOT NULL CHECK (relationship IN (
        'chefe', 'conjuge', 'filho', 'filha', 'pai', 'mae', 
        'avo', 'avoa', 'neto', 'neta', 'irmao', 'irma', 
        'sogro', 'sogra', 'genro', 'nora', 'outro'
    )),
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(family_id, member_id)
);

CREATE INDEX idx_family_rel_family ON family_relationships(family_id);
CREATE INDEX idx_family_rel_member ON family_relationships(member_id);
```

#### `ministries` — Ministérios da Igreja

```sql
CREATE TABLE ministries (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    name            VARCHAR(100) NOT NULL,
    description     TEXT,
    leader_id       UUID REFERENCES members(id),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ministries_church ON ministries(church_id);
```

#### `member_ministries` — Vínculo Membro-Ministério

```sql
CREATE TABLE member_ministries (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    member_id       UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    ministry_id     UUID NOT NULL REFERENCES ministries(id) ON DELETE CASCADE,
    joined_at       DATE NOT NULL DEFAULT CURRENT_DATE,
    left_at         DATE,
    role_in_ministry VARCHAR(50),     -- Líder, vice-líder, membro
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(member_id, ministry_id, joined_at)
);

CREATE INDEX idx_member_ministries_member ON member_ministries(member_id);
CREATE INDEX idx_member_ministries_ministry ON member_ministries(ministry_id);
```

#### `member_history` — Histórico de Eventos do Membro

```sql
CREATE TABLE member_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    member_id       UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    event_type      VARCHAR(50) NOT NULL CHECK (event_type IN (
        'ingresso', 'batismo_aguas', 'batismo_espirito', 'casamento',
        'mudanca_cargo', 'entrada_ministerio', 'saida_ministerio',
        'transferencia_entrada', 'transferencia_saida',
        'disciplina', 'reconciliacao', 'desligamento',
        'reintegracao', 'falecimento', 'outro'
    )),
    event_date      DATE NOT NULL,
    description     TEXT NOT NULL,
    previous_value  VARCHAR(100),
    new_value       VARCHAR(100),
    registered_by   UUID REFERENCES users(id),
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_member_history_member ON member_history(member_id);
CREATE INDEX idx_member_history_church ON member_history(church_id);
CREATE INDEX idx_member_history_date ON member_history(event_date);
```

---

### 3.3 Tabelas do Módulo Financeiro

#### `account_plans` — Plano de Contas

```sql
CREATE TABLE account_plans (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    parent_id       UUID REFERENCES account_plans(id),  -- Subcategoria
    code            VARCHAR(20) NOT NULL,                -- Ex: "1.01", "2.03.01"
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(10) NOT NULL CHECK (type IN ('receita', 'despesa')),
    level           SMALLINT NOT NULL DEFAULT 1,         -- Nível na hierarquia (1, 2, 3)
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(church_id, code)
);

CREATE INDEX idx_account_plans_church ON account_plans(church_id);
CREATE INDEX idx_account_plans_parent ON account_plans(parent_id);
CREATE INDEX idx_account_plans_type ON account_plans(church_id, type);
```

#### `bank_accounts` — Contas Bancárias/Caixas

```sql
CREATE TABLE bank_accounts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    name            VARCHAR(100) NOT NULL,          -- Ex: "Caixa Principal", "Conta Bradesco"
    type            VARCHAR(20) NOT NULL CHECK (type IN ('caixa', 'conta_corrente', 'poupanca', 'digital')),
    bank_name       VARCHAR(100),
    agency          VARCHAR(20),
    account_number  VARCHAR(30),
    initial_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    current_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bank_accounts_church ON bank_accounts(church_id);
```

#### `financial_entries` — Lançamentos Financeiros

```sql
CREATE TABLE financial_entries (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    
    -- Classificação
    type            VARCHAR(10) NOT NULL CHECK (type IN ('receita', 'despesa')),
    account_plan_id UUID NOT NULL REFERENCES account_plans(id),
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id),
    campaign_id     UUID,             -- FK para campaigns (se vinculado)
    
    -- Valores
    amount          DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    
    -- Datas
    entry_date      DATE NOT NULL,               -- Data do lançamento
    due_date        DATE,                        -- Data de vencimento (despesas)
    payment_date    DATE,                        -- Data efetiva do pagamento
    
    -- Detalhes
    description     TEXT NOT NULL,
    payment_method  VARCHAR(30) CHECK (payment_method IN (
        'dinheiro', 'pix', 'transferencia', 'cartao_debito', 
        'cartao_credito', 'cheque', 'boleto', 'outro'
    )),
    
    -- Vínculo com membro (dízimo/oferta nominal)
    member_id       UUID REFERENCES members(id),
    
    -- Fornecedor (despesas)
    supplier_name   VARCHAR(200),
    
    -- Comprovante
    receipt_url     VARCHAR(500),
    
    -- Controle
    status          VARCHAR(20) NOT NULL DEFAULT 'confirmado' CHECK (status IN (
        'pendente', 'confirmado', 'cancelado', 'estornado'
    )),
    is_recurring    BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_id    UUID,             -- Agrupa lançamentos recorrentes
    
    -- Fechamento
    is_closed       BOOLEAN NOT NULL DEFAULT FALSE,
    closed_at       TIMESTAMPTZ,
    closed_by       UUID REFERENCES users(id),
    
    -- Metadados
    registered_by   UUID NOT NULL REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

-- Índices
CREATE INDEX idx_fin_entries_church ON financial_entries(church_id);
CREATE INDEX idx_fin_entries_type ON financial_entries(church_id, type);
CREATE INDEX idx_fin_entries_date ON financial_entries(church_id, entry_date);
CREATE INDEX idx_fin_entries_account ON financial_entries(account_plan_id);
CREATE INDEX idx_fin_entries_bank ON financial_entries(bank_account_id);
CREATE INDEX idx_fin_entries_member ON financial_entries(member_id) WHERE member_id IS NOT NULL;
CREATE INDEX idx_fin_entries_campaign ON financial_entries(campaign_id) WHERE campaign_id IS NOT NULL;
CREATE INDEX idx_fin_entries_status ON financial_entries(church_id, status);
CREATE INDEX idx_fin_entries_deleted ON financial_entries(deleted_at) WHERE deleted_at IS NULL;
```

#### `campaigns` — Campanhas Financeiras

```sql
CREATE TABLE campaigns (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    goal_amount     DECIMAL(15,2),
    raised_amount   DECIMAL(15,2) NOT NULL DEFAULT 0,   -- Calculado via trigger/app
    start_date      DATE NOT NULL,
    end_date        DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa', 'encerrada', 'cancelada')),
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE financial_entries ADD CONSTRAINT fk_fin_entries_campaign
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id);

CREATE INDEX idx_campaigns_church ON campaigns(church_id);
CREATE INDEX idx_campaigns_status ON campaigns(church_id, status);
```

#### `monthly_closings` — Fechamentos Mensais

```sql
CREATE TABLE monthly_closings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    reference_month DATE NOT NULL,        -- Sempre primeiro dia do mês
    
    total_income    DECIMAL(15,2) NOT NULL,
    total_expense   DECIMAL(15,2) NOT NULL,
    balance         DECIMAL(15,2) NOT NULL,
    
    previous_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    accumulated_balance DECIMAL(15,2) NOT NULL,
    
    closed_by       UUID NOT NULL REFERENCES users(id),
    notes           TEXT,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(church_id, reference_month)
);

CREATE INDEX idx_monthly_closings_church ON monthly_closings(church_id);
```

---

### 3.4 Tabelas do Módulo de Patrimônio

#### `asset_categories` — Categorias de Bens

```sql
CREATE TABLE asset_categories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    parent_id       UUID REFERENCES asset_categories(id),
    name            VARCHAR(100) NOT NULL,
    useful_life_months INT,              -- Vida útil em meses (para depreciação)
    depreciation_rate DECIMAL(5,2),      -- Taxa anual de depreciação (%)
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(church_id, name)
);

CREATE INDEX idx_asset_categories_church ON asset_categories(church_id);
```

#### `assets` — Bens Patrimoniais

```sql
CREATE TABLE assets (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id           UUID NOT NULL REFERENCES churches(id),
    category_id         UUID NOT NULL REFERENCES asset_categories(id),
    
    -- Identificação
    asset_code          VARCHAR(20) NOT NULL,   -- Código de tombamento
    description         VARCHAR(300) NOT NULL,
    brand               VARCHAR(100),
    model               VARCHAR(100),
    serial_number       VARCHAR(100),
    
    -- Aquisição
    acquisition_date    DATE,
    acquisition_value   DECIMAL(15,2),
    acquisition_type    VARCHAR(20) CHECK (acquisition_type IN ('compra', 'doacao', 'construcao', 'outro')),
    donor_member_id     UUID REFERENCES members(id),
    invoice_url         VARCHAR(500),
    
    -- Valores
    current_value       DECIMAL(15,2),
    residual_value      DECIMAL(15,2),
    accumulated_depreciation DECIMAL(15,2) DEFAULT 0,
    
    -- Localização
    location            VARCHAR(150),           -- Departamento/sala
    
    -- Estado
    condition           VARCHAR(20) NOT NULL DEFAULT 'bom' CHECK (condition IN (
        'novo', 'bom', 'regular', 'ruim', 'inservivel'
    )),
    status              VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (status IN (
        'ativo', 'em_manutencao', 'baixado', 'cedido', 'alienado'
    )),
    status_date         DATE,
    status_reason       TEXT,
    
    -- Observações
    notes               TEXT,
    
    -- Metadados
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    
    UNIQUE(church_id, asset_code)
);

CREATE INDEX idx_assets_church ON assets(church_id);
CREATE INDEX idx_assets_category ON assets(category_id);
CREATE INDEX idx_assets_status ON assets(church_id, status);
CREATE INDEX idx_assets_code ON assets(church_id, asset_code);
```

#### `asset_photos` — Fotos dos Bens

```sql
CREATE TABLE asset_photos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id        UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    photo_url       VARCHAR(500) NOT NULL,
    caption         VARCHAR(200),
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_asset_photos_asset ON asset_photos(asset_id);
```

#### `maintenances` — Manutenções

```sql
CREATE TABLE maintenances (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    asset_id        UUID NOT NULL REFERENCES assets(id),
    
    type            VARCHAR(20) NOT NULL CHECK (type IN ('preventiva', 'corretiva')),
    description     TEXT NOT NULL,
    supplier_name   VARCHAR(200),
    cost            DECIMAL(15,2),
    
    scheduled_date  DATE,
    execution_date  DATE,
    next_maintenance_date DATE,
    
    status          VARCHAR(20) NOT NULL DEFAULT 'agendada' CHECK (status IN (
        'agendada', 'em_andamento', 'concluida', 'cancelada'
    )),
    
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_maintenances_church ON maintenances(church_id);
CREATE INDEX idx_maintenances_asset ON maintenances(asset_id);
CREATE INDEX idx_maintenances_status ON maintenances(church_id, status);
```

#### `inventories` — Inventários

```sql
CREATE TABLE inventories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    
    name            VARCHAR(100) NOT NULL,
    reference_date  DATE NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'em_andamento', 'concluido')),
    
    total_items     INT DEFAULT 0,
    found_items     INT DEFAULT 0,
    missing_items   INT DEFAULT 0,
    divergent_items INT DEFAULT 0,
    
    conducted_by    UUID REFERENCES users(id),
    notes           TEXT,
    
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inventories_church ON inventories(church_id);
```

#### `inventory_items` — Itens do Inventário

```sql
CREATE TABLE inventory_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id    UUID NOT NULL REFERENCES inventories(id) ON DELETE CASCADE,
    asset_id        UUID NOT NULL REFERENCES assets(id),
    
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN (
        'pendente', 'encontrado', 'nao_encontrado', 'divergencia'
    )),
    observed_condition VARCHAR(20),
    notes           TEXT,
    checked_at      TIMESTAMPTZ,
    checked_by      UUID REFERENCES users(id),
    
    UNIQUE(inventory_id, asset_id)
);

CREATE INDEX idx_inventory_items_inventory ON inventory_items(inventory_id);
```

#### `asset_loans` — Empréstimos de Bens

```sql
CREATE TABLE asset_loans (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id           UUID NOT NULL REFERENCES churches(id),
    asset_id            UUID NOT NULL REFERENCES assets(id),
    borrower_member_id  UUID NOT NULL REFERENCES members(id),
    
    loan_date           DATE NOT NULL,
    expected_return_date DATE NOT NULL,
    actual_return_date  DATE,
    
    condition_out       VARCHAR(20) NOT NULL,    -- Estado na saída
    condition_in        VARCHAR(20),             -- Estado na devolução
    
    notes               TEXT,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_asset_loans_church ON asset_loans(church_id);
CREATE INDEX idx_asset_loans_asset ON asset_loans(asset_id);
CREATE INDEX idx_asset_loans_borrower ON asset_loans(borrower_member_id);
```

---

### 3.5 Tabelas do Módulo EBD

#### `ebd_terms` — Períodos/Trimestres da EBD

```sql
CREATE TABLE ebd_terms (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    name            VARCHAR(100) NOT NULL,        -- Ex: "1º Trimestre 2026"
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    theme           VARCHAR(200),                 -- Tema geral do trimestre
    magazine_title  VARCHAR(200),                 -- Nome da revista
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ebd_terms_church ON ebd_terms(church_id);
CREATE INDEX idx_ebd_terms_active ON ebd_terms(church_id, is_active);
```

#### `ebd_classes` — Turmas da EBD

```sql
CREATE TABLE ebd_classes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    term_id         UUID NOT NULL REFERENCES ebd_terms(id),
    
    name            VARCHAR(100) NOT NULL,
    age_range_start INT,                          -- Idade mínima
    age_range_end   INT,                          -- Idade máxima
    room            VARCHAR(50),                  -- Sala
    max_capacity    INT,
    
    teacher_id      UUID REFERENCES members(id),  -- Professor titular
    aux_teacher_id  UUID REFERENCES members(id),  -- Professor auxiliar
    
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ebd_classes_church ON ebd_classes(church_id);
CREATE INDEX idx_ebd_classes_term ON ebd_classes(term_id);
CREATE INDEX idx_ebd_classes_teacher ON ebd_classes(teacher_id);
```

#### `ebd_enrollments` — Matrículas na EBD

```sql
CREATE TABLE ebd_enrollments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id        UUID NOT NULL REFERENCES ebd_classes(id) ON DELETE CASCADE,
    member_id       UUID NOT NULL REFERENCES members(id),
    
    enrolled_at     DATE NOT NULL DEFAULT CURRENT_DATE,
    left_at         DATE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    notes           TEXT,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(class_id, member_id)
);

CREATE INDEX idx_ebd_enrollments_class ON ebd_enrollments(class_id);
CREATE INDEX idx_ebd_enrollments_member ON ebd_enrollments(member_id);
```

#### `ebd_lessons` — Aulas/Lições

```sql
CREATE TABLE ebd_lessons (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    class_id        UUID NOT NULL REFERENCES ebd_classes(id),
    
    lesson_date     DATE NOT NULL,
    lesson_number   INT,                          -- Número da lição na revista
    title           VARCHAR(200),
    theme           VARCHAR(200),
    bible_text      VARCHAR(200),                 -- Ex: "João 3:16-21"
    summary         TEXT,
    
    teacher_id      UUID REFERENCES members(id),  -- Quem ministrou (pode diferir do titular)
    materials_used  TEXT,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(class_id, lesson_date)
);

CREATE INDEX idx_ebd_lessons_church ON ebd_lessons(church_id);
CREATE INDEX idx_ebd_lessons_class ON ebd_lessons(class_id);
CREATE INDEX idx_ebd_lessons_date ON ebd_lessons(lesson_date);
```

#### `ebd_attendances` — Frequência da EBD

```sql
CREATE TABLE ebd_attendances (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id       UUID NOT NULL REFERENCES ebd_lessons(id) ON DELETE CASCADE,
    member_id       UUID NOT NULL REFERENCES members(id),
    
    status          VARCHAR(20) NOT NULL DEFAULT 'presente' CHECK (status IN (
        'presente', 'ausente', 'justificado'
    )),
    brought_bible   BOOLEAN DEFAULT FALSE,
    brought_magazine BOOLEAN DEFAULT FALSE,
    offering_amount DECIMAL(10,2) DEFAULT 0,
    
    is_visitor      BOOLEAN NOT NULL DEFAULT FALSE,  -- Visitante (não matriculado)
    visitor_name    VARCHAR(200),                     -- Nome se for visitante não cadastrado
    
    notes           TEXT,
    registered_by   UUID REFERENCES users(id),
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(lesson_id, member_id)
);

CREATE INDEX idx_ebd_attendances_lesson ON ebd_attendances(lesson_id);
CREATE INDEX idx_ebd_attendances_member ON ebd_attendances(member_id);
```

---

## 4. Views Úteis

```sql
-- View: Resumo de membros por status
CREATE VIEW vw_member_stats AS
SELECT 
    church_id,
    status,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE gender = 'masculino') as male_count,
    COUNT(*) FILTER (WHERE gender = 'feminino') as female_count
FROM members
WHERE deleted_at IS NULL
GROUP BY church_id, status;

-- View: Saldo financeiro por conta
CREATE VIEW vw_account_balances AS
SELECT
    ba.id as bank_account_id,
    ba.church_id,
    ba.name as account_name,
    ba.initial_balance,
    COALESCE(SUM(CASE WHEN fe.type = 'receita' AND fe.status = 'confirmado' THEN fe.amount ELSE 0 END), 0) as total_income,
    COALESCE(SUM(CASE WHEN fe.type = 'despesa' AND fe.status = 'confirmado' THEN fe.amount ELSE 0 END), 0) as total_expense,
    ba.initial_balance 
        + COALESCE(SUM(CASE WHEN fe.type = 'receita' AND fe.status = 'confirmado' THEN fe.amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN fe.type = 'despesa' AND fe.status = 'confirmado' THEN fe.amount ELSE 0 END), 0) as current_balance
FROM bank_accounts ba
LEFT JOIN financial_entries fe ON fe.bank_account_id = ba.id AND fe.deleted_at IS NULL
GROUP BY ba.id, ba.church_id, ba.name, ba.initial_balance;

-- View: Frequência da EBD por turma
CREATE VIEW vw_ebd_class_attendance AS
SELECT
    ec.church_id,
    ec.id as class_id,
    ec.name as class_name,
    el.lesson_date,
    COUNT(ea.id) FILTER (WHERE ea.status = 'presente') as present_count,
    COUNT(ea.id) FILTER (WHERE ea.status = 'ausente') as absent_count,
    COUNT(ea.id) FILTER (WHERE ea.status = 'justificado') as justified_count,
    COUNT(ea.id) as total_students,
    COALESCE(SUM(ea.offering_amount), 0) as total_offering,
    COUNT(ea.id) FILTER (WHERE ea.brought_bible = TRUE) as bibles_count,
    COUNT(ea.id) FILTER (WHERE ea.brought_magazine = TRUE) as magazines_count
FROM ebd_classes ec
JOIN ebd_lessons el ON el.class_id = ec.id
LEFT JOIN ebd_attendances ea ON ea.lesson_id = el.id
GROUP BY ec.church_id, ec.id, ec.name, el.lesson_date;
```

---

## 5. Triggers

```sql
-- Trigger: Atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar em todas as tabelas com updated_at
CREATE TRIGGER trg_churches_updated BEFORE UPDATE ON churches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_members_updated BEFORE UPDATE ON members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_financial_entries_updated BEFORE UPDATE ON financial_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_assets_updated BEFORE UPDATE ON assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_ebd_classes_updated BEFORE UPDATE ON ebd_classes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger: Atualizar saldo da campanha ao inserir/atualizar lançamento
CREATE OR REPLACE FUNCTION update_campaign_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.campaign_id IS NOT NULL AND NEW.status = 'confirmado' THEN
        UPDATE campaigns SET raised_amount = (
            SELECT COALESCE(SUM(amount), 0)
            FROM financial_entries
            WHERE campaign_id = NEW.campaign_id
              AND status = 'confirmado'
              AND deleted_at IS NULL
        )
        WHERE id = NEW.campaign_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_campaign_balance
AFTER INSERT OR UPDATE ON financial_entries
FOR EACH ROW EXECUTE FUNCTION update_campaign_balance();

-- Trigger: Gerar código de tombamento automaticamente
CREATE OR REPLACE FUNCTION generate_asset_code()
RETURNS TRIGGER AS $$
DECLARE
    next_seq INT;
BEGIN
    IF NEW.asset_code IS NULL OR NEW.asset_code = '' THEN
        SELECT COALESCE(MAX(CAST(SUBSTRING(asset_code FROM '[0-9]+$') AS INT)), 0) + 1
        INTO next_seq
        FROM assets
        WHERE church_id = NEW.church_id;
        
        NEW.asset_code = 'PAT-' || LPAD(next_seq::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_asset_code
BEFORE INSERT ON assets
FOR EACH ROW EXECUTE FUNCTION generate_asset_code();
```

---

## 6. Seeds (Dados Iniciais)

```sql
-- Categorias padrão do plano de contas (receitas)
-- Executar após criar a igreja
-- church_id deve ser substituído pelo UUID real

-- RECEITAS
INSERT INTO account_plans (church_id, code, name, type, level) VALUES
('CHURCH_UUID', '1', 'Receitas', 'receita', 1),
('CHURCH_UUID', '1.01', 'Dízimos', 'receita', 2),
('CHURCH_UUID', '1.02', 'Ofertas', 'receita', 2),
('CHURCH_UUID', '1.03', 'Campanhas', 'receita', 2),
('CHURCH_UUID', '1.04', 'Doações', 'receita', 2),
('CHURCH_UUID', '1.05', 'Eventos', 'receita', 2),
('CHURCH_UUID', '1.06', 'Aluguéis', 'receita', 2),
('CHURCH_UUID', '1.07', 'Outras Receitas', 'receita', 2);

-- DESPESAS
INSERT INTO account_plans (church_id, code, name, type, level) VALUES
('CHURCH_UUID', '2', 'Despesas', 'despesa', 1),
('CHURCH_UUID', '2.01', 'Pessoal', 'despesa', 2),
('CHURCH_UUID', '2.01.01', 'Salários', 'despesa', 3),
('CHURCH_UUID', '2.01.02', 'Encargos', 'despesa', 3),
('CHURCH_UUID', '2.01.03', 'Benefícios', 'despesa', 3),
('CHURCH_UUID', '2.02', 'Infraestrutura', 'despesa', 2),
('CHURCH_UUID', '2.02.01', 'Aluguel', 'despesa', 3),
('CHURCH_UUID', '2.02.02', 'Água', 'despesa', 3),
('CHURCH_UUID', '2.02.03', 'Energia Elétrica', 'despesa', 3),
('CHURCH_UUID', '2.02.04', 'Telefone/Internet', 'despesa', 3),
('CHURCH_UUID', '2.03', 'Manutenção', 'despesa', 2),
('CHURCH_UUID', '2.04', 'Material de Escritório', 'despesa', 2),
('CHURCH_UUID', '2.05', 'Material de Limpeza', 'despesa', 2),
('CHURCH_UUID', '2.06', 'Missões', 'despesa', 2),
('CHURCH_UUID', '2.07', 'Ação Social', 'despesa', 2),
('CHURCH_UUID', '2.08', 'Eventos', 'despesa', 2),
('CHURCH_UUID', '2.09', 'Dízimos Repassados', 'despesa', 2),
('CHURCH_UUID', '2.10', 'Outras Despesas', 'despesa', 2);

-- Categorias padrão de patrimônio
INSERT INTO asset_categories (church_id, name, useful_life_months, depreciation_rate) VALUES
('CHURCH_UUID', 'Imóveis', 300, 4.00),
('CHURCH_UUID', 'Veículos', 60, 20.00),
('CHURCH_UUID', 'Equipamentos de Som', 120, 10.00),
('CHURCH_UUID', 'Instrumentos Musicais', 120, 10.00),
('CHURCH_UUID', 'Mobiliário', 120, 10.00),
('CHURCH_UUID', 'Equipamentos de Informática', 60, 20.00),
('CHURCH_UUID', 'Equipamentos de Cozinha', 120, 10.00),
('CHURCH_UUID', 'Equipamentos de Projeção', 60, 20.00),
('CHURCH_UUID', 'Outros', 120, 10.00);
```

---

## 7. Estratégia de Backups

```bash
# Backup diário automatizado
pg_dump -U igreja_user -h localhost -F c -b -v -f "backup_$(date +%Y%m%d_%H%M).dump" igreja_manager

# Restore
pg_restore -U igreja_user -h localhost -d igreja_manager -v backup_20260218.dump
```

**Política recomendada:**
- Backup completo diário (retenção: 30 dias)
- Backup semanal (retenção: 3 meses)
- Backup mensal (retenção: 1 ano)
- WAL archiving para point-in-time recovery

---

*Modelo de dados vivo — evolui conforme novas funcionalidades são implementadas.*
