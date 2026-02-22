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
/// Supports wildcard matching: "members:*" matches "members:create", "members:update", etc.
pub fn require_permission(claims: &Claims, permission: &str) -> Result<(), AppError> {
    // super_admin always passes
    if claims.role == "super_admin" {
        return Ok(());
    }

    // Global wildcard (e.g., permissions: ["*"])
    if claims.permissions.contains(&"*".to_string()) {
        return Ok(());
    }

    // Exact match
    if claims.permissions.contains(&permission.to_string()) {
        return Ok(());
    }

    // Wildcard match: "members:*" should match "members:create"
    let parts: Vec<&str> = permission.split(':').collect();
    if parts.len() == 2 {
        let wildcard = format!("{}:*", parts[0]);
        if claims.permissions.contains(&wildcard) {
            return Ok(());
        }
    }

    Err(AppError::Forbidden(
        "Permissão insuficiente para esta ação".into(),
    ))
}

/// Returns the list of allowed congregation UUIDs based on JWT scope,
/// or None if the user has global access (can see all congregations).
pub fn get_allowed_congregations(claims: &Claims) -> Option<Vec<uuid::Uuid>> {
    match claims.scope_type.as_str() {
        "global" => None, // No restriction — admin sees everything
        "congregation" => {
            Some(
                claims
                    .congregation_ids
                    .iter()
                    .filter_map(|id| id.parse::<uuid::Uuid>().ok())
                    .collect(),
            )
        }
        "self" => {
            // Self-scope: return primary congregation (members see their own congregation)
            claims
                .primary_congregation_id
                .as_ref()
                .and_then(|id| id.parse::<uuid::Uuid>().ok())
                .map(|id| vec![id])
                .or(Some(vec![]))
        }
        _ => Some(vec![]), // Unknown scope = no access
    }
}

/// Checks if the user can access data from a specific congregation.
pub fn can_access_congregation(claims: &Claims, congregation_id: Option<uuid::Uuid>) -> bool {
    match claims.scope_type.as_str() {
        "global" => true,
        "congregation" => match congregation_id {
            None => false, // NULL congregation = Sede/Geral — denied for scoped users
            Some(cid) => claims.congregation_ids.contains(&cid.to_string()),
        },
        "self" => match (congregation_id, &claims.primary_congregation_id) {
            (Some(cid), Some(pcid)) => cid.to_string() == *pcid,
            _ => false,
        },
        _ => false,
    }
}

/// Returns the member_id linked to this user (from JWT), if any.
pub fn get_member_id(claims: &Claims) -> Option<uuid::Uuid> {
    claims
        .member_id
        .as_ref()
        .and_then(|id| id.parse::<uuid::Uuid>().ok())
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
