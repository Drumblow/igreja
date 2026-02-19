use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use validator::Validate;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateMemberRequest {
    #[validate(length(min = 3, max = 200, message = "Nome deve ter entre 3 e 200 caracteres"))]
    pub full_name: String,
    pub social_name: Option<String>,
    pub birth_date: Option<NaiveDate>,
    #[validate(length(min = 1, message = "Sexo é obrigatório"))]
    pub gender: String,
    pub marital_status: Option<String>,
    pub cpf: Option<String>,
    pub rg: Option<String>,
    #[validate(email(message = "E-mail inválido"))]
    pub email: Option<String>,
    pub phone_primary: Option<String>,
    pub phone_secondary: Option<String>,

    // Address
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,

    // Additional
    pub profession: Option<String>,
    pub workplace: Option<String>,
    pub birthplace_city: Option<String>,
    pub birthplace_state: Option<String>,
    pub nationality: Option<String>,
    pub education_level: Option<String>,
    pub blood_type: Option<String>,

    // Ecclesiastical
    pub conversion_date: Option<NaiveDate>,
    pub water_baptism_date: Option<NaiveDate>,
    pub spirit_baptism_date: Option<NaiveDate>,
    pub origin_church: Option<String>,
    pub entry_date: Option<NaiveDate>,
    pub entry_type: Option<String>,
    pub role_position: Option<String>,
    pub ordination_date: Option<NaiveDate>,

    pub status: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateMemberRequest {
    #[validate(length(min = 3, max = 200, message = "Nome deve ter entre 3 e 200 caracteres"))]
    pub full_name: Option<String>,
    pub social_name: Option<String>,
    pub birth_date: Option<NaiveDate>,
    pub gender: Option<String>,
    pub marital_status: Option<String>,
    pub cpf: Option<String>,
    pub rg: Option<String>,
    pub email: Option<String>,
    pub phone_primary: Option<String>,
    pub phone_secondary: Option<String>,

    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,

    pub profession: Option<String>,
    pub workplace: Option<String>,
    pub birthplace_city: Option<String>,
    pub birthplace_state: Option<String>,
    pub nationality: Option<String>,
    pub education_level: Option<String>,
    pub blood_type: Option<String>,

    pub conversion_date: Option<NaiveDate>,
    pub water_baptism_date: Option<NaiveDate>,
    pub spirit_baptism_date: Option<NaiveDate>,
    pub origin_church: Option<String>,
    pub entry_date: Option<NaiveDate>,
    pub entry_type: Option<String>,
    pub role_position: Option<String>,
    pub ordination_date: Option<NaiveDate>,

    pub status: Option<String>,
    pub status_reason: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct MemberFilter {
    pub status: Option<String>,
    pub gender: Option<String>,
    pub marital_status: Option<String>,
    pub role_position: Option<String>,
    #[allow(dead_code)]
    pub ministry_id: Option<uuid::Uuid>,
    pub birth_month: Option<i32>,
    pub age_min: Option<i32>,
    pub age_max: Option<i32>,
    pub neighborhood: Option<String>,
    pub entry_date_from: Option<NaiveDate>,
    pub entry_date_to: Option<NaiveDate>,
}

#[derive(Debug, Serialize, ToSchema)]
#[allow(dead_code)]
pub struct MemberStats {
    pub total_active: i64,
    pub total_inactive: i64,
    pub by_gender: std::collections::HashMap<String, i64>,
    pub by_marital_status: std::collections::HashMap<String, i64>,
    pub by_role_position: std::collections::HashMap<String, i64>,
    pub new_members_this_month: i64,
    pub new_members_this_year: i64,
}
