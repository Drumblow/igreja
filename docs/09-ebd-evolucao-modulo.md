# 📖 Evolução do Módulo EBD — Igreja Manager

> **Data de criação:** 19 de fevereiro de 2026  
> **Versão do documento:** 1.0  
> **Status:** Proposta de Evolução  
> **Módulo afetado:** EBD (Escola Bíblica Dominical)

---

## 1. Contexto e Motivação

O módulo EBD foi implementado com sucesso na **Fase 4** do projeto, cobrindo o fluxo básico de:
- Gestão de **trimestres/períodos** (`ebd_terms`)
- Gestão de **turmas** (`ebd_classes`) com professor titular e auxiliar
- **Matrícula** de alunos (`ebd_enrollments`) vinculados a membros
- Registro de **aulas/lições** (`ebd_lessons`) com título, texto bíblico e resumo
- **Frequência** (`ebd_attendances`) com status P/A/J, Bíblia, revista e oferta

Porém, ao usar o sistema na prática, identificou-se que:

1. **As lições são registros superficiais** — não é possível adicionar imagens ilustrativas, atividades práticas, materiais de apoio ou anotações enriquecidas. Na prática, professores precisam de um espaço para planejar e registrar o conteúdo detalhado de cada lição.

2. **O cadastro de alunos está funcional mas subaproveitado** — a matrícula já utiliza `member_id` (tabela `members`), porém **não existe uma visão unificada "Aluno EBD"** que mostre o histórico de turmas, frequência acumulada e progresso do aluno ao longo dos trimestres. Isso força o professor a navegar manualmente entre turmas para acompanhar cada aluno.

3. **Faltam funcionalidades de gestão pedagógica** — notas sobre alunos, atividades realizadas, materiais utilizados e avaliação qualitativa do trimestre.

### 1.1 Princípio Arquitetural: Membro como Aluno

**Decisão fundamental:** os alunos da EBD **são membros cadastrados no módulo de Membros** (`members`). Não criaremos uma tabela separada `ebd_students`.

**Justificativas:**
- Evita duplicação de dados pessoais (nome, contato, endereço, foto)
- O visitante que frequenta a EBD pode ser convertido em membro de forma natural
- O campo `members.status` já contempla `visitante` e `congregado`, perfis típicos de alunos da EBD
- A tabela `ebd_enrollments` já faz a vinculação via `member_id → members.id`
- Relatórios cruzados (frequência EBD + participação em ministérios + dados pessoais) ficam triviais

**O que muda na prática:** adicionamos **views e endpoints especializados** que montam a perspectiva "Aluno EBD" a partir dos dados existentes, sem duplicar o cadastro.

---

## 2. Diagnóstico do Estado Atual

### 2.1 O que Funciona (Backend + Frontend)

| Funcionalidade | Backend | Frontend | Observações |
|----------------|:-------:|:--------:|-------------|
| CRUD de Trimestres | ✅ 4 endpoints | ✅ Lista + criação | Falta edição na UI |
| CRUD de Turmas | ✅ 4 endpoints | ✅ Lista + detalhe | Falta edição na UI |
| Matrículas | ✅ 3 endpoints | ✅ Matricular/remover | Funcional com busca de membros |
| Criação de Aulas | ✅ 3 endpoints | ✅ Lista + criação | **Sem update/delete** |
| Frequência | ✅ 3 endpoints | ✅ P/A/J + Bíblia/Revista | Campo oferta sem UI |
| Relatório Turma | ✅ 1 endpoint | ❌ Sem tela | Repo implementado, sem tela |
| Stats (Overview) | ✅ 1 endpoint (cached) | ✅ Wired via API | Funcional |

### 2.2 Problemas Identificados

| # | Problema | Impacto | Severidade |
|---|----------|---------|:----------:|
| 1 | **Status de frequência em inglês no frontend** | Attendance screen envia `present`/`absent`/`justified`, backend espera `presente`/`ausente`/`justificado` — gera erro 400 | 🔴 Bug crítico |
| 2 | **Sem update/delete de aulas** | Professor não pode corrigir dados de uma aula criada | 🟡 Médio |
| 3 | **Sem edição de trimestres na UI** | Só é possível criar, não editar nome/datas/tema | 🟡 Médio |
| 4 | **Sem edição de turmas na UI** | Só é possível criar, não editar turma | 🟡 Médio |
| 5 | **Valor de oferta sem input na UI** | Campo `offering_amount` existe no modelo mas não há campo de entrada na tela de frequência | 🟡 Médio |
| 6 | **Campo `notes` em attendance não exposto** | DTO `AttendanceRecord` não inclui `notes` — nunca é salvo | 🟢 Baixo |
| 7 | **Sem audit logging para EBD** | Outros módulos têm `AuditService`, EBD não | 🟢 Baixo |
| 8 | **Sem paginação nas listas** | Todas as listas carregam apenas page 1 | 🟢 Baixo |
| 9 | **Tela de relatório da turma inexistente** | `EbdClassReportLoaded` state existe mas sem screen | 🟡 Médio |
| 10 | **Sem delete de trimestres/turmas** | Backend não implementa exclusão | 🟢 Baixo |

### 2.3 Tabelas e Campos Atuais (Referência)

```
ebd_terms:      id, church_id, name, start_date, end_date, theme, magazine_title, is_active
ebd_classes:    id, church_id, term_id, name, age_range_start/end, room, max_capacity, teacher_id, aux_teacher_id, is_active
ebd_enrollments: id, class_id, member_id, enrolled_at, left_at, is_active, notes
ebd_lessons:    id, church_id, class_id, lesson_date, lesson_number, title, theme, bible_text, summary, teacher_id, materials_used
ebd_attendances: id, lesson_id, member_id, status, brought_bible, brought_magazine, offering_amount, is_visitor, visitor_name, notes, registered_by
```

---

## 3. Novas Funcionalidades Propostas

### 3.1 Visão Geral das Evoluções

| # | Funcionalidade | Prioridade | Complexidade | Novas Tabelas |
|---|----------------|:----------:|:------------:|:-------------:|
| E1 | Conteúdo Enriquecido de Lições (imagens + texto) | 🔴 Alta | Alta | `ebd_lesson_contents` |
| E2 | Atividades por Lição | 🔴 Alta | Alta | `ebd_lesson_activities`, `ebd_activity_responses` |
| E3 | Perfil Unificado do Aluno EBD | 🔴 Alta | Média | View `vw_ebd_student_profile` |
| E4 | Materiais e Recursos da Lição | 🟡 Média | Média | `ebd_lesson_materials` |
| E5 | Anotações do Professor por Aluno | 🟡 Média | Baixa | `ebd_student_notes` |
| E6 | Relatórios Avançados da EBD | 🟡 Média | Média | — |
| E7 | Clonagem de Turmas entre Trimestres | 🟡 Média | Baixa | — |
| F1 | Correções e melhorias no código existente | 🔴 Alta | Baixa | — |

---

## 4. Detalhamento das Funcionalidades

### 4.1 [E1] Conteúdo Enriquecido de Lições

#### Problema
Atualmente, a tabela `ebd_lessons` possui apenas campos textuais simples (`title`, `theme`, `bible_text`, `summary`, `materials_used`). Não é possível:
- Adicionar **imagens** ilustrativas (fotos do quadro, slides, figuras bíblicas)
- Estruturar o **conteúdo da lição** em seções (introdução, desenvolvimento, aplicação)
- Vincular **referências bíblicas múltiplas** com comentários

#### Solução: Tabela `ebd_lesson_contents`

Adiciona blocos de conteúdo ordenados à lição, suportando texto rico e imagens.

```sql
CREATE TABLE ebd_lesson_contents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id       UUID NOT NULL REFERENCES ebd_lessons(id) ON DELETE CASCADE,
    
    -- Tipo do bloco
    content_type    VARCHAR(20) NOT NULL CHECK (content_type IN (
        'text',           -- Bloco de texto (markdown/plain)
        'image',          -- Imagem com legenda
        'bible_reference', -- Referência bíblica destacada
        'note'            -- Nota/observação do professor
    )),
    
    -- Conteúdo
    title           VARCHAR(200),               -- Título do bloco (ex: "Introdução", "Versículo-chave")
    body            TEXT,                        -- Conteúdo textual ou URL da imagem
    image_url       VARCHAR(500),               -- URL da imagem (quando content_type = 'image')
    image_caption   VARCHAR(300),               -- Legenda da imagem
    
    -- Ordenação
    sort_order      INT NOT NULL DEFAULT 0,     -- Ordem de exibição
    
    -- Metadados
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lesson_contents_lesson ON ebd_lesson_contents(lesson_id);
CREATE INDEX idx_lesson_contents_order ON ebd_lesson_contents(lesson_id, sort_order);

CREATE TRIGGER trg_lesson_contents_updated BEFORE UPDATE ON ebd_lesson_contents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

#### Endpoints Novos

| Método | Rota | Descrição | Perm |
|--------|------|-----------|------|
| `GET` | `/api/v1/ebd/lessons/{id}/contents` | Listar blocos de conteúdo da lição (ordenados) | `ebd:read` |
| `POST` | `/api/v1/ebd/lessons/{id}/contents` | Adicionar bloco de conteúdo | `ebd:write` |
| `PUT` | `/api/v1/ebd/lessons/{lid}/contents/{cid}` | Atualizar bloco de conteúdo | `ebd:write` |
| `DELETE` | `/api/v1/ebd/lessons/{lid}/contents/{cid}` | Remover bloco de conteúdo | `ebd:write` |
| `PUT` | `/api/v1/ebd/lessons/{id}/contents/reorder` | Reordenar blocos | `ebd:write` |
| `POST` | `/api/v1/ebd/lessons/{id}/contents/upload` | Upload de imagem (multipart) | `ebd:write` |

#### DTOs

```rust
// Request
pub struct CreateLessonContentRequest {
    pub content_type: String,     // "text" | "image" | "bible_reference" | "note"
    pub title: Option<String>,
    pub body: Option<String>,
    pub image_url: Option<String>,
    pub image_caption: Option<String>,
    pub sort_order: Option<i32>,
}

pub struct UpdateLessonContentRequest {
    pub content_type: Option<String>,
    pub title: Option<String>,
    pub body: Option<String>,
    pub image_url: Option<String>,
    pub image_caption: Option<String>,
    pub sort_order: Option<i32>,
}

pub struct ReorderContentsRequest {
    pub content_ids: Vec<Uuid>,   // IDs na nova ordem
}

// Response
pub struct LessonContentResponse {
    pub id: Uuid,
    pub lesson_id: Uuid,
    pub content_type: String,
    pub title: Option<String>,
    pub body: Option<String>,
    pub image_url: Option<String>,
    pub image_caption: Option<String>,
    pub sort_order: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
```

#### Frontend — Tela de Detalhe da Lição (Nova)

Nova tela: `/ebd/lessons/:lessonId` → `EbdLessonDetailScreen`

**Layout:**
- **Header:** Título da lição, nº da lição, data, turma, professor
- **Seção "Conteúdo da Lição":** Lista ordenável de blocos
  - Bloco de texto renderizado com formatação
  - Bloco de imagem com preview + legenda
  - Referência bíblica com destaque visual
  - Nota do professor com fundo diferenciado
- **FAB:** "Adicionar Conteúdo" → Bottom sheet com opções (Texto, Imagem, Referência, Nota)
- **Ação no cabeçalho:** "Registrar Frequência" → navega para attendance

#### Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN-EBD-E1-001 | Cada lição pode ter até **20 blocos** de conteúdo |
| RN-EBD-E1-002 | Imagens são armazenadas via upload (multipart) e servidas como URL estática |
| RN-EBD-E1-003 | O tamanho máximo de imagem é **5 MB** (formatos: jpg, png, webp) |
| RN-EBD-E1-004 | O campo `body` suporta texto simples (Markdown será renderizado no frontend) |
| RN-EBD-E1-005 | Ao excluir uma lição, todos os conteúdos são removidos em cascata (`ON DELETE CASCADE`) |
| RN-EBD-E1-006 | A reordenação atualiza `sort_order` de todos os blocos em uma transação única |

---

### 4.2 [E2] Atividades por Lição

#### Problema
Professores precisam registrar atividades práticas vinculadas à lição (perguntas de revisão, tarefas para casa, dinâmicas em grupo, completar versículos, etc.) e opcionalmente rastrear a participação dos alunos nessas atividades.

#### Solução: Tabelas `ebd_lesson_activities` + `ebd_activity_responses`

```sql
-- Atividades associadas a uma lição
CREATE TABLE ebd_lesson_activities (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id       UUID NOT NULL REFERENCES ebd_lessons(id) ON DELETE CASCADE,
    
    -- Tipo da atividade
    activity_type   VARCHAR(30) NOT NULL CHECK (activity_type IN (
        'question',          -- Pergunta de revisão (resposta livre)
        'multiple_choice',   -- Pergunta de múltipla escolha
        'fill_blank',        -- Complete o versículo/texto
        'group_activity',    -- Dinâmica de grupo (sem resposta individual)
        'homework',          -- Tarefa para casa
        'other'              -- Outro tipo
    )),
    
    -- Conteúdo
    title           VARCHAR(300) NOT NULL,          -- Enunciado da atividade
    description     TEXT,                           -- Instruções detalhadas
    options         JSONB,                          -- Opções (para multiple_choice): ["a) ...", "b) ...", "c) ..."]
    correct_answer  TEXT,                           -- Resposta esperada (visível só para professor)
    bible_reference VARCHAR(200),                   -- Referência bíblica relacionada
    
    -- Controle
    is_required     BOOLEAN NOT NULL DEFAULT FALSE, -- Atividade obrigatória?
    sort_order      INT NOT NULL DEFAULT 0,
    
    -- Metadados
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lesson_activities_lesson ON ebd_lesson_activities(lesson_id);

CREATE TRIGGER trg_lesson_activities_updated BEFORE UPDATE ON ebd_lesson_activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Respostas/participação dos alunos nas atividades
CREATE TABLE ebd_activity_responses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id     UUID NOT NULL REFERENCES ebd_lesson_activities(id) ON DELETE CASCADE,
    member_id       UUID NOT NULL REFERENCES members(id),
    
    -- Resposta
    response_text   TEXT,                           -- Resposta do aluno
    is_completed    BOOLEAN NOT NULL DEFAULT FALSE, -- Marcou como concluída?
    score           SMALLINT CHECK (score >= 0 AND score <= 10), -- Nota opcional (0-10)
    
    -- Feedback do professor
    teacher_feedback TEXT,
    
    -- Metadados
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(activity_id, member_id)
);

CREATE INDEX idx_activity_responses_activity ON ebd_activity_responses(activity_id);
CREATE INDEX idx_activity_responses_member ON ebd_activity_responses(member_id);

CREATE TRIGGER trg_activity_responses_updated BEFORE UPDATE ON ebd_activity_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

#### Endpoints Novos

| Método | Rota | Descrição | Perm |
|--------|------|-----------|------|
| `GET` | `/api/v1/ebd/lessons/{id}/activities` | Listar atividades da lição | `ebd:read` |
| `POST` | `/api/v1/ebd/lessons/{id}/activities` | Criar atividade | `ebd:write` |
| `PUT` | `/api/v1/ebd/lessons/{lid}/activities/{aid}` | Atualizar atividade | `ebd:write` |
| `DELETE` | `/api/v1/ebd/lessons/{lid}/activities/{aid}` | Remover atividade | `ebd:write` |
| `GET` | `/api/v1/ebd/activities/{aid}/responses` | Listar respostas dos alunos | `ebd:read` |
| `POST` | `/api/v1/ebd/activities/{aid}/responses` | Registrar resposta em lote | `ebd:write` |
| `PUT` | `/api/v1/ebd/activities/{aid}/responses/{rid}` | Atualizar resposta (feedback) | `ebd:write` |

#### DTOs

```rust
pub struct CreateLessonActivityRequest {
    pub activity_type: String,
    #[validate(length(min = 3, max = 300))]
    pub title: String,
    pub description: Option<String>,
    pub options: Option<serde_json::Value>,     // JSON array para multiple_choice
    pub correct_answer: Option<String>,
    pub bible_reference: Option<String>,
    pub is_required: Option<bool>,
    pub sort_order: Option<i32>,
}

pub struct UpdateLessonActivityRequest {
    pub activity_type: Option<String>,
    pub title: Option<String>,
    pub description: Option<String>,
    pub options: Option<serde_json::Value>,
    pub correct_answer: Option<String>,
    pub bible_reference: Option<String>,
    pub is_required: Option<bool>,
    pub sort_order: Option<i32>,
}

pub struct ActivityResponseRecord {
    pub member_id: Uuid,
    pub response_text: Option<String>,
    pub is_completed: bool,
    pub score: Option<i16>,
    pub teacher_feedback: Option<String>,
}

pub struct CreateActivityResponsesRequest {
    pub responses: Vec<ActivityResponseRecord>,  // Batch
}
```

#### Frontend — Tela de Atividades

Integrada na `EbdLessonDetailScreen` como aba ou seção:

**Componentes:**
- Lista de atividades com ícone por tipo (❓ question, 📝 fill_blank, 👥 group, 🏠 homework)
- Dialog/Bottom sheet para criar atividade com campos dinâmicos por tipo
- Para `multiple_choice`: builder de opções (adicionar/remover alternativas)
- Para `fill_blank`: campo com placeholder `___` para o texto com lacunas
- Tela de respostas: lista de alunos matriculados com campo de resposta/check e nota opcional

#### Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN-EBD-E2-001 | Cada lição pode ter até **10 atividades** |
| RN-EBD-E2-002 | Atividades do tipo `multiple_choice` devem ter entre 2 e 6 opções |
| RN-EBD-E2-003 | A `correct_answer` é visível apenas para o professor (permissão `ebd:write`) |
| RN-EBD-E2-004 | Respostas usam UPSERT — um aluno pode atualizar sua resposta |
| RN-EBD-E2-005 | Atividades de grupo (`group_activity`) não exigem resposta individual |
| RN-EBD-E2-006 | A nota (`score`) é opcional e de 0 a 10 |
| RN-EBD-E2-007 | Atividades podem ser editadas enquanto a lição estiver no período editável (RN-EBD-004: 7 dias) |

---

### 4.3 [E3] Perfil Unificado do Aluno EBD

#### Problema
Não existe uma visão "Aluno" que consolide: dados pessoais (do membro), histórico de turmas, frequência acumulada, atividades realizadas e notas do professor. O professor precisa navegar por múltiplas telas para obter essa visão.

#### Solução: View + Endpoint Especializado

```sql
-- View materializada: perfil do aluno na EBD
CREATE VIEW vw_ebd_student_profile AS
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
    
    -- Métricas EBD agregadas
    COUNT(DISTINCT ee.id) FILTER (WHERE ee.is_active = TRUE) AS active_enrollments,
    COUNT(DISTINCT ee.id) AS total_enrollments,
    COUNT(DISTINCT ec.term_id) AS terms_attended,
    
    -- Frequência geral
    COUNT(ea.id) FILTER (WHERE ea.status = 'presente') AS total_present,
    COUNT(ea.id) FILTER (WHERE ea.status = 'ausente') AS total_absent,
    COUNT(ea.id) FILTER (WHERE ea.status = 'justificado') AS total_justified,
    COUNT(ea.id) AS total_attendance_records,
    
    -- Indicadores
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
```

#### Endpoints Novos

| Método | Rota | Descrição | Perm |
|--------|------|-----------|------|
| `GET` | `/api/v1/ebd/students` | Listar alunos da EBD (com filtros: term, class, status) | `ebd:read` |
| `GET` | `/api/v1/ebd/students/{member_id}` | Perfil completo do aluno (dados pessoais + EBD) | `ebd:read` |
| `GET` | `/api/v1/ebd/students/{member_id}/history` | Histórico de turmas e frequência por trimestre | `ebd:read` |
| `GET` | `/api/v1/ebd/students/{member_id}/activities` | Atividades e respostas do aluno | `ebd:read` |

#### DTOs

```rust
pub struct EbdStudentSummary {
    pub member_id: Uuid,
    pub full_name: String,
    pub birth_date: Option<NaiveDate>,
    pub gender: String,
    pub phone_primary: Option<String>,
    pub photo_url: Option<String>,
    pub member_status: String,
    pub active_enrollments: i64,
    pub attendance_percentage: Decimal,
    pub current_class_name: Option<String>,      // Turma ativa atual
    pub current_term_name: Option<String>,        // Trimestre ativo atual
}

pub struct EbdStudentProfile {
    // Dados pessoais (do membro)
    pub member_id: Uuid,
    pub full_name: String,
    pub birth_date: Option<NaiveDate>,
    pub gender: String,
    pub phone_primary: Option<String>,
    pub email: Option<String>,
    pub photo_url: Option<String>,
    pub member_status: String,
    
    // Métricas EBD
    pub total_enrollments: i64,
    pub terms_attended: i64,
    pub total_present: i64,
    pub total_absent: i64,
    pub total_justified: i64,
    pub attendance_percentage: Decimal,
    pub times_brought_bible: i64,
    pub times_brought_magazine: i64,
    pub total_offerings: Decimal,
    
    // Turma atual (se matriculado em trimestre ativo)
    pub current_enrollment: Option<CurrentEnrollment>,
    
    // Histórico de turmas
    pub enrollment_history: Vec<EnrollmentHistoryItem>,
}

pub struct CurrentEnrollment {
    pub class_id: Uuid,
    pub class_name: String,
    pub term_name: String,
    pub teacher_name: Option<String>,
    pub enrolled_at: NaiveDate,
}

pub struct EnrollmentHistoryItem {
    pub term_name: String,
    pub class_name: String,
    pub enrolled_at: NaiveDate,
    pub left_at: Option<NaiveDate>,
    pub lessons_attended: i64,
    pub total_lessons: i64,
    pub attendance_percentage: Decimal,
}

pub struct EbdStudentFilter {
    pub term_id: Option<Uuid>,
    pub class_id: Option<Uuid>,
    pub search: Option<String>,           // Busca por nome do membro
    pub min_attendance: Option<Decimal>,   // Frequência mínima (%)
    pub max_attendance: Option<Decimal>,   // Frequência máxima (%)
}
```

#### Frontend — Tela de Alunos EBD (Nova)

Nova rota: `/ebd/students` → `EbdStudentListScreen`
Nova rota: `/ebd/students/:memberId` → `EbdStudentProfileScreen`

**`EbdStudentListScreen`:**
- Barra de busca (nome do aluno)
- Filtros: Trimestre, Turma, Faixa de frequência
- Lista de alunos com: avatar, nome, turma atual, badge de frequência (cor por indicador)
- FAB: "Matricular Aluno" → busca de membros + seleção de turma

**`EbdStudentProfileScreen`:**
- **Card de perfil:** foto, nome, idade, contato (dados do membro — somente leitura)
- **Métricas:** 4 stat cards (frequência %, aulas presentes, Bíblias, ofertas)
- **Turma atual:** nome da turma, professor, data de matrícula — link para turma
- **Histórico de turmas:** timeline ordenada por trimestre
  - Por trimestre: nome da turma, presença X/Y (Z%), badge de indicador
- **Seção de notas do professor** (ver E5)
- **Link "Ver cadastro completo":** navega para `/members/:id`

#### Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN-EBD-E3-001 | O perfil do aluno é uma **projeção** dos dados de `members` — não duplica dados |
| RN-EBD-E3-002 | Um membro aparece como "aluno EBD" somente se tiver **pelo menos 1 matrícula** (ativa ou inativa) |
| RN-EBD-E3-003 | A frequência percentual é calculada sobre o total de aulas da turma onde o aluno estava matriculado |
| RN-EBD-E3-004 | Os indicadores de frequência seguem a regra RN-EBD-005 (≥90% Excelente, 75-89% Bom, 50-74% Regular, <50% Insuficiente) |
| RN-EBD-E3-005 | O acesso ao perfil do aluno exige permissão `ebd:read` |

---

### 4.4 [E4] Materiais e Recursos da Lição

#### Problema
Professores utilizam diversos materiais de apoio (PDFs, links de vídeos, imagens, arquivos) e não há onde registrá-los de forma organizada.

#### Solução: Tabela `ebd_lesson_materials`

```sql
CREATE TABLE ebd_lesson_materials (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id       UUID NOT NULL REFERENCES ebd_lessons(id) ON DELETE CASCADE,
    
    -- Tipo do material
    material_type   VARCHAR(20) NOT NULL CHECK (material_type IN (
        'document',     -- PDF, DOC, etc.
        'video',        -- Link de vídeo (YouTube, Vimeo, etc.)
        'audio',        -- Áudio (hino, podcast)
        'link',         -- Link externo genérico
        'image'         -- Imagem/Figura adicional
    )),
    
    -- Detalhes
    title           VARCHAR(200) NOT NULL,
    description     VARCHAR(500),
    url             VARCHAR(500) NOT NULL,       -- URL do arquivo ou link externo
    file_size_bytes BIGINT,                      -- Tamanho do arquivo (se upload)
    mime_type       VARCHAR(100),                -- Tipo MIME (se upload)
    
    -- Metadados
    uploaded_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lesson_materials_lesson ON ebd_lesson_materials(lesson_id);
```

#### Endpoints Novos

| Método | Rota | Descrição | Perm |
|--------|------|-----------|------|
| `GET` | `/api/v1/ebd/lessons/{id}/materials` | Listar materiais da lição | `ebd:read` |
| `POST` | `/api/v1/ebd/lessons/{id}/materials` | Adicionar material (link) | `ebd:write` |
| `POST` | `/api/v1/ebd/lessons/{id}/materials/upload` | Upload de arquivo (multipart) | `ebd:write` |
| `DELETE` | `/api/v1/ebd/lessons/{lid}/materials/{mid}` | Remover material | `ebd:write` |

#### Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN-EBD-E4-001 | Cada lição pode ter até **10 materiais** anexados |
| RN-EBD-E4-002 | Uploads de arquivos limitados a **10 MB** por arquivo |
| RN-EBD-E4-003 | Formatos aceitos para upload: pdf, doc, docx, jpg, png, webp, mp3, mp4 |
| RN-EBD-E4-004 | Links de vídeo (YouTube/Vimeo) são validados por regex de URL |
| RN-EBD-E4-005 | Ao excluir a lição, os materiais são removidos em cascata. Arquivos físicos devem ser removidos do storage |

---

### 4.5 [E5] Anotações do Professor por Aluno

#### Problema
Professores precisam fazer anotações sobre o desenvolvimento, comportamento, necessidades especiais e progresso de cada aluno, ao longo do trimestre. Não existe um local para registrar essas observações.

#### Solução: Tabela `ebd_student_notes`

```sql
CREATE TABLE ebd_student_notes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id),
    member_id       UUID NOT NULL REFERENCES members(id),       -- O aluno
    term_id         UUID REFERENCES ebd_terms(id),              -- Trimestre (opcional, pode ser nota geral)
    
    -- Conteúdo
    note_type       VARCHAR(30) NOT NULL CHECK (note_type IN (
        'observation',     -- Observação geral
        'behavior',        -- Comportamento
        'progress',        -- Progresso na aprendizagem
        'special_need',    -- Necessidade especial
        'praise',          -- Elogio/destaque positivo
        'concern'          -- Preocupação/atenção
    )),
    title           VARCHAR(200),
    content         TEXT NOT NULL,
    is_private      BOOLEAN NOT NULL DEFAULT TRUE,   -- Visível só para professores/secretários
    
    -- Metadados
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_student_notes_church ON ebd_student_notes(church_id);
CREATE INDEX idx_student_notes_member ON ebd_student_notes(member_id);
CREATE INDEX idx_student_notes_term ON ebd_student_notes(term_id);

CREATE TRIGGER trg_student_notes_updated BEFORE UPDATE ON ebd_student_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

#### Endpoints Novos

| Método | Rota | Descrição | Perm |
|--------|------|-----------|------|
| `GET` | `/api/v1/ebd/students/{member_id}/notes` | Listar notas do aluno (filtro: term, type) | `ebd:read` |
| `POST` | `/api/v1/ebd/students/{member_id}/notes` | Criar nota | `ebd:write` |
| `PUT` | `/api/v1/ebd/students/{mid}/notes/{nid}` | Atualizar nota (apenas o autor) | `ebd:write` |
| `DELETE` | `/api/v1/ebd/students/{mid}/notes/{nid}` | Remover nota (apenas o autor) | `ebd:write` |

#### Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN-EBD-E5-001 | Notas marcadas como `is_private = true` são visíveis apenas para usuários com permissão `ebd:write` |
| RN-EBD-E5-002 | Apenas o autor da nota pode editá-la ou excluí-la |
| RN-EBD-E5-003 | Notas são mantidas mesmo se o aluno sair da turma ou trocar de trimestre |
| RN-EBD-E5-004 | Se `term_id` é NULL, a nota é considerada "geral" (não vinculada a um trimestre específico) |

---

### 4.6 [E6] Relatórios Avançados da EBD

#### Problema
O endpoint `GET /api/v1/ebd/classes/{id}/report` existe no backend e retorna dados de frequência por turma, mas:
- Não há tela no frontend
- Não há relatório consolidado por trimestre
- Não há comparativo entre trimestres
- Não há ranking de turmas ou alunos

#### Solução: Novos Endpoints + Telas

| Método | Rota | Descrição | Perm |
|--------|------|-----------|------|
| `GET` | `/api/v1/ebd/reports/term/{term_id}` | Relatório consolidado do trimestre | `ebd:read` |
| `GET` | `/api/v1/ebd/reports/term/{term_id}/ranking` | Ranking de turmas por presença | `ebd:read` |
| `GET` | `/api/v1/ebd/reports/comparison` | Comparativo entre trimestres (query: term_ids[]) | `ebd:read` |
| `GET` | `/api/v1/ebd/reports/students/attendance` | Alunos faltosos (ausências consecutivas ≥ 3) | `ebd:read` |

#### DTOs de Relatório

```rust
pub struct TermReportResponse {
    pub term_id: Uuid,
    pub term_name: String,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub total_classes: i64,
    pub total_students: i64,
    pub total_lessons: i64,
    pub average_attendance_percentage: Decimal,
    pub total_offerings: Decimal,
    pub total_bibles_brought: i64,
    pub total_magazines_brought: i64,
    pub classes_summary: Vec<ClassReportSummary>,
}

pub struct ClassReportSummary {
    pub class_id: Uuid,
    pub class_name: String,
    pub teacher_name: Option<String>,
    pub enrolled_count: i64,
    pub total_lessons: i64,
    pub average_attendance: Decimal,
    pub attendance_percentage: Decimal,
    pub total_offerings: Decimal,
}

pub struct TermComparisonResponse {
    pub terms: Vec<TermComparisonItem>,
}

pub struct TermComparisonItem {
    pub term_id: Uuid,
    pub term_name: String,
    pub total_students: i64,
    pub total_lessons: i64,
    pub average_attendance_percentage: Decimal,
    pub total_offerings: Decimal,
    pub student_growth_percentage: Option<Decimal>,    // vs. trimestre anterior
    pub attendance_growth_percentage: Option<Decimal>,  // vs. trimestre anterior
}

pub struct AbsentStudentAlert {
    pub member_id: Uuid,
    pub member_name: String,
    pub class_name: String,
    pub consecutive_absences: i64,
    pub last_present_date: Option<NaiveDate>,
    pub phone_primary: Option<String>,
}
```

#### Frontend — Telas de Relatório

Nova rota: `/ebd/reports` → `EbdReportScreen`

**Seções:**
1. **Seletor de trimestre** (dropdown)
2. **Cards de resumo:** Total alunos, Total aulas, Média presença, Total ofertas
3. **Ranking de turmas:** Tabela ordenada por presença (%) com barra de progresso visual
4. **Comparativo:** Gráfico de barras comparando 2-4 trimestres (presença + alunos)
5. **Alerta de faltosos:** Lista de alunos com ≥3 ausências consecutivas, com botão de contato (telefone)

---

### 4.7 [E7] Clonagem de Turmas entre Trimestres

#### Problema
A cada novo trimestre, geralme as turmas se mantêm similares (mesmos nomes, faixas etárias, professores). Recriar manualmente é improdutivo.

#### Solução: Endpoint de Clonagem

| Método | Rota | Descrição | Perm |
|--------|------|-----------|------|
| `POST` | `/api/v1/ebd/terms/{term_id}/clone-classes` | Clonar turmas de um trimestre para outro | `ebd:write` |

```rust
pub struct CloneClassesRequest {
    pub source_term_id: Uuid,       // Trimestre origem
    pub include_enrollments: bool,  // Clonar matrículas também?
}

pub struct CloneClassesResponse {
    pub classes_cloned: i64,
    pub enrollments_cloned: i64,    // 0 se include_enrollments = false
}
```

#### Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN-EBD-E7-001 | Clona apenas turmas ativas do trimestre origem |
| RN-EBD-E7-002 | Se `include_enrollments = true`, apenas matrículas ativas são clonadas |
| RN-EBD-E7-003 | O professor titular e auxiliar são mantidos na clonagem |
| RN-EBD-E7-004 | Se uma turma com o mesmo nome já existe no trimestre destino, a clonagem é ignorada para essa turma |
| RN-EBD-E7-005 | Um aluno não pode ser matriculado em duas turmas do mesmo trimestre (RN-EBD-003 continua válida) |

---

### 4.8 [F1] Correções no Código Existente

#### F1.1 — Bug: Status de Frequência (EN vs PT)

**Arquivo:** `frontend/lib/features/ebd/presentation/ebd_attendance_screen.dart`

**Problema:** O frontend envia status em inglês (`present`, `absent`, `justified`) mas o backend PostgreSQL tem CHECK constraint e o service valida em português (`presente`, `ausente`, `justificado`).

**Solução:** Padronizar no frontend para enviar os valores em português.

```dart
// ANTES (bug)
status: 'present'   // ❌

// DEPOIS (correção)
status: 'presente'  // ✅
```

Ajustar também `statusLabel` getters nos models para interpretar os valores corretos.

#### F1.2 — Update/Delete de Aulas

**Backend:**
- Adicionar `UpdateEbdLessonRequest` DTO (todos os campos opcionais)
- Implementar `update()` e `delete()` no `ebd_lesson_service.rs`
- Adicionar endpoints `PUT /api/v1/ebd/lessons/{id}` e `DELETE /api/v1/ebd/lessons/{id}`
- Delete verifica se não há attendances registradas (ou confirma com flag `force`)

**Frontend:**
- Adicionar `EbdLessonUpdateRequested` e `EbdLessonDeleteRequested` events
- Adicionar estados correspondentes no BLoC
- Adicionar botões de edição/exclusão na UI de lição

#### F1.3 — Edição de Trimestres e Turmas na UI

**Frontend:**
- `EbdTermListScreen`: adicionar botão de edição em cada item da lista → abre dialog pré-preenchido
- `EbdClassDetailScreen`: adicionar botão de edição → navega para form pré-preenchido com dados da turma

#### F1.4 — Campo de Oferta na Frequência

**Frontend:** Adicionar `TextFormField` para `offering_amount` na tela de frequência (`EbdAttendanceScreen`), formatado como moeda (BRL).

#### F1.5 — Campo `notes` na Frequência

**Backend:** Adicionar `notes: Option<String>` ao DTO `AttendanceRecord`.
**Frontend:** Adicionar campo de observação na tela de frequência.

#### F1.6 — Audit Logging para EBD

**Backend:** Integrar `AuditService::log()` nos services EBD para todas as operações de escrita (create/update/delete).

#### F1.7 — Paginação nas Listas

**Frontend:** Implementar scroll infinito (lazy loading) nas listas de turmas, aulas e alunos, usando o pattern já estabelecido no módulo de membros.

#### F1.8 — Tela de Relatório de Turma

**Frontend:** Criar `EbdClassReportScreen` que usa o endpoint existente `GET /api/v1/ebd/classes/{id}/report`. Acessível a partir da `EbdClassDetailScreen`.

---

## 5. Modelo de Dados Atualizado (EBD Completo)

### 5.1 Diagrama ER Simplificado

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  ebd_terms   │◄────│ ebd_classes  │────►│    members       │
│              │  1:N │              │  N:1 │  (professor)     │
│ id           │     │ id           │     │                  │
│ name         │     │ term_id  (FK)│     │ id               │
│ start_date   │     │ name         │     │ full_name        │
│ end_date     │     │ teacher_id   │     │ birth_date       │
│ theme        │     │ aux_teacher  │     │ ...              │
│ magazine     │     │ room         │     └────────┬─────────┘
│ is_active    │     │ max_capacity │              │
└──────────────┘     │ age_range    │              │
                     └──────┬───────┘              │
                            │ 1:N                  │
              ┌─────────────┼──────────────┐       │
              │             │              │       │
              ▼             ▼              ▼       │
    ┌─────────────┐  ┌────────────┐  ┌──────────────────┐
    │ebd_enrollme-│  │ebd_lessons │  │  members  (aluno) │
    │   nts       │  │            │  │                   │
    │             │  │ id         │  │  (via enrollment) │
    │ class_id    │  │ class_id   │  └──────────────────┘
    │ member_id ──┼──┤ lesson_date│
    │ enrolled_at │  │ title      │
    │ is_active   │  │ theme      │
    └─────────────┘  │ bible_text │
                     │ summary    │
                     │ teacher_id │
                     └─────┬──────┘
                           │ 1:N
              ┌────────────┼────────────┬────────────────┐
              │            │            │                 │
              ▼            ▼            ▼                 ▼
    ┌──────────────┐ ┌───────────┐ ┌──────────────┐ ┌──────────────┐
    │ebd_attendance│ │ebd_lesson │ │ebd_lesson    │ │ebd_lesson    │
    │              │ │_contents  │ │_activities   │ │_materials    │
    │ lesson_id    │ │           │ │              │ │              │
    │ member_id    │ │ lesson_id │ │ lesson_id    │ │ lesson_id    │
    │ status (P/A/J│ │ type      │ │ type         │ │ type         │
    │ bible        │ │ title     │ │ title        │ │ title        │
    │ magazine     │ │ body      │ │ description  │ │ url          │
    │ offering     │ │ image_url │ │ options      │ │ file_size    │
    └──────────────┘ │ sort_order│ │ correct_ans  │ └──────────────┘
                     └───────────┘ │ sort_order   │
                                   └──────┬───────┘
                                          │ 1:N
                                          ▼
                                   ┌──────────────────┐
                                   │ebd_activity      │
                                   │  _responses      │
                                   │                  │
                                   │ activity_id      │
                                   │ member_id        │
                                   │ response_text    │
                                   │ is_completed     │
                                   │ score            │
                                   │ teacher_feedback │
                                   └──────────────────┘
    
    ┌──────────────────┐
    │ebd_student_notes │
    │                  │
    │ church_id        │
    │ member_id ───────┤──► members (aluno)
    │ term_id ─────────┤──► ebd_terms
    │ note_type        │
    │ content          │
    │ is_private       │
    │ created_by ──────┤──► users (professor)
    └──────────────────┘
```

### 5.2 Resumo de Tabelas do Módulo EBD (Após Evolução)

| Tabela | Status | Campos | Propósito |
|--------|:------:|:------:|-----------|
| `ebd_terms` | ✅ Existente | 9 | Períodos/trimestres |
| `ebd_classes` | ✅ Existente | 12 | Turmas |
| `ebd_enrollments` | ✅ Existente | 7 | Matrículas (membro ↔ turma) |
| `ebd_lessons` | ✅ Existente | 12 | Aulas/lições |
| `ebd_attendances` | ✅ Existente | 11 | Frequência |
| `ebd_lesson_contents` | 🆕 Novo | 9 | Blocos de conteúdo enriquecido |
| `ebd_lesson_activities` | 🆕 Novo | 11 | Atividades pedagógicas |
| `ebd_activity_responses` | 🆕 Novo | 8 | Respostas/participação dos alunos |
| `ebd_lesson_materials` | 🆕 Novo | 9 | Materiais e recursos de apoio |
| `ebd_student_notes` | 🆕 Novo | 9 | Anotações do professor por aluno |
| `vw_ebd_student_profile` | 🆕 Nova view | — | Perfil consolidado do aluno |

---

## 6. Endpoints — Resumo Consolidado

### 6.1 Endpoints Existentes (16)

| # | Método | Rota | Status |
|---|--------|------|:------:|
| 1 | GET | `/api/v1/ebd/terms` | ✅ |
| 2 | GET | `/api/v1/ebd/terms/{id}` | ✅ |
| 3 | POST | `/api/v1/ebd/terms` | ✅ |
| 4 | PUT | `/api/v1/ebd/terms/{id}` | ✅ |
| 5 | GET | `/api/v1/ebd/classes` | ✅ |
| 6 | GET | `/api/v1/ebd/classes/{id}` | ✅ |
| 7 | POST | `/api/v1/ebd/classes` | ✅ |
| 8 | PUT | `/api/v1/ebd/classes/{id}` | ✅ |
| 9 | GET | `/api/v1/ebd/classes/{id}/enrollments` | ✅ |
| 10 | POST | `/api/v1/ebd/classes/{id}/enrollments` | ✅ |
| 11 | DELETE | `/api/v1/ebd/classes/{id}/enrollments/{eid}` | ✅ |
| 12 | GET | `/api/v1/ebd/lessons` | ✅ |
| 13 | GET | `/api/v1/ebd/lessons/{id}` | ✅ |
| 14 | POST | `/api/v1/ebd/lessons` | ✅ |
| 15 | POST | `/api/v1/ebd/lessons/{id}/attendance` | ✅ |
| 16 | GET | `/api/v1/ebd/lessons/{id}/attendance` | ✅ |
| 17 | GET | `/api/v1/ebd/classes/{id}/report` | ✅ |
| 18 | GET | `/api/v1/ebd/stats` | ✅ |

### 6.2 Novos Endpoints com Correções (4)

| # | Método | Rota | Funcionalidade | Ref |
|---|--------|------|----------------|-----|
| 19 | PUT | `/api/v1/ebd/lessons/{id}` | Atualizar aula | F1.2 |
| 20 | DELETE | `/api/v1/ebd/lessons/{id}` | Excluir aula | F1.2 |
| 21 | POST | `/api/v1/ebd/terms/{id}/clone-classes` | Clonar turmas entre trimestres | E7 |
| 22 | DELETE | `/api/v1/ebd/terms/{id}` | Excluir trimestre (se sem dados) | F1 |

### 6.3 Novos Endpoints — Conteúdo de Lições (6)

| # | Método | Rota | Funcionalidade | Ref |
|---|--------|------|----------------|-----|
| 23 | GET | `/api/v1/ebd/lessons/{id}/contents` | Listar blocos de conteúdo | E1 |
| 24 | POST | `/api/v1/ebd/lessons/{id}/contents` | Criar bloco de conteúdo | E1 |
| 25 | PUT | `/api/v1/ebd/lessons/{lid}/contents/{cid}` | Atualizar bloco | E1 |
| 26 | DELETE | `/api/v1/ebd/lessons/{lid}/contents/{cid}` | Remover bloco | E1 |
| 27 | PUT | `/api/v1/ebd/lessons/{id}/contents/reorder` | Reordenar blocos | E1 |
| 28 | POST | `/api/v1/ebd/lessons/{id}/contents/upload` | Upload de imagem | E1 |

### 6.4 Novos Endpoints — Atividades (7)

| # | Método | Rota | Funcionalidade | Ref |
|---|--------|------|----------------|-----|
| 29 | GET | `/api/v1/ebd/lessons/{id}/activities` | Listar atividades | E2 |
| 30 | POST | `/api/v1/ebd/lessons/{id}/activities` | Criar atividade | E2 |
| 31 | PUT | `/api/v1/ebd/lessons/{lid}/activities/{aid}` | Atualizar atividade | E2 |
| 32 | DELETE | `/api/v1/ebd/lessons/{lid}/activities/{aid}` | Remover atividade | E2 |
| 33 | GET | `/api/v1/ebd/activities/{aid}/responses` | Listar respostas | E2 |
| 34 | POST | `/api/v1/ebd/activities/{aid}/responses` | Registrar respostas (lote) | E2 |
| 35 | PUT | `/api/v1/ebd/activities/{aid}/responses/{rid}` | Atualizar resposta | E2 |

### 6.5 Novos Endpoints — Materiais (4)

| # | Método | Rota | Funcionalidade | Ref |
|---|--------|------|----------------|-----|
| 36 | GET | `/api/v1/ebd/lessons/{id}/materials` | Listar materiais | E4 |
| 37 | POST | `/api/v1/ebd/lessons/{id}/materials` | Adicionar material | E4 |
| 38 | POST | `/api/v1/ebd/lessons/{id}/materials/upload` | Upload de arquivo | E4 |
| 39 | DELETE | `/api/v1/ebd/lessons/{lid}/materials/{mid}` | Remover material | E4 |

### 6.6 Novos Endpoints — Perfil do Aluno (4)

| # | Método | Rota | Funcionalidade | Ref |
|---|--------|------|----------------|-----|
| 40 | GET | `/api/v1/ebd/students` | Listar alunos EBD | E3 |
| 41 | GET | `/api/v1/ebd/students/{member_id}` | Perfil do aluno | E3 |
| 42 | GET | `/api/v1/ebd/students/{member_id}/history` | Histórico de turmas | E3 |
| 43 | GET | `/api/v1/ebd/students/{member_id}/activities` | Atividades do aluno | E3 |

### 6.7 Novos Endpoints — Notas do Professor (4)

| # | Método | Rota | Funcionalidade | Ref |
|---|--------|------|----------------|-----|
| 44 | GET | `/api/v1/ebd/students/{mid}/notes` | Listar notas | E5 |
| 45 | POST | `/api/v1/ebd/students/{mid}/notes` | Criar nota | E5 |
| 46 | PUT | `/api/v1/ebd/students/{mid}/notes/{nid}` | Atualizar nota | E5 |
| 47 | DELETE | `/api/v1/ebd/students/{mid}/notes/{nid}` | Remover nota | E5 |

### 6.8 Novos Endpoints — Relatórios (4)

| # | Método | Rota | Funcionalidade | Ref |
|---|--------|------|----------------|-----|
| 48 | GET | `/api/v1/ebd/reports/term/{term_id}` | Relatório do trimestre | E6 |
| 49 | GET | `/api/v1/ebd/reports/term/{term_id}/ranking` | Ranking de turmas | E6 |
| 50 | GET | `/api/v1/ebd/reports/comparison` | Comparativo entre trimestres | E6 |
| 51 | GET | `/api/v1/ebd/reports/students/attendance` | Alerta de faltosos | E6 |

**Total: 18 endpoints existentes + 33 novos = 51 endpoints**

---

## 7. Frontend — Novas Telas

### 7.1 Resumo de Telas

| # | Rota | Tela | Status | Ref |
|---|------|------|:------:|-----|
| 1 | `/ebd` | `EbdOverviewScreen` | ✅ Existente (atualizar links) | — |
| 2 | `/ebd/terms` | `EbdTermListScreen` | ✅ Existente (+ edição) | F1.3 |
| 3 | `/ebd/classes` | `EbdClassListScreen` | ✅ Existente | — |
| 4 | `/ebd/classes/:id` | `EbdClassDetailScreen` | ✅ Existente (+ edição + relatório) | F1.3, F1.8 |
| 5 | `/ebd/lessons` | `EbdLessonListScreen` | ✅ Existente (+ edição/exclusão) | F1.2 |
| 6 | `/ebd/lessons/:id` | `EbdLessonDetailScreen` | 🆕 Nova | E1, E2, E4 |
| 7 | `/ebd/lessons/:id/attendance` | `EbdAttendanceScreen` | ✅ Existente (+ oferta + notas) | F1.4, F1.5 |
| 8 | `/ebd/students` | `EbdStudentListScreen` | 🆕 Nova | E3 |
| 9 | `/ebd/students/:id` | `EbdStudentProfileScreen` | 🆕 Nova | E3, E5 |
| 10 | `/ebd/reports` | `EbdReportScreen` | 🆕 Nova | E6 |
| 11 | `/ebd/classes/:id/report` | `EbdClassReportScreen` | 🆕 Nova | F1.8 |

### 7.2 Atualização do Overview

Adicionar dois novos cards de acesso rápido à `EbdOverviewScreen`:

| Card | Ícone | Label | Destino |
|------|-------|-------|---------|
| Alunos | 👤 `Icons.school` | "Alunos" / "Perfil dos alunos" | `/ebd/students` |
| Relatórios | 📊 `Icons.bar_chart` | "Relatórios" / "Análises e métricas" | `/ebd/reports` |

### 7.3 Atualização da Sidebar

Adicionar sub-itens ao menu EBD (expandable):

```
📖 EBD
  ├── 📋 Visão Geral     → /ebd
  ├── 📅 Trimestres       → /ebd/terms
  ├── 👥 Turmas           → /ebd/classes
  ├── 📝 Aulas            → /ebd/lessons
  ├── 🎓 Alunos           → /ebd/students
  └── 📊 Relatórios       → /ebd/reports
```

---

## 8. Plano de Implementação

### Fase 1 — Correções Críticas (Prioridade 🔴)

| # | Tarefa | Estimativa | Dependência |
|---|--------|:----------:|:-----------:|
| 1.1 | Corrigir bug de status EN→PT na frequência | 1h | — |
| 1.2 | Adicionar campo `notes` ao DTO de attendance | 30min | — |
| 1.3 | Adicionar campo de oferta na UI de frequência | 1h | — |
| 1.4 | Implementar update/delete de aulas (backend) | 3h | — |
| 1.5 | Implementar update/delete de aulas (frontend) | 2h | 1.4 |
| 1.6 | Adicionar edição de trimestres na UI | 2h | — |
| 1.7 | Adicionar edição de turmas na UI | 2h | — |
| 1.8 | Audit logging para EBD | 2h | — |

**Estimativa Fase 1: ~14 horas**

### Fase 2 — Conteúdo Enriquecido de Lições (Prioridade 🔴)

| # | Tarefa | Estimativa | Dependência |
|---|--------|:----------:|:-----------:|
| 2.1 | Migration: criar tabela `ebd_lesson_contents` | 1h | — |
| 2.2 | Backend: entity + DTO + service + handler | 4h | 2.1 |
| 2.3 | Backend: upload de imagens (actix-multipart) | 3h | 2.2 |
| 2.4 | Frontend: modelo + repositório + BLoC events/states | 2h | 2.2 |
| 2.5 | Frontend: `EbdLessonDetailScreen` | 6h | 2.4 |
| 2.6 | Frontend: componente de editor de blocos + reorder | 4h | 2.5 |

**Estimativa Fase 2: ~20 horas**

### Fase 3 — Atividades Pedagógicas (Prioridade 🔴)

| # | Tarefa | Estimativa | Dependência |
|---|--------|:----------:|:-----------:|
| 3.1 | Migration: criar tabelas `ebd_lesson_activities` + `ebd_activity_responses` | 1h | — |
| 3.2 | Backend: entities + DTOs + services + handlers | 5h | 3.1 |
| 3.3 | Frontend: modelos + repositório + BLoC | 2h | 3.2 |
| 3.4 | Frontend: seção de atividades na `EbdLessonDetailScreen` | 5h | 3.3 |
| 3.5 | Frontend: tela/dialog de respostas por atividade | 4h | 3.4 |

**Estimativa Fase 3: ~17 horas**

### Fase 4 — Perfil do Aluno + Notas (Prioridade 🔴)

| # | Tarefa | Estimativa | Dependência |
|---|--------|:----------:|:-----------:|
| 4.1 | Migration: criar view `vw_ebd_student_profile` + tabela `ebd_student_notes` | 1h | — |
| 4.2 | Backend: student DTOs + service + handler (4 endpoints) | 4h | 4.1 |
| 4.3 | Backend: notes DTOs + service + handler (4 endpoints) | 3h | 4.1 |
| 4.4 | Frontend: modelos + repositório + BLoC (students + notes) | 3h | 4.2, 4.3 |
| 4.5 | Frontend: `EbdStudentListScreen` | 4h | 4.4 |
| 4.6 | Frontend: `EbdStudentProfileScreen` | 6h | 4.4 |

**Estimativa Fase 4: ~21 horas**

### Fase 5 — Materiais + Relatórios + Clonagem (Prioridade 🟡)

| # | Tarefa | Estimativa | Dependência |
|---|--------|:----------:|:-----------:|
| 5.1 | Migration: criar tabela `ebd_lesson_materials` | 30min | — |
| 5.2 | Backend: materials entity + DTO + service + handler | 3h | 5.1 |
| 5.3 | Frontend: materiais na `EbdLessonDetailScreen` | 3h | 5.2 |
| 5.4 | Backend: relatórios avançados (4 endpoints) | 5h | — |
| 5.5 | Frontend: `EbdReportScreen` | 6h | 5.4 |
| 5.6 | Frontend: `EbdClassReportScreen` | 3h | — |
| 5.7 | Backend: clonagem de turmas | 2h | — |
| 5.8 | Frontend: UI de clonagem no término do trimestre | 2h | 5.7 |

**Estimativa Fase 5: ~25 horas**

### Resumo de Esforço

| Fase | Estimativa | Prioridade |
|------|:----------:|:----------:|
| Fase 1 — Correções | ~14h | 🔴 Alta |
| Fase 2 — Conteúdo de Lições | ~20h | 🔴 Alta |
| Fase 3 — Atividades | ~17h | 🔴 Alta |
| Fase 4 — Perfil do Aluno | ~21h | 🔴 Alta |
| Fase 5 — Materiais + Relatórios | ~25h | 🟡 Média |
| **Total** | **~97h** | |

---

## 9. Migration SQL Consolidada

```sql
-- Migration: EBD Module Evolution
-- Após a migration existente (20250101000000_initial.sql)

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
```

---

## 10. Compatibilidade e Coesão com o Projeto

### 10.1 Padrões Mantidos

| Padrão | Como é Mantido |
|--------|----------------|
| **Multi-tenancy** | Todas as novas tabelas que precisam de isolamento por igreja incluem `church_id`. Tabelas filhas herdam o contexto via foreign key (ex: `ebd_lesson_contents` herda via `lesson_id → ebd_lessons.church_id`) |
| **UUID como PK** | Todas as novas tabelas seguem `id UUID PRIMARY KEY DEFAULT uuid_generate_v4()` |
| **Timestamps** | Todas as novas tabelas possuem `created_at` + `updated_at` com triggers |
| **Cascade delete** | Tabelas filhas usam `ON DELETE CASCADE` no parent (contents, activities, responses, materials) |
| **Clean Architecture** | Novos services seguem o padrão: Entity → DTO → Service → Handler |
| **Cache Redis** | Novos endpoints de stats/relatórios usam `CacheService` com TTL de 120s |
| **Audit Log** | Operações de escrita integram `AuditService::log()` |
| **BLoC Pattern** | Frontend segue Events → States → BLoC com padrão emit Loading → call repo → emit Loaded/Error |
| **API Response** | Respostas seguem `ApiResponse<T>` com `success`, `data`, `meta` (paginação) |
| **Permissões** | Endpoints usam `ebd:read` (leitura) e `ebd:write` (escrita), consistente com RBAC existente |

### 10.2 Integração com Módulos Existentes

| Integração | Descrição |
|------------|-----------|
| **EBD → Membros** | Alunos e professores são `members`. A view `vw_ebd_student_profile` faz JOIN com `members`. O frontend busca membros via `MemberRepository` existente |
| **EBD → Financeiro** | Ofertas da EBD (campo `offering_amount` em `ebd_attendances`) podem ser consolidadas como lançamento de receita via integração manual ou botão "Registrar ofertas no financeiro" |
| **EBD → Dashboard** | O endpoint `GET /api/v1/ebd/stats` (já existente) pode ser expandido para incluir dados das novas funcionalidades |
| **EBD → Relatórios** | A `ReportsScreen` existente já tem seção de EBD — novos dados serão adicionados lá |

### 10.3 Não Alterações

| Item | Motivo |
|------|--------|
| Tabela `members` | Nenhuma coluna adicionada. O perfil "Aluno EBD" é uma view que consulta `members` via JOIN |
| Tabela `ebd_enrollments` | Mantida. A matrícula continua sendo `class_id + member_id` |
| Tabela `ebd_attendances` | Nenhuma coluna adicionada. Frequência mantém o schema atual |
| Tabela `ebd_lessons` | Nenhuma coluna adicionada. Conteúdo enriquecido fica em tabela separada (`ebd_lesson_contents`) |
| Endpoints existentes | Nenhum endpoint alterado. Apenas novos adicionados |

---

## 11. Regras de Negócio — Complemento

Regras adicionais para as novas funcionalidades. As regras existentes (RN-EBD-001 a RN-EBD-007) permanecem válidas.

| Código | Regra | Descrição |
|--------|-------|-----------|
| RN-EBD-008 | Conteúdo de Lição | Cada lição pode ter até 20 blocos de conteúdo. Imagens limitadas a 5 MB (jpg, png, webp). A exclusão da lição remove todos os blocos em cascata |
| RN-EBD-009 | Atividades | Cada lição pode ter até 10 atividades. `multiple_choice` exige 2-6 opções. `correct_answer` visível apenas para `ebd:write`. Atividades editáveis dentro do período de 7 dias (RN-EBD-004) |
| RN-EBD-010 | Respostas | Um aluno pode atualizar sua resposta (UPSERT). A nota é opcional (0-10). O feedback do professor é privado (apenas `ebd:write`) |
| RN-EBD-011 | Perfil do Aluno | O perfil é uma projeção de `members`. Um membro só aparece como aluno se tiver pelo menos 1 matrícula. Frequência calculada sobre total de aulas das turmas matriculadas |
| RN-EBD-012 | Notas do Professor | Notas privadas visíveis apenas para `ebd:write`. Apenas o autor pode editar/excluir. Mantidas mesmo após saída do aluno da turma |
| RN-EBD-013 | Materiais | Até 10 materiais por lição. Uploads limitados a 10 MB. Formatos aceitos: pdf, doc, docx, jpg, png, webp, mp3, mp4. Exclusão da lição remove materiais em cascata |
| RN-EBD-014 | Clonagem | Clona apenas turmas ativas. Se `include_enrollments = true`, apenas matrículas ativas. Turmas duplicadas (mesmo nome no destino) são ignoradas |
| RN-EBD-015 | Upload de Arquivos | Arquivos são armazenados no filesystem local (path: `/uploads/ebd/{church_id}/{lesson_id}/`) com URL servida como `GET /uploads/ebd/...`. Em produção, migrar para S3/MinIO |

---

## 12. Glossário Adicional

| Termo | Definição |
|-------|-----------|
| **Bloco de conteúdo** | Unidade de conteúdo dentro de uma lição (texto, imagem, referência bíblica, nota) |
| **Atividade** | Exercício pedagógico vinculado a uma lição (pergunta, completar, dinâmica) |
| **Resposta** | Registro da participação do aluno em uma atividade |
| **Perfil do Aluno** | View consolidada de dados pessoais + métricas EBD de um membro matriculado |
| **Nota do Professor** | Anotação privada sobre um aluno, vinculada a um trimestre ou geral |
| **Clonagem de turmas** | Cópia de turmas (e opcionalmente matrículas) de um trimestre para outro |
| **Material de apoio** | Recurso externo vinculado a uma lição (documento, vídeo, áudio, link) |

---

> **Nota:** Este documento complementa a documentação existente (docs 01-08) e deve ser referenciado junto ao `07-andamento-do-projeto.md` durante a implementação. As estimativas de esforço pressupõem familiaridade com o codebase e os padrões já estabelecidos.

*Documento de evolução — versão 1.0*
