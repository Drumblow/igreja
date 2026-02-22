-- =================================================================
-- Migração: Integração User-Member + Controle de Acesso por Congregação
-- Data: 21 de fevereiro de 2026
-- Descrição:
--   1. Campo force_password_change em users
--   2. Campo active_congregation_id em users
--   3. Índice para busca de user por member_id
--   4. Role congregation_leader
--   5. Atualização de roles existentes
--   6. View de EBD por congregação
--   7. FKs cross-module nullable (padrão modular)
-- =================================================================

-- =========================================
-- 1. Novos campos na tabela users
-- =========================================

-- Campo para forçar troca de senha no primeiro login
ALTER TABLE users ADD COLUMN IF NOT EXISTS force_password_change BOOLEAN NOT NULL DEFAULT FALSE;

-- Congregação ativa selecionada pelo usuário (persistência de preferência)
ALTER TABLE users ADD COLUMN IF NOT EXISTS active_congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

-- =========================================
-- 2. Índices
-- =========================================

-- Busca eficiente de user por member_id
CREATE INDEX IF NOT EXISTS idx_users_member_id ON users(member_id) WHERE member_id IS NOT NULL;

-- =========================================
-- 3. Novo role: congregation_leader
-- =========================================

INSERT INTO roles (name, display_name, description, permissions, is_system)
VALUES (
    'congregation_leader',
    'Líder de Congregação',
    'Dirigente/responsável por uma congregação. Acesso completo dentro do escopo da sua congregação.',
    '["members:*", "financial:read", "financial:write", "assets:*", "ebd:*", "reports:*", "settings:read"]'::jsonb,
    TRUE
) ON CONFLICT (name) DO NOTHING;

-- =========================================
-- 4. Atualizar role pastor para incluir settings:write e congregations:*
-- =========================================

UPDATE roles
SET permissions = '["members:*", "financial:read", "financial:write", "assets:*", "ebd:*", "reports:*", "settings:read", "settings:write", "congregations:*"]'::jsonb,
    updated_at = NOW()
WHERE name = 'pastor'
  AND permissions::text NOT LIKE '%settings:write%';

-- =========================================
-- 5. View de estatísticas EBD por congregação (faltava)
-- =========================================

CREATE OR REPLACE VIEW vw_congregation_ebd_stats AS
SELECT
    c.id AS congregation_id,
    c.name AS congregation_name,
    COUNT(DISTINCT ec.id) AS total_classes,
    COUNT(DISTINCT ee.id) AS total_enrolled,
    COUNT(DISTINCT CASE
        WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id
    END) AS attendances_this_month,
    ROUND(
        CASE
            WHEN COUNT(DISTINCT CASE
                WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id
            END) > 0
            THEN COUNT(DISTINCT CASE
                WHEN ea.present = true AND el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id
            END)::NUMERIC
            / NULLIF(COUNT(DISTINCT CASE
                WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id
            END), 0) * 100
            ELSE 0
        END, 1
    ) AS attendance_percentage_this_month
FROM congregations c
LEFT JOIN ebd_classes ec ON ec.congregation_id = c.id
LEFT JOIN ebd_enrollments ee ON ee.class_id = ec.id
LEFT JOIN ebd_lessons el ON el.class_id = ec.id
LEFT JOIN ebd_attendances ea ON ea.lesson_id = el.id
WHERE c.is_active = true
GROUP BY c.id, c.name;

-- =========================================
-- 6. Tornar FKs cross-module nullable (padrão modular PF-001)
-- =========================================

-- ebd_enrollments.member_id: NOT NULL → NULL (para EBD funcionar sem módulo de Membros)
ALTER TABLE ebd_enrollments ALTER COLUMN member_id DROP NOT NULL;

-- asset_loans.borrower_member_id: NOT NULL → NULL, com campo texto alternativo
ALTER TABLE asset_loans ALTER COLUMN borrower_member_id DROP NOT NULL;
ALTER TABLE asset_loans ADD COLUMN IF NOT EXISTS borrower_name VARCHAR(200);

-- Constraint: deve ter member_id OU borrower_name preenchido
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_borrower_identification'
    ) THEN
        ALTER TABLE asset_loans ADD CONSTRAINT chk_borrower_identification
            CHECK (borrower_member_id IS NOT NULL OR borrower_name IS NOT NULL);
    END IF;
END $$;
