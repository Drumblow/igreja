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
}

#[derive(Debug, Deserialize)]
pub struct EbdClassFilter {
    pub term_id: Option<Uuid>,
    pub is_active: Option<bool>,
    pub teacher_id: Option<Uuid>,
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
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateEbdAttendanceRequest {
    pub attendances: Vec<AttendanceRecord>,
}
