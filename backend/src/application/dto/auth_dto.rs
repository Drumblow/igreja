use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use validator::Validate;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct LoginRequest {
    #[validate(email(message = "E-mail inválido"))]
    pub email: String,
    #[validate(length(min = 8, message = "Senha deve ter no mínimo 8 caracteres"))]
    pub password: String,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct LoginResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
    pub user: AuthUser,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AuthUser {
    pub id: uuid::Uuid,
    pub email: String,
    pub role: String,
    pub church_id: uuid::Uuid,
    pub church_name: String,
    // New fields for congregation scope
    pub member_id: Option<uuid::Uuid>,
    pub member_name: Option<String>,
    pub scope_type: String,
    pub congregation_ids: Vec<uuid::Uuid>,
    pub primary_congregation_id: Option<uuid::Uuid>,
    pub primary_congregation_name: Option<String>,
    pub force_password_change: bool,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct RefreshResponse {
    pub access_token: String,
    pub expires_in: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub church_id: String,
    pub role: String,
    pub permissions: Vec<String>,

    // Congregation scope fields
    #[serde(default = "default_scope_global")]
    pub scope_type: String, // "global", "congregation", "self"
    #[serde(default)]
    pub congregation_ids: Vec<String>, // UUIDs of allowed congregations
    #[serde(default)]
    pub primary_congregation_id: Option<String>, // Default congregation (is_primary)
    #[serde(default)]
    pub member_id: Option<String>, // Linked member ID (for self scope)

    pub exp: i64,
    pub iat: i64,
}

fn default_scope_global() -> String {
    "global".to_string()
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct ForgotPasswordRequest {
    #[validate(email(message = "E-mail inválido"))]
    pub email: String,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct ResetPasswordRequest {
    pub token: String,
    #[validate(length(min = 8, message = "Senha deve ter no mínimo 8 caracteres"))]
    pub new_password: String,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct ChangePasswordRequest {
    #[validate(length(min = 6, message = "Senha deve ter no mínimo 6 caracteres"))]
    pub new_password: String,
    #[validate(length(min = 6, message = "Confirmação deve ter no mínimo 6 caracteres"))]
    pub confirm_password: String,
}
