use chrono::NaiveDate;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

/// Summary for student list
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdStudentSummary {
    pub member_id: Uuid,
    pub church_id: Uuid,
    pub full_name: String,
    pub birth_date: Option<NaiveDate>,
    pub gender: String,
    pub phone_primary: Option<String>,
    pub photo_url: Option<String>,
    pub member_status: String,
    pub active_enrollments: Option<i64>,
    pub total_enrollments: Option<i64>,
    pub terms_attended: Option<i64>,
    pub total_present: Option<i64>,
    pub total_absent: Option<i64>,
    pub total_justified: Option<i64>,
    pub total_attendance_records: Option<i64>,
    pub attendance_percentage: Option<Decimal>,
    pub times_brought_bible: Option<i64>,
    pub times_brought_magazine: Option<i64>,
    pub total_offerings: Option<Decimal>,
}

/// Enrollment history item
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdEnrollmentHistory {
    pub term_name: String,
    pub class_name: String,
    pub enrolled_at: NaiveDate,
    pub left_at: Option<NaiveDate>,
    pub is_active: bool,
    pub lessons_attended: Option<i64>,
    pub total_lessons: Option<i64>,
}
