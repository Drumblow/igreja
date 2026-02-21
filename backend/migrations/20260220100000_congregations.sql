-- ============================================================================
-- Migration: Módulo de Congregações
-- Data: 2026-02-20
-- Descrição: Cria tabelas de congregações (congregations, user_congregations),
--            adiciona congregation_id em tabelas existentes, cria views consolidadas.
-- NUNCA modifique uma migration já aplicada em produção!
-- ============================================================================

-- ============================
-- 1. Tabela principal: congregations
-- ============================
CREATE TABLE IF NOT EXISTS congregations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
    
    -- Identificação
    name            VARCHAR(200) NOT NULL,
    short_name      VARCHAR(50),
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
    sort_order      INT NOT NULL DEFAULT 0,
    settings        JSONB DEFAULT '{}',
    
    -- Metadados
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(church_id, name)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_congregations_church ON congregations(church_id);
CREATE INDEX IF NOT EXISTS idx_congregations_active ON congregations(church_id, is_active);
CREATE INDEX IF NOT EXISTS idx_congregations_leader ON congregations(leader_id) WHERE leader_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_congregations_type ON congregations(church_id, type);

-- Trigger updated_at
CREATE OR REPLACE TRIGGER trg_congregations_updated
    BEFORE UPDATE ON congregations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================
-- 2. Tabela: user_congregations (Acesso do Usuário às Congregações)
-- ============================
CREATE TABLE IF NOT EXISTS user_congregations (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    congregation_id     UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
    
    -- Papel na congregação
    role_in_congregation VARCHAR(30) NOT NULL DEFAULT 'viewer'
                        CHECK (role_in_congregation IN (
                            'dirigente',
                            'secretario',
                            'tesoureiro',
                            'professor_ebd',
                            'viewer'
                        )),
    
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, congregation_id)
);

CREATE INDEX IF NOT EXISTS idx_user_congregations_user ON user_congregations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_congregations_congregation ON user_congregations(congregation_id);

-- ============================
-- 3. Adicionar congregation_id em tabelas existentes
-- ============================

-- MÓDULO DE MEMBROS
ALTER TABLE members 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_members_congregation 
    ON members(congregation_id) WHERE congregation_id IS NOT NULL;

-- MÓDULO FINANCEIRO
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

-- MÓDULO EBD
ALTER TABLE ebd_terms 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

ALTER TABLE ebd_classes 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_ebd_classes_congregation 
    ON ebd_classes(congregation_id) WHERE congregation_id IS NOT NULL;

-- MÓDULO PATRIMÔNIO
ALTER TABLE assets 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_assets_congregation 
    ON assets(congregation_id) WHERE congregation_id IS NOT NULL;

ALTER TABLE inventories 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

-- MÓDULO DE MINISTÉRIOS
ALTER TABLE ministries 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

-- ============================
-- 4. Views Consolidadas
-- ============================

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
