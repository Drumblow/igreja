use chrono::NaiveDate;
use rust_decimal::Decimal;
use serde::Deserialize;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

// ==========================================
// EBD Terms (Períodos/Trimestres)
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateEbdTermRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: String,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub theme: Option<String>,
    pub magazine_title: Option<String>,
    pub congregation_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateEbdTermRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: Option<String>,
    pub start_date: Option<NaiveDate>,
    pub end_date: Option<NaiveDate>,
    pub theme: Option<String>,
    pub magazine_title: Option<String>,
    pub is_active: Option<bool>,
    pub congregation_id: Option<Option<Uuid>>,
}

// ==========================================
// EBD Classes (Turmas)
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateEbdClassRequest {
    pub term_id: Uuid,
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: String,
    pub age_range_start: Option<i32>,
    pub age_range_end: Option<i32>,
    pub room: Option<String>,
    pub max_capacity: Option<i32>,
    pub teacher_id: Option<Uuid>,
    pub aux_teacher_id: Option<Uuid>,
    pub congregation_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateEbdClassRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: Option<String>,
    pub age_range_start: Option<i32>,
    pub age_range_end: Option<i32>,
    pub room: Option<String>,
    pub max_capacity: Option<i32>,
    pub teacher_id: Option<Uuid>,
    pub aux_teacher_id: Option<Uuid>,
    pub is_active: Option<bool>,
    pub congregation_id: Option<Option<Uuid>>,
}

#[derive(Debug, Deserialize)]
pub struct EbdClassFilter {
    pub term_id: Option<Uuid>,
    pub is_active: Option<bool>,
    pub teacher_id: Option<Uuid>,
    pub congregation_id: Option<Uuid>,
}

// ==========================================
// EBD Enrollments (Matrículas)
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateEbdEnrollmentRequest {
    pub member_id: Uuid,
}

// ==========================================
// EBD Lessons (Aulas)
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateEbdLessonRequest {
    pub class_id: Uuid,
    pub lesson_date: NaiveDate,
    pub lesson_number: Option<i32>,
    pub title: Option<String>,
    pub theme: Option<String>,
    pub bible_text: Option<String>,
    pub summary: Option<String>,
    pub teacher_id: Option<Uuid>,
    pub materials_used: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct EbdLessonFilter {
    pub class_id: Option<Uuid>,
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
}

// ==========================================
// EBD Attendance (Frequência)
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct AttendanceRecord {
    pub member_id: Uuid,
    pub status: String,
    pub brought_bible: Option<bool>,
    pub brought_magazine: Option<bool>,
    pub offering_amount: Option<Decimal>,
    pub is_visitor: Option<bool>,
    pub visitor_name: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateEbdAttendanceRequest {
    pub attendances: Vec<AttendanceRecord>,
}

// ==========================================
// EBD Lesson Update (F1.2)
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateEbdLessonRequest {
    pub lesson_date: Option<NaiveDate>,
    pub lesson_number: Option<i32>,
    pub title: Option<String>,
    pub theme: Option<String>,
    pub bible_text: Option<String>,
    pub summary: Option<String>,
    pub teacher_id: Option<Uuid>,
    pub materials_used: Option<String>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct DeleteLessonParams {
    pub force: Option<bool>,
}

// ==========================================
// E1: Conteúdo Enriquecido de Lições
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateLessonContentRequest {
    pub content_type: String,
    #[validate(length(max = 200))]
    pub title: Option<String>,
    pub body: Option<String>,
    #[validate(length(max = 500))]
    pub image_url: Option<String>,
    #[validate(length(max = 300))]
    pub image_caption: Option<String>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateLessonContentRequest {
    pub content_type: Option<String>,
    #[validate(length(max = 200))]
    pub title: Option<String>,
    pub body: Option<String>,
    #[validate(length(max = 500))]
    pub image_url: Option<String>,
    #[validate(length(max = 300))]
    pub image_caption: Option<String>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct ReorderContentsRequest {
    pub content_ids: Vec<Uuid>,
}

// ==========================================
// E2: Atividades por Lição
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateLessonActivityRequest {
    pub activity_type: String,
    #[validate(length(min = 3, max = 300))]
    pub title: String,
    pub description: Option<String>,
    pub options: Option<serde_json::Value>,
    pub correct_answer: Option<String>,
    #[validate(length(max = 200))]
    pub bible_reference: Option<String>,
    pub is_required: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateLessonActivityRequest {
    pub activity_type: Option<String>,
    #[validate(length(min = 3, max = 300))]
    pub title: Option<String>,
    pub description: Option<String>,
    pub options: Option<serde_json::Value>,
    pub correct_answer: Option<String>,
    #[validate(length(max = 200))]
    pub bible_reference: Option<String>,
    pub is_required: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct ActivityResponseRecord {
    pub member_id: Uuid,
    pub response_text: Option<String>,
    pub is_completed: bool,
    pub score: Option<i16>,
    pub teacher_feedback: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateActivityResponsesRequest {
    pub responses: Vec<ActivityResponseRecord>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateActivityResponseRequest {
    pub response_text: Option<String>,
    pub is_completed: Option<bool>,
    pub score: Option<i16>,
    pub teacher_feedback: Option<String>,
}

// ==========================================
// E4: Materiais e Recursos da Lição
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateLessonMaterialRequest {
    pub material_type: String,
    #[validate(length(min = 2, max = 200))]
    pub title: String,
    #[validate(length(max = 500))]
    pub description: Option<String>,
    #[validate(length(min = 1, max = 500))]
    pub url: String,
    pub file_size_bytes: Option<i64>,
    pub mime_type: Option<String>,
}

// ==========================================
// E3: Perfil do Aluno EBD
// ==========================================

#[derive(Debug, Deserialize)]
pub struct EbdStudentFilter {
    pub term_id: Option<Uuid>,
    pub class_id: Option<Uuid>,
    pub search: Option<String>,
    pub min_attendance: Option<Decimal>,
    pub max_attendance: Option<Decimal>,
}

// ==========================================
// E5: Anotações do Professor por Aluno
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateStudentNoteRequest {
    pub term_id: Option<Uuid>,
    pub note_type: String,
    #[validate(length(max = 200))]
    pub title: Option<String>,
    #[validate(length(min = 1))]
    pub content: String,
    pub is_private: Option<bool>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateStudentNoteRequest {
    pub note_type: Option<String>,
    #[validate(length(max = 200))]
    pub title: Option<String>,
    #[validate(length(min = 1))]
    pub content: Option<String>,
    pub is_private: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct StudentNoteFilter {
    pub term_id: Option<Uuid>,
    pub note_type: Option<String>,
}

// ==========================================
// E7: Clonagem de Turmas
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CloneClassesRequest {
    pub source_term_id: Uuid,
    pub include_enrollments: Option<bool>,
}

// ==========================================
// E6: Relatórios Avançados
// ==========================================

#[derive(Debug, Deserialize)]
pub struct TermComparisonQuery {
    pub term_ids: String, // comma-separated UUIDs
}
