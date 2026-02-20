-- ============================================================
-- Migration: EBD Module Evolution
-- Date: 2025-02-19
-- Description: Adds enriched lesson content, activities,
--              materials, student notes, and student profile view
-- ============================================================

-- ============================================================
-- E1: Conteúdo Enriquecido de Lições
-- ============================================================
CREATE TABLE ebd_lesson_contents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id       UUID NOT NULL REFERENCES ebd_lessons(id) ON DELETE CASCADE,
    content_type    VARCHAR(20) NOT NULL CHECK (content_type IN ('text', 'image', 'bible_reference', 'note')),
    title           VARCHAR(200),
    body            TEXT,
    image_url       VARCHAR(500),
    image_caption   VARCHAR(300),
    sort_order      INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lesson_contents_lesson ON ebd_lesson_contents(lesson_id);
CREATE INDEX idx_lesson_contents_order ON ebd_lesson_contents(lesson_id, sort_order);

CREATE TRIGGER trg_lesson_contents_updated BEFORE UPDATE ON ebd_lesson_contents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- E2: Atividades por Lição
-- ============================================================
CREATE TABLE ebd_lesson_activities (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id       UUID NOT NULL REFERENCES ebd_lessons(id) ON DELETE CASCADE,
    activity_type   VARCHAR(30) NOT NULL CHECK (activity_type IN (
        'question', 'multiple_choice', 'fill_blank', 'group_activity', 'homework', 'other'
    )),
    title           VARCHAR(300) NOT NULL,
    description     TEXT,
    options         JSONB,
    correct_answer  TEXT,
    bible_reference VARCHAR(200),
    is_required     BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order      INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lesson_activities_lesson ON ebd_lesson_activities(lesson_id);

CREATE TRIGGER trg_lesson_activities_updated BEFORE UPDATE ON ebd_lesson_activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE ebd_activity_responses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id     UUID NOT NULL REFERENCES ebd_lesson_activities(id) ON DELETE CASCADE,
    member_id       UUID NOT NULL REFERENCES members(id),
    response_text   TEXT,
    is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
    score           SMALLINT CHECK (score >= 0 AND score <= 10),
    teacher_feedback TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(activity_id, member_id)
);

CREATE INDEX idx_activity_responses_activity ON ebd_activity_responses(activity_id);
CREATE INDEX idx_activity_responses_member ON ebd_activity_responses(member_id);

CREATE TRIGGER trg_activity_responses_updated BEFORE UPDATE ON ebd_activity_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- E4: Materiais e Recursos da Lição
-- ============================================================
CREATE TABLE ebd_lesson_materials (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id       UUID NOT NULL REFERENCES ebd_lessons(id) ON DELETE CASCADE,
    material_type   VARCHAR(20) NOT NULL CHECK (material_type IN (
        'document', 'video', 'audio', 'link', 'image'
    )),
    title           VARCHAR(200) NOT NULL,
    description     VARCHAR(500),
    url             VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT,
    mime_type       VARCHAR(100),
    uploaded_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lesson_materials_lesson ON ebd_lesson_materials(lesson_id);

-- ============================================================
-- E5: Anotações do Professor por Aluno
-- ============================================================
CREATE TABLE ebd_student_notes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    member_id       UUID NOT NULL REFERENCES members(id),
    term_id         UUID REFERENCES ebd_terms(id),
    note_type       VARCHAR(30) NOT NULL CHECK (note_type IN (
        'observation', 'behavior', 'progress', 'special_need', 'praise', 'concern'
    )),
    title           VARCHAR(200),
    content         TEXT NOT NULL,
    is_private      BOOLEAN NOT NULL DEFAULT TRUE,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_student_notes_church ON ebd_student_notes(church_id);
CREATE INDEX idx_student_notes_member ON ebd_student_notes(member_id);
CREATE INDEX idx_student_notes_term ON ebd_student_notes(term_id);

CREATE TRIGGER trg_student_notes_updated BEFORE UPDATE ON ebd_student_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- E3: View do Perfil do Aluno EBD
-- ============================================================
CREATE OR REPLACE VIEW vw_ebd_student_profile AS
SELECT
    m.id AS member_id,
    m.church_id,
    m.full_name,
    m.birth_date,
    m.gender,
    m.phone_primary,
    m.email,
    m.photo_url,
    m.status AS member_status,
    COUNT(DISTINCT ee.id) FILTER (WHERE ee.is_active = TRUE) AS active_enrollments,
    COUNT(DISTINCT ee.id) AS total_enrollments,
    COUNT(DISTINCT ec.term_id) AS terms_attended,
    COUNT(ea.id) FILTER (WHERE ea.status = 'presente') AS total_present,
    COUNT(ea.id) FILTER (WHERE ea.status = 'ausente') AS total_absent,
    COUNT(ea.id) FILTER (WHERE ea.status = 'justificado') AS total_justified,
    COUNT(ea.id) AS total_attendance_records,
    CASE 
        WHEN COUNT(ea.id) > 0 
        THEN ROUND(
            COUNT(ea.id) FILTER (WHERE ea.status = 'presente')::DECIMAL / COUNT(ea.id) * 100, 1
        )
        ELSE 0 
    END AS attendance_percentage,
    COUNT(ea.id) FILTER (WHERE ea.brought_bible = TRUE) AS times_brought_bible,
    COUNT(ea.id) FILTER (WHERE ea.brought_magazine = TRUE) AS times_brought_magazine,
    COALESCE(SUM(ea.offering_amount), 0) AS total_offerings
FROM members m
INNER JOIN ebd_enrollments ee ON ee.member_id = m.id
INNER JOIN ebd_classes ec ON ec.id = ee.class_id
LEFT JOIN ebd_lessons el ON el.class_id = ec.id
LEFT JOIN ebd_attendances ea ON ea.lesson_id = el.id AND ea.member_id = m.id
WHERE m.deleted_at IS NULL
GROUP BY m.id, m.church_id, m.full_name, m.birth_date, m.gender, 
         m.phone_primary, m.email, m.photo_url, m.status;
