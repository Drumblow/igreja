-- ============================================
-- Igreja Manager — Migration: Member Improvements
-- 1. Create church_roles table (dynamic roles per church)
-- 2. Remove CHECK constraint on role_position
-- 3. Drop rg column
-- 4. Add marriage_date column
--
-- ⚠️  REGRA DE OURO: NUNCA modifique uma migration já aplicada!
--     Todas as alterações devem ir em novas migrations.
-- ============================================

-- ============================
-- 1. CARGOS DINÂMICOS POR IGREJA
-- ============================

CREATE TABLE church_roles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
    key             VARCHAR(50) NOT NULL,
    display_name    VARCHAR(100) NOT NULL,
    -- Tipo de investidura: consagracao, ordenacao, eleicao, nomeacao
    investiture_type VARCHAR(30) DEFAULT 'consagracao',
    sort_order      INT NOT NULL DEFAULT 0,
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(church_id, key)
);

CREATE INDEX idx_church_roles_church ON church_roles(church_id);
CREATE INDEX idx_church_roles_active ON church_roles(church_id, is_active);

-- Trigger para atualizar updated_at
CREATE TRIGGER trg_church_roles_updated
    BEFORE UPDATE ON church_roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Função para inserir cargos padrão ao criar uma igreja
CREATE OR REPLACE FUNCTION seed_default_church_roles(p_church_id UUID) RETURNS void AS $$
BEGIN
    INSERT INTO church_roles (church_id, key, display_name, investiture_type, sort_order, is_default) VALUES
        (p_church_id, 'pastor',                'Pastor(a)',               'consagracao', 1,  TRUE),
        (p_church_id, 'evangelista',            'Evangelista',             'consagracao', 2,  TRUE),
        (p_church_id, 'presbitero',             'Presbítero',             'ordenacao',   3,  TRUE),
        (p_church_id, 'diacono',                'Diácono/Diaconisa',      'ordenacao',   4,  TRUE),
        (p_church_id, 'coordenador_ministerio', 'Coordenador(a) de Ministério', 'nomeacao', 5, TRUE),
        (p_church_id, 'cooperador',             'Cooperador(a)',          'nomeacao',    6,  TRUE),
        (p_church_id, 'membro',                 'Membro',                 NULL,          7,  TRUE),
        (p_church_id, 'congregado',             'Congregado(a)',          NULL,          8,  TRUE);
END;
$$ LANGUAGE plpgsql;

-- Seed cargos padrão para igrejas já existentes
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id FROM churches LOOP
        PERFORM seed_default_church_roles(r.id);
    END LOOP;
END $$;

-- ============================
-- 2. REMOVER CHECK CONSTRAINT DE role_position
-- ============================

-- Identificar e remover a constraint CHECK no role_position
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    SELECT conname INTO constraint_name
    FROM pg_constraint
    WHERE conrelid = 'members'::regclass
      AND pg_get_constraintdef(oid) LIKE '%role_position%';

    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE members DROP CONSTRAINT %I', constraint_name);
    END IF;
END $$;

-- ============================
-- 3. REMOVER COLUNA RG
-- ============================

ALTER TABLE members DROP COLUMN IF EXISTS rg;

-- ============================
-- 4. ADICIONAR DATA DE CASAMENTO
-- ============================

ALTER TABLE members ADD COLUMN IF NOT EXISTS marriage_date DATE;
