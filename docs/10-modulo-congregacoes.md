# 🏛️ Módulo de Congregações — Igreja Manager

> **Data de criação:** 20 de fevereiro de 2026  
> **Versão do documento:** 1.1  
> **Status:** ✅ Implementado  
> **Módulo afetado:** Todos (Transversal)

---

## 1. Contexto e Motivação

### 1.1 Cenário Real

A igreja está localizada em **Tutóia-MA** e possui a seguinte estrutura organizacional:

```
AD Ministério de Tutóia (Igreja)
├── Sede (Templo Central)          → Pastor Presidente
├── Congregação Paxicá             → Dirigente local
├── Congregação Nova Terra         → Dirigente local
└── Congregação Residencial        → Dirigente local
```

Cada **congregação** é um ponto de culto com autonomia operacional parcial:
- Possui seus **próprios membros** (cadastro local)
- Possui seu **próprio caixa** (dízimos, ofertas, despesas locais)
- Possui sua **própria EBD** (turmas, professores, alunos locais)
- Possui seu **próprio patrimônio** (bens físicos no local)
- Possui um **dirigente** responsável (pastor auxiliar, presbítero ou diácono)

Porém, todas fazem parte da **mesma entidade jurídica** (mesmo CNPJ) e respondem ao **pastor presidente**, que precisa de:
- Visão **consolidada** de membros, finanças, EBD e patrimônio
- Relatórios **individuais** por congregação
- Relatórios **comparativos** entre congregações
- Gestão unificada de usuários e permissões

### 1.2 Problema Atual

O sistema atual implementa **multi-tenancy por `church_id`**, onde cada `church` é um tenant completamente isolado. Não existe:
- Conceito de **congregação** como subdivisão de uma igreja
- **Hierarquia** entre igrejas (sede → congregações)
- **Relatórios consolidados** cruzando dados de múltiplas unidades
- **Troca de contexto** no app (um usuário acessando dados de várias congregações)
- **Transferência interna** de membros entre congregações

### 1.3 Decisão Arquitetural

**Abordagem escolhida: Congregações como subdivisões dentro da Church (tenant)**

Cada congregation é uma **unidade organizacional** dentro de uma `church`, não uma church separada.

**Justificativas:**
1. Congregações **não são entidades jurídicas independentes** — compartilham o mesmo CNPJ
2. Reutiliza toda a infraestrutura de multi-tenancy por `church_id` existente
3. O pastor presidente tem **visão completa natural** (é do mesmo `church_id`)
4. Transferências internas entre congregações são simples (mesmo `church_id`)
5. Relatórios consolidados são triviais (query sem filtro de `congregation_id`)
6. Escala para futuro: se a igreja abrir 10 congregações, o modelo se mantém

**Abordagem descartada: Cada congregação como uma `church` separada com `parent_church_id`**
- Criaria isolamento excessivo entre unidades que deveriam compartilhar dados
- Complicaria relatórios consolidados (precisaria fazer UNION de queries cross-tenant)
- Quebraria a regra de negócio RN-GER-001 (nenhuma query retorna dados de outra church)
- Transferências entre congregações virariam "transferências eclesiásticas" formais

---

## 2. Modelo de Dados

### 2.1 Nova Tabela: `congregations`

```sql
CREATE TABLE IF NOT EXISTS congregations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
    
    -- Identificação
    name            VARCHAR(200) NOT NULL,          -- "Sede", "Congregação Paxicá", etc.
    short_name      VARCHAR(50),                    -- "Paxicá", "Nova Terra" (para cards e menus)
    type            VARCHAR(20) NOT NULL DEFAULT 'congregacao' 
                    CHECK (type IN ('sede', 'congregacao', 'ponto_de_pregacao')),
    
    -- Líder local
    leader_id       UUID REFERENCES members(id) ON DELETE SET NULL,
    
    -- Endereço
    zip_code        VARCHAR(10),
    street          VARCHAR(200),
    number          VARCHAR(20),
    complement      VARCHAR(100),
    neighborhood    VARCHAR(100),
    city            VARCHAR(100) DEFAULT 'Tutóia',
    state           CHAR(2) DEFAULT 'MA',
    
    -- Contato
    phone           VARCHAR(20),
    email           VARCHAR(150),
    
    -- Configurações
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order      INT NOT NULL DEFAULT 0,         -- Sede primeiro, depois alfabético
    settings        JSONB DEFAULT '{}',             -- Configs específicas da congregação
    
    -- Metadados
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(church_id, name)
);

-- Índices
CREATE INDEX idx_congregations_church ON congregations(church_id);
CREATE INDEX idx_congregations_active ON congregations(church_id, is_active);
CREATE INDEX idx_congregations_leader ON congregations(leader_id) WHERE leader_id IS NOT NULL;
CREATE INDEX idx_congregations_type ON congregations(church_id, type);

-- Trigger updated_at
CREATE TRIGGER trg_congregations_updated
    BEFORE UPDATE ON congregations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### 2.2 Nova Tabela: `user_congregations` (Acesso do Usuário às Congregações)

```sql
-- Um usuário pode ter acesso a múltiplas congregações
-- Super admin e pastor-presidente acessam TODAS (sem registro aqui)
CREATE TABLE IF NOT EXISTS user_congregations (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    congregation_id     UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
    
    -- Papel na congregação
    role_in_congregation VARCHAR(30) NOT NULL DEFAULT 'viewer'
                        CHECK (role_in_congregation IN (
                            'dirigente',     -- Líder da congregação (CRUD completo local)
                            'secretario',    -- Secretário local
                            'tesoureiro',    -- Tesoureiro local
                            'professor_ebd', -- Professor EBD local
                            'viewer'         -- Apenas visualização
                        )),
    
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,  -- Congregação principal do usuário
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, congregation_id)
);

CREATE INDEX idx_user_congregations_user ON user_congregations(user_id);
CREATE INDEX idx_user_congregations_congregation ON user_congregations(congregation_id);
```

### 2.3 Alterações em Tabelas Existentes

Todas as tabelas de dados que hoje possuem `church_id` receberão uma coluna **`congregation_id`** (nullable):

```sql
-- ============================
-- MÓDULO DE MEMBROS
-- ============================

ALTER TABLE members 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_members_congregation 
    ON members(congregation_id) WHERE congregation_id IS NOT NULL;

-- ============================
-- MÓDULO FINANCEIRO
-- ============================

ALTER TABLE financial_entries 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_fin_entries_congregation 
    ON financial_entries(congregation_id) WHERE congregation_id IS NOT NULL;

ALTER TABLE bank_accounts 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_bank_accounts_congregation 
    ON bank_accounts(congregation_id) WHERE congregation_id IS NOT NULL;

ALTER TABLE campaigns 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

ALTER TABLE monthly_closings 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

ALTER TABLE account_plans
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

-- ============================
-- MÓDULO EBD
-- ============================

ALTER TABLE ebd_terms 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

ALTER TABLE ebd_classes 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_ebd_classes_congregation 
    ON ebd_classes(congregation_id) WHERE congregation_id IS NOT NULL;

-- ============================
-- MÓDULO PATRIMÔNIO
-- ============================

ALTER TABLE assets 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_assets_congregation 
    ON assets(congregation_id) WHERE congregation_id IS NOT NULL;

ALTER TABLE inventories 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

-- ============================
-- MÓDULO DE MINISTÉRIOS
-- ============================

ALTER TABLE ministries 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;
```

> **Nota:** `congregation_id` é **nullable** por design. Registros com `congregation_id = NULL` são considerados da **sede** ou de **âmbito geral da igreja**.

### 2.4 Views Consolidadas

```sql
-- Estatísticas de membros por congregação
CREATE OR REPLACE VIEW vw_congregation_member_stats AS
SELECT 
    c.id AS congregation_id,
    c.name AS congregation_name,
    c.church_id,
    COUNT(m.id) FILTER (WHERE m.status = 'ativo' AND m.deleted_at IS NULL) AS active_members,
    COUNT(m.id) FILTER (WHERE m.status = 'visitante' AND m.deleted_at IS NULL) AS visitors,
    COUNT(m.id) FILTER (WHERE m.status = 'congregado' AND m.deleted_at IS NULL) AS congregados,
    COUNT(m.id) FILTER (WHERE m.deleted_at IS NULL) AS total_members
FROM congregations c
LEFT JOIN members m ON m.congregation_id = c.id
WHERE c.is_active = TRUE
GROUP BY c.id, c.name, c.church_id;

-- Resumo financeiro por congregação
CREATE OR REPLACE VIEW vw_congregation_financial_summary AS
SELECT 
    c.id AS congregation_id,
    c.name AS congregation_name,
    c.church_id,
    COALESCE(SUM(fe.amount) FILTER (WHERE fe.type = 'receita' AND fe.status = 'confirmado'), 0) AS total_income,
    COALESCE(SUM(fe.amount) FILTER (WHERE fe.type = 'despesa' AND fe.status = 'confirmado'), 0) AS total_expense,
    COALESCE(SUM(fe.amount) FILTER (WHERE fe.type = 'receita' AND fe.status = 'confirmado'), 0) 
    - COALESCE(SUM(fe.amount) FILTER (WHERE fe.type = 'despesa' AND fe.status = 'confirmado'), 0) AS balance,
    DATE_TRUNC('month', fe.entry_date) AS reference_month
FROM congregations c
LEFT JOIN financial_entries fe ON fe.congregation_id = c.id AND fe.deleted_at IS NULL
WHERE c.is_active = TRUE
GROUP BY c.id, c.name, c.church_id, DATE_TRUNC('month', fe.entry_date);

-- Frequência EBD por congregação
CREATE OR REPLACE VIEW vw_congregation_ebd_stats AS
SELECT 
    c.id AS congregation_id,
    c.name AS congregation_name,
    c.church_id,
    COUNT(DISTINCT ec.id) AS total_classes,
    COUNT(DISTINCT ee.member_id) AS total_students,
    AVG(CASE WHEN ea.status = 'presente' THEN 1.0 ELSE 0.0 END) * 100 AS avg_attendance_pct
FROM congregations c
LEFT JOIN ebd_classes ec ON ec.congregation_id = c.id AND ec.is_active = TRUE
LEFT JOIN ebd_enrollments ee ON ee.class_id = ec.id AND ee.is_active = TRUE
LEFT JOIN ebd_lessons el ON el.class_id = ec.id
LEFT JOIN ebd_attendances ea ON ea.lesson_id = el.id
WHERE c.is_active = TRUE
GROUP BY c.id, c.name, c.church_id;
```

### 2.5 Diagrama ER (Congregações)

```
┌──────────────────┐
│    churches      │
│──────────────────│
│ id (PK)          │◄────────────────────────────────────────────┐
│ name             │                                              │
│ cnpj             │                                              │
│ pastor_name      │                                              │
│ ...              │                                              │
└──────────────────┘                                              │
         │                                                        │
         │ 1:N                                                    │
         ▼                                                        │
┌──────────────────┐         ┌─────────────────────┐             │
│  congregations   │         │ user_congregations   │             │
│──────────────────│         │─────────────────────│             │
│ id (PK)          │◄────────│ congregation_id (FK) │             │
│ church_id (FK)   │─────────┼─────────────────────│─────────────┘
│ name             │         │ user_id (FK)         │──── users
│ type (sede/cong) │         │ role_in_congregation │
│ leader_id (FK)   │──┐      │ is_primary           │
│ endereço...      │  │      └─────────────────────┘
│ is_active        │  │
└──────┬───────────┘  │
       │              │
       │ 1:N          │ (member)
       ▼              │
┌──────────────┐      │
│   members    │◄─────┘
│──────────────│
│congregation_id│ (nullable FK)
│ church_id    │
│ full_name    │
│ ...          │
└──────────────┘

Mesmo padrão para: financial_entries, ebd_classes, assets, ministries, etc.
```

---

## 3. Regras de Negócio

### RN-CONG-001: Estrutura Obrigatória
- Toda igreja (`church`) pode ter **zero ou mais** congregações.
- Se a igreja possuir congregações, **uma delas deve ser do tipo `sede`**.
- Pode existir **apenas uma** congregação do tipo `sede` por igreja.
- Congregações do tipo `ponto_de_pregacao` são pontos menores, ainda não estabelecidos como congregação formal.

### RN-CONG-002: Dirigente da Congregação
- Cada congregação pode ter **um dirigente** (leader_id → members).
- O dirigente deve ser um membro **ativo** da igreja.
- O dirigente não precisa necessariamente estar vinculado à própria congregação como membro (ex: pastor da sede que supervisiona uma congregação).
- A mudança de dirigente deve gerar evento de auditoria.

### RN-CONG-003: Membros e Congregações
- Um membro pertence a **uma congregação** (ou nenhuma — nesse caso, é da sede por padrão).
- `congregation_id = NULL` nos registros antigos é interpretado como **Sede** ou **Igreja Geral**.
- Transferência interna (entre congregações da mesma igreja) **não** gera carta de transferência — é apenas uma mudança de `congregation_id` com registro no histórico.
- Transferência interna gera evento em `member_history` com `event_type = 'transferencia_interna'`.

### RN-CONG-004: Finanças por Congregação
- Cada congregação pode ter suas **próprias contas bancárias/caixas**.
- Lançamentos financeiros (receitas e despesas) podem ser vinculados a uma congregação.
- Lançamentos com `congregation_id = NULL` são de **âmbito geral** da igreja (sede/administração).
- O **fechamento mensal** pode ser feito por congregação OU consolidado (geral).
- O tesoureiro da congregação só vê/edita lançamentos da sua congregação.
- O tesoureiro geral (ou pastor) vê/edita lançamentos de **todas** as congregações.

### RN-CONG-005: EBD por Congregação
- Turmas e trimestres da EBD podem ser vinculados a uma congregação.
- Uma turma pertence a **uma** congregação.
- O professor só vê turmas da sua congregação (a menos que tenha acesso geral).
- Relatórios consolidados da EBD mostram todas as congregações em uma mesma visão.

### RN-CONG-006: Patrimônio por Congregação
- Bens patrimoniais estão **fisicamente localizados** em uma congregação.
- Inventários podem ser feitos por congregação individualmente.
- Um bem pode ser **transferido** entre congregações (mudança de `congregation_id` com registro).

### RN-CONG-007: Permissões e Acesso
- **Pastor/Super Admin/Admin**: acesso a **todas** as congregações. Não precisa de registro em `user_congregations`.
- **Dirigente**: acesso completo aos dados da **sua** congregação. Definido via `user_congregations.role_in_congregation = 'dirigente'`.
- **Secretário/Tesoureiro/Professor local**: acesso apenas à sua congregação, no escopo do seu papel.
- Um usuário pode ter **acesso a múltiplas congregações** (ex: tesoureiro que cuida de 2 congregações).
- A **congregação primária** (`is_primary = true`) define o contexto padrão do usuário ao fazer login.

### RN-CONG-008: Relatórios Consolidados
- Todo relatório existente ganha um **filtro de congregação** (dropdown/selector).
- Opções do filtro:
  - **"Todas as congregações"** (consolidado — padrão para pastor)
  - **Sede**
  - **Congregação X**
  - **Congregação Y**
- O filtro "Todas" soma os dados de todas as congregações + registros sem congregação.
- Relatórios comparativos entre congregações são uma **nova funcionalidade** (ver seção 5.4).

### RN-CONG-009: Contexto Ativo
- O frontend mantém um **contexto de congregação ativo** (similar a um "workspace selector").
- Ao fazer login, o contexto padrão é:
  - Para pastor/admin: "Todas as congregações"
  - Para dirigente: sua congregação principal
  - Para demais: sua congregação primária
- O usuário pode **trocar o contexto** através de um seletor na barra superior.
- A troca de contexto **não requer novo login** — apenas filtra os dados exibidos.

### RN-CONG-010: Migração de Dados Existentes
- Dados existentes (com `congregation_id = NULL`) continuam funcionando normalmente.
- A criação de congregações é **opcional** — o sistema funciona sem nenhuma congregação cadastrada.
- Quando as congregações forem criadas, os dados podem ser **associados** retroativamente por um admin.
- Um endpoint/ferramenta de **migração em lote** permite associar membros a congregações em massa.

---

## 4. API REST

### 4.1 Endpoints de Congregações (`/congregations`)

#### `GET /api/v1/congregations`
Listar congregações da igreja.

**Permissão:** Autenticado (qualquer role)

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `is_active` | boolean | Filtrar por status ativo |
| `type` | string | Filtrar por tipo (`sede`, `congregacao`, `ponto_de_pregacao`) |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-sede",
      "name": "Sede — Templo Central",
      "short_name": "Sede",
      "type": "sede",
      "leader": {
        "id": "uuid-pastor",
        "full_name": "Pr. João da Silva"
      },
      "address": {
        "street": "Rua Principal",
        "number": "100",
        "neighborhood": "Centro",
        "city": "Tutóia",
        "state": "MA"
      },
      "phone": "(98) 99999-0001",
      "stats": {
        "active_members": 120,
        "total_members": 145
      },
      "is_active": true,
      "sort_order": 0
    },
    {
      "id": "uuid-paxica",
      "name": "Congregação Paxicá",
      "short_name": "Paxicá",
      "type": "congregacao",
      "leader": {
        "id": "uuid-dirigente1",
        "full_name": "Pb. Carlos Lima"
      },
      "address": {
        "neighborhood": "Paxicá",
        "city": "Tutóia",
        "state": "MA"
      },
      "stats": {
        "active_members": 35,
        "total_members": 42
      },
      "is_active": true,
      "sort_order": 1
    }
  ]
}
```

---

#### `GET /api/v1/congregations/{id}`
Obter detalhes de uma congregação.

**Permissão:** `congregations:read` ou acesso à congregação

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid-paxica",
    "church_id": "uuid-church",
    "name": "Congregação Paxicá",
    "short_name": "Paxicá",
    "type": "congregacao",
    "leader": {
      "id": "uuid-dirigente1",
      "full_name": "Pb. Carlos Lima",
      "phone_primary": "(98) 99999-1234",
      "role_position": "presbitero"
    },
    "address": {
      "zip_code": "65580-000",
      "street": "Rua da Congregação",
      "number": "50",
      "neighborhood": "Paxicá",
      "city": "Tutóia",
      "state": "MA"
    },
    "phone": "(98) 99999-0002",
    "email": null,
    "stats": {
      "active_members": 35,
      "total_members": 42,
      "monthly_income": 2500.00,
      "monthly_expense": 1800.00,
      "ebd_classes": 3,
      "ebd_students": 28
    },
    "is_active": true,
    "sort_order": 1,
    "created_at": "2026-02-20T10:00:00Z",
    "updated_at": "2026-02-20T10:00:00Z"
  }
}
```

---

#### `POST /api/v1/congregations`
Criar nova congregação.

**Permissão:** `settings:write` (admin/pastor)

**Request:**
```json
{
  "name": "Congregação Nova Terra",
  "short_name": "Nova Terra",
  "type": "congregacao",
  "leader_id": "uuid-membro-dirigente",
  "zip_code": "65580-000",
  "street": "Rua Nova Terra",
  "number": "25",
  "neighborhood": "Nova Terra",
  "city": "Tutóia",
  "state": "MA",
  "phone": "(98) 99999-0003"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": { "id": "uuid-new", "...": "..." },
  "message": "Congregação criada com sucesso"
}
```

---

#### `PUT /api/v1/congregations/{id}`
Atualizar congregação.

**Permissão:** `settings:write` ou `dirigente` da congregação

**Request:** (mesmos campos do POST, todos opcionais)

---

#### `DELETE /api/v1/congregations/{id}`
Desativar congregação (soft delete via `is_active = false`).

**Permissão:** `settings:write` (admin/pastor)

**Regras:**
- Não exclui fisicamente — apenas desativa
- Membros vinculados ficam com `congregation_id` mantido (podem ser revinculados depois)
- Lançamentos financeiros são mantidos para histórico
- A sede **não pode** ser desativada se houver outras congregações ativas

---

#### `GET /api/v1/congregations/{id}/stats`
Dashboard resumido da congregação.

**Permissão:** Acesso à congregação

**Response (200):**
```json
{
  "success": true,
  "data": {
    "members": {
      "total": 42,
      "active": 35,
      "visitors": 5,
      "congregados": 2,
      "new_this_month": 3
    },
    "financial": {
      "income_this_month": 2500.00,
      "expense_this_month": 1800.00,
      "balance": 700.00,
      "top_income_category": "Dízimos",
      "top_expense_category": "Aluguel"
    },
    "ebd": {
      "classes": 3,
      "enrolled_students": 28,
      "avg_attendance_pct": 72.5,
      "last_sunday_attendance": 22
    },
    "assets": {
      "total_assets": 15,
      "total_value": 12500.00
    }
  }
}
```

---

### 4.2 Endpoint de Troca de Contexto

#### `POST /api/v1/user/active-congregation`
Definir a congregação ativa para o usuário no frontend.

**Permissão:** Autenticado

**Request:**
```json
{
  "congregation_id": "uuid-paxica"
}
```
> Enviar `"congregation_id": null` para selecionar "Todas as congregações" (visão geral).

**Response (200):**
```json
{
  "success": true,
  "data": {
    "active_congregation_id": "uuid-paxica",
    "active_congregation_name": "Congregação Paxicá"
  },
  "message": "Contexto alterado para Congregação Paxicá"
}
```

**Validação:**
- O usuário deve ter acesso à congregação (via `user_congregations` ou ser admin/pastor)
- A preferência é salva no backend (tabela `users` — novo campo `active_congregation_id`) e/ou no frontend (local storage)

---

### 4.3 Endpoints de Associação de Usuário a Congregação

#### `GET /api/v1/congregations/{id}/users`
Listar usuários com acesso à congregação.

**Permissão:** `settings:read` ou `dirigente` da congregação

---

#### `POST /api/v1/congregations/{id}/users`
Conceder acesso de um usuário à congregação.

**Permissão:** `settings:write`

**Request:**
```json
{
  "user_id": "uuid-user",
  "role_in_congregation": "tesoureiro",
  "is_primary": false
}
```

---

#### `DELETE /api/v1/congregations/{id}/users/{user_id}`
Remover acesso do usuário à congregação.

**Permissão:** `settings:write`

---

### 4.4 Endpoint de Migração em Lote

#### `POST /api/v1/congregations/{id}/assign-members`
Associar membros a uma congregação em lote.

**Permissão:** `settings:write` (admin/pastor)

**Request:**
```json
{
  "member_ids": ["uuid-1", "uuid-2", "uuid-3", "uuid-4"],
  "overwrite": false
}
```

| Campo | Descrição |
|-------|-----------|
| `member_ids` | Lista de IDs de membros para associar à congregação |
| `overwrite` | Se `true`, sobrescreve `congregation_id` mesmo de membros já associados a outra congregação. Se `false`, pula membros já associados. |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "assigned": 3,
    "skipped": 1,
    "skipped_members": [
      { "id": "uuid-4", "full_name": "José Lima", "current_congregation": "Paxicá" }
    ]
  },
  "message": "3 membros associados à Congregação Nova Terra"
}
```

---

### 4.5 Modificações em Endpoints Existentes

Todos os endpoints existentes de **listagem** ganham um query parameter opcional:

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `congregation_id` | UUID (opcional) | Filtrar por congregação. Se omitido, retorna dados de todas. |

**Endpoints afetados:**

| Módulo | Endpoint | Comportamento |
|--------|----------|---------------|
| Membros | `GET /members` | Filtra por `congregation_id` se informado |
| Financeiro | `GET /financial/entries` | Filtra por `congregation_id` se informado |
| Financeiro | `GET /financial/bank-accounts` | Filtra por `congregation_id` se informado |
| Financeiro | `GET /financial/campaigns` | Filtra por `congregation_id` se informado |
| EBD | `GET /ebd/terms` | Filtra por `congregation_id` se informado |
| EBD | `GET /ebd/classes` | Filtra por `congregation_id` se informado |
| Patrimônio | `GET /assets` | Filtra por `congregation_id` se informado |
| Patrimônio | `GET /assets/inventories` | Filtra por `congregation_id` se informado |
| Ministérios | `GET /ministries` | Filtra por `congregation_id` se informado |
| Dashboard | `GET /dashboard/stats` | Filtra por `congregation_id` se informado |
| Relatórios | Todos os endpoints de relatório | Filtra por `congregation_id` se informado |

**Endpoints de criação:** Os endpoints de `POST` passam a aceitar o campo `congregation_id` no body.

```json
// Exemplo: criando um membro já vinculado à congregação
POST /api/v1/members
{
  "full_name": "Maria da Silva",
  "congregation_id": "uuid-paxica",
  "...": "..."
}
```

---

### 4.6 Novos Endpoints de Relatórios Consolidados

#### `GET /api/v1/reports/congregations/overview`
Visão geral de todas as congregações (para o pastor).

**Permissão:** `reports:*` ou admin/pastor

**Response (200):**
```json
{
  "success": true,
  "data": {
    "total_congregations": 4,
    "total_members_all": 250,
    "total_income_month": 15000.00,
    "total_expense_month": 11000.00,
    "congregations": [
      {
        "id": "uuid-sede",
        "name": "Sede",
        "type": "sede",
        "active_members": 120,
        "income_month": 8500.00,
        "expense_month": 6000.00,
        "ebd_attendance_pct": 78.2
      },
      {
        "id": "uuid-paxica",
        "name": "Paxicá",
        "type": "congregacao",
        "active_members": 35,
        "income_month": 2500.00,
        "expense_month": 1800.00,
        "ebd_attendance_pct": 72.5
      },
      {
        "id": "uuid-nova-terra",
        "name": "Nova Terra",
        "type": "congregacao",
        "active_members": 55,
        "income_month": 2800.00,
        "expense_month": 2200.00,
        "ebd_attendance_pct": 68.0
      },
      {
        "id": "uuid-residencial",
        "name": "Residencial",
        "type": "congregacao",
        "active_members": 40,
        "income_month": 1200.00,
        "expense_month": 1000.00,
        "ebd_attendance_pct": 65.3
      }
    ]
  }
}
```

---

#### `GET /api/v1/reports/congregations/compare`
Comparativo entre congregações.

**Permissão:** `reports:*` ou admin/pastor

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `metric` | string | `members`, `financial`, `ebd`, `assets` |
| `period_start` | date | Início do período |
| `period_end` | date | Fim do período |
| `congregation_ids` | UUID[] | IDs para comparar (se vazio, compara todas) |

**Response (200):** (exemplo para metric=financial)
```json
{
  "success": true,
  "data": {
    "metric": "financial",
    "period": { "start": "2026-01-01", "end": "2026-02-28" },
    "congregations": [
      {
        "id": "uuid-sede",
        "name": "Sede",
        "values": {
          "total_income": 17000.00,
          "total_expense": 12000.00,
          "tithes": 12000.00,
          "offerings": 3500.00,
          "balance": 5000.00
        }
      },
      {
        "id": "uuid-paxica",
        "name": "Paxicá",
        "values": {
          "total_income": 5000.00,
          "total_expense": 3600.00,
          "tithes": 3200.00,
          "offerings": 1200.00,
          "balance": 1400.00
        }
      }
    ],
    "totals": {
      "total_income": 22000.00,
      "total_expense": 15600.00,
      "tithes": 15200.00,
      "offerings": 4700.00,
      "balance": 6400.00
    }
  }
}
```

---

## 5. Frontend

### 5.1 Nova Feature: `congregations`

```
frontend/lib/features/congregations/
├── data/
│   ├── models/
│   │   └── congregation_model.dart
│   └── repositories/
│       └── congregation_repository.dart
├── domain/
│   └── entities/
│       └── congregation.dart
└── presentation/
    ├── bloc/
    │   ├── congregation_bloc.dart
    │   ├── congregation_event.dart
    │   └── congregation_state.dart
    ├── pages/
    │   ├── congregations_list_page.dart
    │   ├── congregation_detail_page.dart
    │   ├── congregation_form_page.dart
    │   └── congregation_assign_members_page.dart
    └── widgets/
        ├── congregation_card.dart
        ├── congregation_selector.dart       ← Dropdown/seletor global
        ├── congregation_stats_card.dart
        └── congregation_compare_chart.dart
```

### 5.2 Congregation Selector (Componente Global)

O componente mais importante do módulo. Um **seletor de congregação** persistente na barra superior (AppBar) ou no drawer, visível em todas as telas.

#### UX Design

```
┌─────────────────────────────────────────────────────────┐
│  ☰  Igreja Manager          [🏛️ Paxicá ▾]    🔔  👤   │
│─────────────────────────────────────────────────────────│
│                                                         │
│  (conteúdo filtrado pela congregação selecionada)       │
│                                                         │
└─────────────────────────────────────────────────────────┘

Ao clicar no seletor:
┌───────────────────────────┐
│  Selecionar Congregação   │
│───────────────────────────│
│  🌐 Todas (Geral)        │  ← visível só para admin/pastor
│  🏛️ Sede                 │
│  ⛪ Paxicá                │
│  ⛪ Nova Terra             │
│  ⛪ Residencial            │
└───────────────────────────┘
```

#### Comportamento:
1. O seletor aparece **em todas as telas** (exceto login e configurações gerais)
2. Ao trocar a congregação, todas as listas/dashboards são **recarregados** com o novo filtro
3. A seleção é **persistida** em local storage (sobrevive a refresh)
4. Para **admin/pastor**: opção "Todas (Geral)" mostra dados consolidados
5. Para **dirigente**: mostra apenas a(s) congregação(ões) que ele tem acesso
6. Se a igreja **não tiver** congregações cadastradas, o seletor **não aparece**

#### Implementação (State Management):

```dart
// congregation_context_cubit.dart (global, injected via BlocProvider no MaterialApp)

class CongregationContextState {
  final List<Congregation> availableCongregations;
  final Congregation? activeCongregation;  // null = "Todas"
  final bool isLoading;
  
  bool get isAllSelected => activeCongregation == null;
  String get activeLabel => activeCongregation?.shortName ?? 'Geral';
}

class CongregationContextCubit extends Cubit<CongregationContextState> {
  // Carrega as congregações no startup (POST login)
  Future<void> loadCongregations();
  
  // Troca a congregação ativa
  Future<void> selectCongregation(Congregation? congregation);
  
  // Retorna o congregation_id ativo (null = todas)
  Uuid? get activeCongregationId;
}
```

#### Integração com BLoCs Existentes:

Todos os BLoCs de listagem (MembersBloc, FinancialBloc, EbdBloc, etc.) precisam:
1. **Escutar** mudanças no `CongregationContextCubit`
2. **Recarregar** os dados quando a congregação ativa mudar
3. **Enviar** o `congregation_id` como parâmetro nas requests à API

```dart
// Exemplo: members_bloc.dart (modificação)
class MembersBloc extends Bloc<MembersEvent, MembersState> {
  final CongregationContextCubit _congregationContext;
  
  // Ao carregar membros, inclui o filtro de congregação
  Future<void> _onLoadMembers(LoadMembers event, Emitter emit) async {
    final congregationId = _congregationContext.activeCongregationId;
    final members = await repository.getMembers(
      congregationId: congregationId,  // ← NOVO
      page: event.page,
      search: event.search,
    );
    // ...
  }
}
```

### 5.3 Telas do Módulo

#### 5.3.1 Lista de Congregações (`congregations_list_page.dart`)

Acessível via **Configurações > Congregações** ou pelo menu lateral.

```
┌─────────────────────────────────────────────────────┐
│  ←  Congregações                            [+ Nova] │
│─────────────────────────────────────────────────────│
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🏛️ Sede — Templo Central                      │ │
│  │ Pr. João da Silva                              │ │
│  │ Centro, Tutóia-MA                              │ │
│  │ 120 membros ativos │ R$ 8.500 receita/mês      │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ ⛪ Congregação Paxicá                          │ │
│  │ Pb. Carlos Lima (Dirigente)                    │ │
│  │ Paxicá, Tutóia-MA                             │ │
│  │ 35 membros ativos │ R$ 2.500 receita/mês       │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ ⛪ Congregação Nova Terra                      │ │
│  │ Dc. Pedro Santos (Dirigente)                   │ │
│  │ Nova Terra, Tutóia-MA                          │ │
│  │ 55 membros ativos │ R$ 2.800 receita/mês       │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ ⛪ Congregação Residencial                     │ │
│  │ Dc. Ana Oliveira (Dirigente)                   │ │
│  │ Residencial, Tutóia-MA                         │ │
│  │ 40 membros ativos │ R$ 1.200 receita/mês       │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
└─────────────────────────────────────────────────────┘
```

#### 5.3.2 Detalhe da Congregação (`congregation_detail_page.dart`)

```
┌─────────────────────────────────────────────────────┐
│  ←  Congregação Paxicá                        [✏️]  │
│─────────────────────────────────────────────────────│
│                                                      │
│  Dirigente: Pb. Carlos Lima                         │
│  Endereço: Rua da Congregação, 50 — Paxicá         │
│  Telefone: (98) 99999-0002                          │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │ 👥 35    │ │ 💰 2.5k  │ │ 📖 72%   │ │ 🏠 15  │ │
│  │ Membros  │ │ Receita  │ │ Freq.EBD │ │ Bens   │ │
│  │ ativos   │ │ mês      │ │ média    │ │        │ │
│  └──────────┘ └──────────┘ └──────────┘ └────────┘ │
│                                                      │
│  [Tabs: Membros | Financeiro | EBD | Patrimônio]    │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ Lista de membros desta congregação...          │ │
│  │ (com opção de ver completo)                    │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  [Associar membros em lote]                         │
│                                                      │
└─────────────────────────────────────────────────────┘
```

#### 5.3.3 Tela de Comparativo entre Congregações

Acessível via **Relatórios > Comparativo de Congregações** ou no detalhe do Dashboard quando "Todas" estiver selecionado.

```
┌─────────────────────────────────────────────────────┐
│  ←  Comparativo de Congregações                     │
│─────────────────────────────────────────────────────│
│  Período: [Jan/2026 ▾] a [Fev/2026 ▾]             │
│                                                      │
│  [Tabs: Membros | Financeiro | EBD]                 │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │         Receitas por Congregação (Bar Chart)   │ │
│  │                                                │ │
│  │  Sede      ████████████████████  R$ 17.000     │ │
│  │  Paxicá    ██████████           R$ 5.000      │ │
│  │  N. Terra  ███████████          R$ 5.600      │ │
│  │  Residenc. █████                R$ 2.400      │ │
│  │                                                │ │
│  │  Total geral: R$ 30.000                       │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │  Tabela Detalhada                              │ │
│  │──────────────────────────────────────────────── │ │
│  │  Congregação  │ Receita  │ Despesa │ Saldo     │ │
│  │  Sede         │ 17.000   │ 12.000  │ 5.000     │ │
│  │  Paxicá       │  5.000   │  3.600  │ 1.400     │ │
│  │  Nova Terra   │  5.600   │  4.400  │ 1.200     │ │
│  │  Residencial  │  2.400   │  2.000  │   400     │ │
│  │  ──────────── │ ──────── │ ─────── │ ──────    │ │
│  │  TOTAL        │ 30.000   │ 22.000  │ 8.000     │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### 5.4 Modificações no Dashboard

O dashboard passa a ter uma **seção de visão geral por congregação** quando a opção "Todas (Geral)" estiver selecionada:

```
┌─────────────────────────────────────────────────────┐
│  ☰  Dashboard          [🌐 Geral ▾]    🔔  👤     │
│─────────────────────────────────────────────────────│
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │ 👥 250   │ │ 💰 30k   │ │ 📖 71%   │ │ 🏠 85  │ │
│  │ Membros  │ │ Receita  │ │ Freq.EBD │ │ Bens   │ │
│  │ TOTAL    │ │ total/mês│ │ geral    │ │ total  │ │
│  └──────────┘ └──────────┘ └──────────┘ └────────┘ │
│                                                      │
│  📊 Resumo por Congregação                          │
│  ┌────────────────────────────────────────────────┐ │
│  │ Sede         │ 120 👥 │ R$8.5k 💰 │ 78% 📖   │ │
│  │ Paxicá       │  35 👥 │ R$2.5k 💰 │ 72% 📖   │ │
│  │ Nova Terra   │  55 👥 │ R$2.8k 💰 │ 68% 📖   │ │
│  │ Residencial  │  40 👥 │ R$1.2k 💰 │ 65% 📖   │ │
│  └────────────────────────────────────────────────┘ │
│                (toque para ver detalhe)              │
│                                                      │
│  📅 Aniversariantes da Semana (todas as congreg.)  │
│  ┌────────────────────────────────────────────────┐ │
│  │ • Maria Silva (Sede) — 22/02                   │ │
│  │ • João Lima (Paxicá) — 24/02                   │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## 6. Backend — Arquitetura

### 6.1 Novas Entidades

```rust
// backend/src/domain/entities/congregation.rs

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Congregation {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    pub short_name: Option<String>,
    pub congregation_type: String,  // "sede", "congregacao", "ponto_de_pregacao"
    pub leader_id: Option<Uuid>,
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub is_active: bool,
    pub sort_order: i32,
    pub settings: serde_json::Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CongregationDetail {
    pub congregation: Congregation,
    pub leader: Option<MemberSummary>,
    pub stats: CongregationStats,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CongregationStats {
    pub active_members: i64,
    pub total_members: i64,
    pub income_this_month: Decimal,
    pub expense_this_month: Decimal,
    pub ebd_classes: i64,
    pub ebd_students: i64,
    pub ebd_avg_attendance_pct: f64,
    pub total_assets: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserCongregation {
    pub id: Uuid,
    pub user_id: Uuid,
    pub congregation_id: Uuid,
    pub role_in_congregation: String,
    pub is_primary: bool,
    pub created_at: DateTime<Utc>,
}
```

### 6.2 Novos DTOs

```rust
// backend/src/application/dto/congregation_dto.rs

#[derive(Debug, Deserialize, Validate)]
pub struct CreateCongregationRequest {
    #[validate(length(min = 2, max = 200))]
    pub name: String,
    #[validate(length(max = 50))]
    pub short_name: Option<String>,
    pub congregation_type: Option<String>,  // default: "congregacao"
    pub leader_id: Option<Uuid>,
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateCongregationRequest {
    #[validate(length(min = 2, max = 200))]
    pub name: Option<String>,
    pub short_name: Option<String>,
    pub congregation_type: Option<String>,
    pub leader_id: Option<Uuid>,
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub is_active: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AssignMembersRequest {
    pub member_ids: Vec<Uuid>,
    #[serde(default)]
    pub overwrite: bool,
}

#[derive(Debug, Deserialize)]
pub struct AddUserToCongregationRequest {
    pub user_id: Uuid,
    pub role_in_congregation: String,
    #[serde(default)]
    pub is_primary: bool,
}
```

### 6.3 Novo Service

```rust
// backend/src/application/services/congregation_service.rs

impl CongregationService {
    pub async fn list_congregations(pool, church_id, filters) -> Result<Vec<CongregationWithStats>>;
    pub async fn get_congregation(pool, church_id, id) -> Result<CongregationDetail>;
    pub async fn create_congregation(pool, church_id, dto) -> Result<Congregation>;
    pub async fn update_congregation(pool, church_id, id, dto) -> Result<Congregation>;
    pub async fn deactivate_congregation(pool, church_id, id) -> Result<()>;
    pub async fn get_congregation_stats(pool, church_id, id) -> Result<CongregationStats>;
    
    // Gestão de usuários
    pub async fn list_congregation_users(pool, church_id, id) -> Result<Vec<UserCongregation>>;
    pub async fn add_user_to_congregation(pool, church_id, id, dto) -> Result<UserCongregation>;
    pub async fn remove_user_from_congregation(pool, church_id, cong_id, user_id) -> Result<()>;
    
    // Migração de membros
    pub async fn assign_members(pool, church_id, id, dto) -> Result<AssignResult>;
    
    // Relatórios
    pub async fn get_overview(pool, church_id) -> Result<CongregationsOverview>;
    pub async fn get_comparison(pool, church_id, filters) -> Result<CongregationsComparison>;
}
```

### 6.4 Novo Handler

```rust
// backend/src/api/handlers/congregation_handler.rs

// Rotas:
// GET    /api/v1/congregations                          → list_congregations
// GET    /api/v1/congregations/{id}                     → get_congregation
// POST   /api/v1/congregations                          → create_congregation
// PUT    /api/v1/congregations/{id}                     → update_congregation
// DELETE /api/v1/congregations/{id}                     → deactivate_congregation
// GET    /api/v1/congregations/{id}/stats               → get_congregation_stats
// GET    /api/v1/congregations/{id}/users               → list_congregation_users
// POST   /api/v1/congregations/{id}/users               → add_user_to_congregation
// DELETE /api/v1/congregations/{id}/users/{user_id}     → remove_user_from_congregation
// POST   /api/v1/congregations/{id}/assign-members      → assign_members_batch
// POST   /api/v1/user/active-congregation               → set_active_congregation
// GET    /api/v1/reports/congregations/overview          → congregations_overview_report
// GET    /api/v1/reports/congregations/compare           → congregations_comparison_report
```

### 6.5 Middleware de Congregação

```rust
// Novo middleware ou extensão do existente em middleware.rs

/// Extrai o congregation_id do query parameter ou header e valida o acesso do usuário.
/// 
/// Fluxo:
/// 1. Verifica se há `congregation_id` no query string
/// 2. Se houver, valida que o usuário tem acesso (via user_congregations ou é admin)
/// 3. Se não houver, retorna None (todas as congregações / sem filtro)
///
/// Admin/Pastor/Super Admin: sempre têm acesso a todas
/// Outros: verificar em user_congregations
pub fn get_congregation_filter(claims: &Claims, query: &Query) -> Result<Option<Uuid>>;

/// Verifica se o usuário pode ESCREVER na congregação especificada
pub fn require_congregation_access(claims: &Claims, congregation_id: Uuid, pool: &PgPool) -> Result<()>;
```

---

## 7. Plano de Implementação

### Fase 1: Infraestrutura (Banco + Backend Base) — ✅ CONCLUÍDO
**Estimativa: 3-4 dias → Concluído em 1 sessão**

| # | Tarefa | Status |
|---|--------|:------:|
| 1.1 | Criar migration `20260220100000_congregations.sql` com tabela `congregations` e `user_congregations` | ✅ |
| 1.2 | Criar migration para adicionar `congregation_id` em tabelas existentes (members, financial_entries, etc.) | ✅ (na mesma migration) |
| 1.3 | Criar entity `congregation.rs` e `user_congregation.rs` | ✅ (9 structs) |
| 1.4 | Criar DTOs em `congregation_dto.rs` | ✅ (5 DTOs) |
| 1.5 | Criar `congregation_service.rs` com CRUD básico | ✅ (~700 linhas, 16 métodos incl. compare) |
| 1.6 | Criar `congregation_handler.rs` com CRUD endpoints | ✅ (~490 linhas, 13 handlers) |
| 1.7 | Registrar rotas no `main.rs` | ✅ |
| 1.8 | Criar views SQL consolidadas | ✅ (2 views) |

### Fase 2: Integração com Módulos Existentes (Backend) — � PARCIALMENTE CONCLUÍDO
**Nota:** A infraestrutura (tabelas, coluna `congregation_id` nas tabelas existentes, views) foi criada. Integração de filtros nos módulos de Membros concluída. Outros módulos (Financial, EBD, Assets, Ministries) ficam pendentes.

| # | Tarefa | Status |
|---|--------|:------:|
| 2.1 | Modificar `member_handler.rs` — aceitar filtro `congregation_id` | ✅ Concluído |
| 2.2 | Modificar `financial_handler.rs` — aceitar filtro `congregation_id` | 🟡 Pendente |
| 2.3 | Modificar `ebd_handler.rs` — aceitar filtro `congregation_id` | 🟡 Pendente |
| 2.4 | Modificar `asset_handler.rs` — aceitar filtro `congregation_id` | 🟡 Pendente |
| 2.5 | Modificar `ministry_handler.rs` — aceitar filtro `congregation_id` | 🟡 Pendente |
| 2.6 | Modificar `member_service.rs` — incluir `congregation_id` no create/update | ✅ Concluído |
| 2.7 | Modificar services financeiros — incluir `congregation_id` | 🟡 Pendente |
| 2.8 | Modificar services EBD — incluir `congregation_id` | 🟡 Pendente |
| 2.9 | Implementar middleware de filtro de congregação | 🟡 Pendente |
| 2.10 | Endpoint de migração em lote (assign-members) | ✅ Implementado em `congregation_handler` |
| 2.11 | Endpoints de relatórios consolidados (overview + compare) | ✅ Ambos implementados (overview + compare com 4 métricas) |
| 2.12 | Integrar AuditService nos novos endpoints | ✅ Concluído |
| 2.13 | Invalidar caches relevantes ao mudar congregação | ✅ Concluído |

### Fase 3: Frontend — Módulo de Congregações — ✅ CONCLUÍDO
**Estimativa: 3-4 dias → Concluído em 1 sessão**

| # | Tarefa | Status |
|---|--------|:------:|
| 3.1 | Criar model `congregation_model.dart` | ✅ (346 linhas, 5 models) |
| 3.2 | Criar `congregation_repository.dart` | ✅ (12 métodos) |
| 3.3 | Criar `CongregationContextCubit` (gerenciamento global de contexto) | ✅ |
| 3.4 | Criar `congregation_selector.dart` (widget global) | ✅ (198 linhas) |
| 3.5 | Integrar seletor no AppBar / Shell do app | ✅ (Context Cubit em main.dart) |
| 3.6 | Criar `CongregationBloc` (CRUD) | ✅ (5 events, 7 states) |
| 3.7 | Criar tela de lista de congregações | ✅ (405 linhas, filter chips) |
| 3.8 | Criar tela de detalhe da congregação | 🟡 |
| 3.9 | Criar formulário de criação/edição | 🟡 |
| 3.10 | Criar tela de associação de membros em lote | 🟡 |

### Fase 4: Frontend — Integração com Módulos Existentes
| 3.7 | Criar tela de lista de congregações | ✅ (405 linhas, filter chips) |
| 3.8 | Criar tela de detalhe da congregação | ✅ (stats + info + endereço + usuários) |
| 3.9 | Criar formulário de criação/edição | ✅ (829 linhas, 3 seções, responsivo) |
| 3.10 | Criar tela de associação de membros em lote | ✅ (busca + seleção + overwrite) |

### Fase 4: Frontend — Integração com Módulos Existentes — � PARCIALMENTE CONCLUÍDO
**Nota:** O `CongregationContextCubit` foi integrado globalmente. MemberBloc, MemberRepository e Dashboard agora filtram por congregação. Selector está no AppShell (sidebar + AppBar mobile). Outros módulos ficam pendentes.

| # | Tarefa | Status |
|---|--------|:------:|
| 4.1 | Modificar `MembersBloc` para escutar `CongregationContextCubit` | ✅ Concluído |
| 4.2 | Modificar `FinancialBloc` para filtro por congregação | 🟡 Pendente |
| 4.3 | Modificar `EbdBloc` para filtro por congregação | 🟡 Pendente |
| 4.4 | Modificar `AssetsBloc` para filtro por congregação | 🟡 Pendente |
| 4.5 | Modificar `MinistriesBloc` para filtro por congregação | 🟡 Pendente |
| 4.6 | Modificar Dashboard para exibir resumo por congregação | ✅ Concluído (stats filtrado) |
| 4.7 | Adicionar campo `congregation_id` nos formulários de criação | ✅ Concluído (Member model + toCreateJson) |
| 4.8 | Criar tela de comparativo entre congregações | ✅ Concluído (congregation_report_page.dart — 2 abas: Overview + Comparativo) |
| 4.9 | Integrar relatórios consolidados na tela de Relatórios | 🟡 Pendente |
| 4.10 | Adicionar rota no `go_router` para as novas telas | ✅ (5 rotas settings + 7 rotas top-level + reports) |
| 4.11 | Integrar `CongregationSelector` no AppShell (sidebar + mobile) | ✅ Concluído |
| 4.12 | Adicionar nav item "Congregações" no sidebar e "Mais" | ✅ Concluído |

### Fase 5: Polimento e Testes — 🟡 PARCIAL

| # | Tarefa | Status |
|---|--------|:------:|
| 5.1 | Testar fluxo completo: criar congregação → associar membros → visualizar | 🟡 Pendente |
| 5.2 | Testar troca de contexto no seletor global | 🟡 Pendente |
| 5.3 | Testar permissões (dirigente vê só sua congregação) | 🟡 Pendente |
| 5.4 | Testar relatórios consolidados e comparativos | 🟡 Pendente |
| 5.5 | Testar migração de dados existentes (congregation_id NULL) | 🟡 Pendente |
| 5.6 | Atualizar Swagger UI com novos endpoints | ✅ (utoipa annotations em todos os 13 handlers) |
| 5.7 | Cache invalidation nos novos fluxos | 🟡 Pendente |
| 5.8 | Atualizar documentação (API REST, regras de negócio) | ✅ Concluído |

---

## 8. Migração de Dados Existentes

### 8.1 Estratégia: Retrocompatível

A implementação é 100% **backwards-compatible**:

1. **Sem congregações cadastradas**: o sistema funciona exatamente como hoje. O seletor não aparece. Todos os dados têm `congregation_id = NULL`.

2. **Ao criar a primeira congregação (Sede)**: todos os dados existentes com `congregation_id = NULL` são considerados da Sede por convenção, mas **não são migrados automaticamente** — o admin pode associar em lote.

3. **Fluxo de migração recomendado para a igreja de Tutóia:**

```
Passo 1: Criar as congregações
  → Sede — Templo Central
  → Congregação Paxicá
  → Congregação Nova Terra
  → Congregação Residencial

Passo 2: Associar os dirigentes
  → Definir leader_id para cada congregação

Passo 3: Associar membros em lote
  → Usar a tela de "Associar membros" para vincular cada membro à sua congregação
  → Membros já existentes sem congregação continuam funcionando

Passo 4: Criar contas bancárias por congregação (se aplicável)
  → Cada congregação pode ter seu próprio caixa

Passo 5: Associar turmas da EBD às congregações
  → Ao criar novas turmas, selecionar a congregação
  → Turmas existentes podem ser associadas retroativamente

Passo 6: Definir acessos dos usuários
  → Criar login para cada dirigente com acesso à sua congregação
```

### 8.2 Script de Seed para Tutóia

```sql
-- Executar após criar a migration

-- Obter o church_id da igreja de Tutóia
-- (ajustar conforme o ID real)
DO $$
DECLARE
    v_church_id UUID;
BEGIN
    SELECT id INTO v_church_id FROM churches WHERE name LIKE '%Tutóia%' LIMIT 1;
    
    IF v_church_id IS NOT NULL THEN
        INSERT INTO congregations (church_id, name, short_name, type, sort_order, neighborhood, city, state) VALUES
            (v_church_id, 'Sede — Templo Central', 'Sede', 'sede', 0, 'Centro', 'Tutóia', 'MA'),
            (v_church_id, 'Congregação Paxicá', 'Paxicá', 'congregacao', 1, 'Paxicá', 'Tutóia', 'MA'),
            (v_church_id, 'Congregação Nova Terra', 'Nova Terra', 'congregacao', 2, 'Nova Terra', 'Tutóia', 'MA'),
            (v_church_id, 'Congregação Residencial', 'Residencial', 'congregacao', 3, 'Residencial', 'Tutóia', 'MA');
    END IF;
END $$;
```

---

## 9. Permissões e RBAC

### 9.1 Novas Permissões

| Permissão | Descrição |
|-----------|-----------|
| `congregations:read` | Visualizar lista e detalhes de congregações |
| `congregations:write` | Criar e editar congregações |
| `congregations:delete` | Desativar congregações |
| `congregations:assign` | Associar membros e usuários a congregações |
| `reports:congregations` | Visualizar relatórios consolidados e comparativos |

### 9.2 Matriz de Acesso

| Papel | Congregação | Membros (cong.) | Finanças (cong.) | EBD (cong.) | Patrimônio (cong.) | Relatórios |
|-------|:-----------:|:---------------:|:----------------:|:-----------:|:------------------:|:----------:|
| **Super Admin** | CRUD todas | CRUD todas | CRUD todas | CRUD todas | CRUD todas | Consolidado |
| **Admin/Pastor** | CRUD todas | CRUD todas | CRUD todas | CRUD todas | CRUD todas | Consolidado |
| **Dirigente** | Read sua + editar limitado | CRUD sua congregação | Read sua | CRUD sua | Read sua | Sua congregação |
| **Secretário local** | Read sua | CRUD sua congregação | — | Read sua | — | Sua congregação |
| **Tesoureiro local** | Read sua | — | CRUD sua congregação | — | — | Financeiro sua |
| **Professor EBD** | Read sua | — | — | EBD sua | — | EBD sua |
| **Membro** | Read sua | — | — | — | — | — |

---

## 10. Considerações Técnicas

### 10.1 Performance

- **Índices**: todos os novos `congregation_id` possuem índices para queries filtradas
- **Cache**: o Redis deve cachear a lista de congregações (muda raramente)
- **N+1 queries**: ao listar congregações com stats, usar uma única query com `LEFT JOIN` ao invés de N queries
- **Materialized views**: se o `vw_congregation_financial_summary` ficar lento, converter para materialized view com refresh periódico

### 10.2 Impacto no JWT

Duas opções para comunicar a congregação ativa:

**Opção A (recomendada): Query parameter / Header**
- O JWT mantém apenas `church_id` e `role`
- O frontend envia `congregation_id` como query parameter ou header `X-Congregation-Id`
- Mais flexível (troca de contexto sem novo token)

**Opção B: Novo claim no JWT**
- Adicionar `congregation_ids: Vec<Uuid>` no JWT com as congregações acessíveis
- Requer novo token ao mudar permissões de congregação
- Mais seguro mas menos flexível

**Decisão: Opção A** — o `congregation_id` é enviado via query parameter nas requests de listagem e no body das requests de criação. O backend valida o acesso usando `user_congregations` em tempo real.

### 10.3 Escalabilidade

O modelo suporta:
- Até **centenas de congregações** por igreja sem impacto significativo
- Crescimento futuro para **rede de igrejas** (múltiplas churches, cada uma com suas congregações)
- Eventual migração para schema-based multi-tenancy se necessário

---

## 11. Glossário

| Termo | Definição |
|-------|-----------|
| **Sede** | Templo central / matriz da igreja. A congregação principal. |
| **Congregação** | Ponto de culto estabelecido, geralmente com dirigente designado e atividades regulares (cultos, EBD). |
| **Ponto de pregação** | Local de culto provisório, em fase de estabelecimento. Menor formalidade que congregação. |
| **Dirigente** | Líder responsável por uma congregação. Geralmente um presbítero, diácono ou pastor auxiliar. |
| **Contexto ativo** | A congregação atualmente selecionada no frontend, que filtra todos os dados exibidos. |
| **Visão consolidada** | Dados agregados de todas as congregações juntas ("Geral"). |
| **Transferência interna** | Mudança de um membro de uma congregação para outra, dentro da mesma igreja. Sem burocracia formal. |

---

*Documento de especificação — módulo de congregações para o Igreja Manager.*

---

## 12. Registro de Implementação (20/02/2026)

### Resumo — Sessão v1.16

O módulo de Congregações foi implementado com sucesso na sessão v1.16. A implementação cobre as **Fases 1 e 3** do plano (infraestrutura completa + frontend do módulo).

### Resumo — Sessão v1.17 (Integração)

A sessão v1.17 avançou nas **Fases 2 e 4** (integração com módulos existentes):

**Backend (Fase 2):**
- `member_handler.rs` — filtro `congregation_id` na listagem e no stats (queries dinâmicas)
- `member_service.rs` — `congregation_id` no `create()` INSERT ($36) e `update()` SET, filtro no `list()`
- `member_dto.rs` — campo `congregation_id: Option<Uuid>` em `CreateMemberRequest`, `UpdateMemberRequest` e `MemberFilter`
- `congregation_handler.rs` — AuditService logging em create/update/deactivate + CacheService invalidation

**Frontend (Fase 4):**
- `app_shell.dart` — `CongregationSelector` integrado no sidebar (desktop) e AppBar (mobile) + nav item "Congregações" adicionado
- `member_bloc.dart` — escuta `CongregationContextCubit`, recarrega lista ao trocar congregação, passa `congregationId` ao repositório
- `member_event_state.dart` — `congregationId` adicionado a `MembersLoadRequested` e `MemberLoaded`
- `member_repository.dart` — `getMembers()` e `getStats()` aceitam `congregationId` como query param
- `member_models.dart` — campo `congregationId` no model `Member`, `fromJson` e `toCreateJson`
- `member_list_screen.dart` / `member_form_screen.dart` — passam `CongregationContextCubit` ao criar `MemberBloc`
- `dashboard_screen.dart` — recarrega stats ao trocar congregação, passa `congregationId` ao `getStats()`

### O que foi implementado (v1.16)

| Área | Componente | Arquivos | Linhas |
|------|-----------|:--------:|:------:|
| Backend | Migration SQL (tabelas + views + ALTER 11 tabelas) | 1 | ~175 |
| Backend | Entity (9 structs) | 1 | ~100 |
| Backend | DTOs (5 request structs com validação) | 1 | ~70 |
| Backend | Service (12 métodos, regras RN-CONG-001/002) | 1 | ~450 |
| Backend | Handler (12 endpoints com OpenAPI) | 1 | ~400 |
| Frontend | Models (5 classes Equatable + fromJson) | 1 | ~346 |
| Frontend | Repository (12 métodos API) | 1 | ~180 |
| Frontend | BLoC (5 events, 7 states) | 2 | ~200 |
| Frontend | Context Cubit (gerenciamento global) | 1 | ~100 |
| Frontend | Selector Widget (AppBar dropdown) | 1 | ~198 |
| Frontend | Lista (filter chips + cards) | 1 | ~405 |
| Frontend | Detalhe (stats + info + usuários) | 1 | ~350 |
| Frontend | Formulário (3 seções, responsivo) | 1 | ~829 |
| Frontend | Associar membros em lote | 1 | ~250 |
| **Total** | | **15 novos + 4 modificados** | **~4.050** |

### Regras de negócio implementadas

| Regra | Descrição | Status |
|-------|-----------|:------:|
| RN-CONG-001 | Sede única por igreja | ✅ Validação no service |
| RN-CONG-002 | Dirigente deve ser membro ativo | ✅ Validação no service |
| RN-CONG-003 | Membro pertence a uma congregação (NULL = sede) | ✅ Schema + assign-members |
| RN-CONG-009 | Contexto ativo no frontend | ✅ CongregationContextCubit |
| RN-CONG-010 | Dados existentes (NULL) continuam funcionando | ✅ Backwards-compatible |

### O que ficou pendente (restante Fases 2 e 4)

- Filtro `congregation_id` nos handlers/services de Financial, EBD, Assets, Ministries (backend)
- Middleware de filtro de congregação automático (backend)
- Integração do `CongregationContextCubit` nos BLoCs de Financial, EBD, Assets, Ministries (frontend)
- Dropdown de congregação nos formulários de criação de lançamentos financeiros, turmas EBD, patrimônio

### Resumo — Sessão v1.18 (Evolução do Módulo)

A sessão v1.18 avançou significativamente nas **Fases 2 e 4**, completando itens-chave:

**Backend:**
- Novo endpoint `GET /api/v1/reports/congregations/compare` com 4 métricas: `members`, `financial`, `ebd`, `assets`
- `get_congregation` agora retorna `CongregationDetail` enriquecido (leader_name + stats embutidos)
- `set_active_congregation` agora retorna `active_congregation_name` na resposta
- `assign_members` agora wrapped em SQL transaction (`pool.begin()` → `tx.commit()`)
- 3 novos entity types: `CongregationDetail`, `CongregationCompareReport`, `CongregationCompareItem`
- Novo DTO: `CongregationCompareFilter`
- Service expandido para ~700 linhas, 16 métodos (4 novos: `get_detail`, `validate_active_congregation`, `compare`, sub-métricas)

**Frontend:**
- Corrigida rota `/congregations` top-level (sidebar nav item agora funciona)
- Todas as páginas de congregações usam caminhos dinâmicos (`/congregations` ou `/settings/congregations`)
- Tela de detalhe agora permite adicionar/remover usuários (dialog com UUID, role, isPrimary)
- Nova tela `congregation_report_page.dart` (~430 linhas) com 2 abas: Overview + Comparativo
- Novos modelos `CongregationCompareReport` e `CongregationCompareItem`
- Repository expandido para 14 métodos (+`getCompareReport`, +`getCongregationStatsFromDetail`)

**Arquivos:** 1 criado + 12 modificados
