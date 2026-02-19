use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

// ==========================================
// User DTOs
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateUserRequest {
    #[validate(email(message = "E-mail inválido"))]
    pub email: String,
    #[validate(length(min = 8, message = "Senha deve ter no mínimo 8 caracteres"))]
    pub password: String,
    pub role_id: Uuid,
    pub member_id: Option<Uuid>,
    pub is_active: Option<bool>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateUserRequest {
    #[validate(email(message = "E-mail inválido"))]
    pub email: Option<String>,
    #[validate(length(min = 8, message = "Senha deve ter no mínimo 8 caracteres"))]
    pub password: Option<String>,
    pub role_id: Option<Uuid>,
    pub member_id: Option<Uuid>,
    pub is_active: Option<bool>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct UserSummary {
    pub id: Uuid,
    pub email: String,
    pub role_name: String,
    pub role_display_name: String,
    pub member_name: Option<String>,
    pub is_active: bool,
    pub email_verified: bool,
    pub last_login_at: Option<chrono::DateTime<chrono::Utc>>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

// ==========================================
// Role DTOs
// ==========================================

#[allow(dead_code)]
#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateRoleRequest {
    #[validate(length(min = 2, max = 50, message = "Nome deve ter entre 2 e 50 caracteres"))]
    pub name: String,
    #[validate(length(min = 2, max = 100))]
    pub display_name: String,
    pub description: Option<String>,
    pub permissions: Vec<String>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateRoleRequest {
    pub display_name: Option<String>,
    pub description: Option<String>,
    pub permissions: Option<Vec<String>>,
}
