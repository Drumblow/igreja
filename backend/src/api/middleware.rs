use crate::application::dto::Claims;
use crate::config::AppConfig;
use crate::errors::AppError;
use jsonwebtoken::{decode, DecodingKey, Validation};

/// Extracts and validates JWT from Authorization header.
pub fn extract_claims_from_header(auth_header: &str, config: &AppConfig) -> Result<Claims, AppError> {
    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or_else(|| AppError::Unauthorized("Formato de token inválido".into()))?;

    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(config.jwt_secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|e| AppError::Unauthorized(format!("Token inválido: {e}")))?;

    Ok(token_data.claims)
}

/// Actix-web handler-level auth. Used in handlers to extract claims.
pub async fn auth_middleware(
    req: actix_web::HttpRequest,
    config: actix_web::web::Data<AppConfig>,
) -> Result<Claims, AppError> {
    let auth_header = req
        .headers()
        .get("Authorization")
        .and_then(|v: &actix_web::http::header::HeaderValue| v.to_str().ok())
        .ok_or_else(|| AppError::Unauthorized("Token de autenticação não fornecido".into()))?;

    extract_claims_from_header(auth_header, &config)
}

/// Verifies user has the required permission.
pub fn require_permission(claims: &Claims, permission: &str) -> Result<(), AppError> {
    if claims.role == "super_admin" || claims.permissions.contains(&permission.to_string()) {
        Ok(())
    } else {
        Err(AppError::Forbidden(
            "Permissão insuficiente para esta ação".into(),
        ))
    }
}

/// Gets the church_id from claims as UUID.
pub fn get_church_id(claims: &Claims) -> Result<uuid::Uuid, AppError> {
    claims
        .church_id
        .parse::<uuid::Uuid>()
        .map_err(|_| AppError::Unauthorized("church_id inválido no token".into()))
}

/// Gets the user_id from claims as UUID.
pub fn get_user_id(claims: &Claims) -> Result<uuid::Uuid, AppError> {
    claims
        .sub
        .parse::<uuid::Uuid>()
        .map_err(|_| AppError::Unauthorized("user_id inválido no token".into()))
}
