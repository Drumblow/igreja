use actix_web::{post, put, web, HttpRequest, HttpResponse};
use sqlx::{FromRow, PgPool};
use validator::Validate;

use crate::api::middleware;
use crate::api::response::ApiResponse;
use crate::application::dto::{
    ChangePasswordRequest, ForgotPasswordRequest, LoginRequest, RefreshRequest,
    ResetPasswordRequest,
};
use crate::application::services::AuthService;
use crate::config::AppConfig;
use crate::errors::AppError;

#[derive(Debug, FromRow)]
struct RefreshTokenRow {
    id: uuid::Uuid,
    user_id: uuid::Uuid,
    token_hash: String,
    #[allow(dead_code)]
    expires_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, FromRow)]
struct UserRoleRow {
    id: uuid::Uuid,
    church_id: uuid::Uuid,
    role_name: String,
    role_permissions: serde_json::Value,
    member_id: Option<uuid::Uuid>,
}

#[derive(Debug, FromRow)]
struct UserProfileRow {
    id: uuid::Uuid,
    email: String,
    church_id: uuid::Uuid,
    is_active: bool,
    email_verified: bool,
    last_login_at: Option<chrono::DateTime<chrono::Utc>>,
    created_at: chrono::DateTime<chrono::Utc>,
    role_name: String,
    role_display_name: String,
    church_name: String,
}

/// Login
#[utoipa::path(
    post,
    path = "/api/v1/auth/login",
    request_body = LoginRequest,
    responses(
        (status = 200, description = "Login successful"),
        (status = 401, description = "Invalid credentials")
    )
)]
#[post("/api/v1/auth/login")]
pub async fn login(
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<LoginRequest>,
) -> Result<HttpResponse, AppError> {
    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let response = AuthService::login(pool.get_ref(), &body, &config).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(response)))
}

/// Refresh token
#[utoipa::path(
    post,
    path = "/api/v1/auth/refresh",
    request_body = RefreshRequest,
    responses(
        (status = 200, description = "Token refreshed"),
        (status = 401, description = "Invalid refresh token")
    )
)]
#[post("/api/v1/auth/refresh")]
pub async fn refresh_token(
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<RefreshRequest>,
) -> Result<HttpResponse, AppError> {
    // Find the refresh token in DB
    let stored_tokens = sqlx::query_as::<_, RefreshTokenRow>(
        r#"
        SELECT rt.id, rt.user_id, rt.token_hash, rt.expires_at
        FROM refresh_tokens rt
        WHERE rt.revoked_at IS NULL
          AND rt.expires_at > NOW()
        ORDER BY rt.created_at DESC
        LIMIT 10
        "#,
    )
    .fetch_all(pool.get_ref())
    .await?;

    let mut matched_user_id = None;
    let mut matched_token_id = None;

    for token_row in &stored_tokens {
        if AuthService::verify_password(&body.refresh_token, &token_row.token_hash)? {
            matched_user_id = Some(token_row.user_id);
            matched_token_id = Some(token_row.id);
            break;
        }
    }

    let user_id = matched_user_id
        .ok_or_else(|| AppError::Unauthorized("Refresh token inválido".into()))?;
    let token_id = matched_token_id.unwrap();

    // Revoke old token
    sqlx::query("UPDATE refresh_tokens SET revoked_at = NOW() WHERE id = $1")
        .bind(token_id)
        .execute(pool.get_ref())
        .await?;

    // Get user info for new access token (including member_id for scope)
    let user = sqlx::query_as::<_, UserRoleRow>(
        r#"
        SELECT u.id, u.church_id, r.name as role_name, r.permissions as role_permissions,
               u.member_id
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.id = $1 AND u.is_active = true
        "#,
    )
    .bind(user_id)
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::Unauthorized("Usuário não encontrado ou desativado".into()))?;

    let permissions: Vec<String> =
        serde_json::from_value(user.role_permissions).unwrap_or_default();

    // Re-determine scope on refresh (congregation assignments may have changed)
    let scope = AuthService::determine_scope_public(
        pool.get_ref(),
        user.id,
        &user.role_name,
        user.member_id,
    )
    .await;

    let access_token = AuthService::generate_access_token(
        user.id,
        user.church_id,
        &user.role_name,
        permissions,
        &scope.0,
        scope.1,
        scope.2,
        user.member_id,
        &config,
    )?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(
        crate::application::dto::RefreshResponse {
            access_token,
            expires_in: config.jwt_access_expiry,
        },
    )))
}

/// Logout (revoke refresh token)
#[utoipa::path(
    post,
    path = "/api/v1/auth/logout",
    responses(
        (status = 200, description = "Logged out"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/auth/logout")]
pub async fn logout(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let user_id = middleware::get_user_id(&claims)?;

    // Revoke all refresh tokens for this user
    sqlx::query(
        "UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL",
    )
    .bind(user_id)
    .execute(pool.get_ref())
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({"message": "Logout realizado com sucesso"}))))
}

/// Get current user profile
#[utoipa::path(
    get,
    path = "/api/v1/auth/me",
    responses(
        (status = 200, description = "User profile"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[actix_web::get("/api/v1/auth/me")]
pub async fn me(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let user_id = middleware::get_user_id(&claims)?;

    let user = sqlx::query_as::<_, UserProfileRow>(
        r#"
        SELECT u.id, u.email, u.church_id, u.is_active, u.email_verified,
               u.last_login_at, u.created_at,
               r.name as role_name, r.display_name as role_display_name,
               c.name as church_name
        FROM users u
        JOIN roles r ON u.role_id = r.id
        JOIN churches c ON u.church_id = c.id
        WHERE u.id = $1
        "#,
    )
    .bind(user_id)
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::not_found("Usuário"))?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({
        "id": user.id,
        "email": user.email,
        "church_id": user.church_id,
        "church_name": user.church_name,
        "role": user.role_name,
        "role_display_name": user.role_display_name,
        "is_active": user.is_active,
        "email_verified": user.email_verified,
        "last_login_at": user.last_login_at,
        "created_at": user.created_at
    }))))
}

/// Forgot password — sends reset token to user email
#[utoipa::path(
    post,
    path = "/api/v1/auth/forgot-password",
    request_body = ForgotPasswordRequest,
    responses(
        (status = 200, description = "Reset instructions sent (always returns success for security)")
    )
)]
#[post("/api/v1/auth/forgot-password")]
pub async fn forgot_password(
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<ForgotPasswordRequest>,
) -> Result<HttpResponse, AppError> {
    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    // Always return success to prevent email enumeration
    let message = "Se o e-mail estiver cadastrado, você receberá instruções para redefinir sua senha.";

    // Look up user
    let user = sqlx::query_as::<_, (uuid::Uuid, String)>(
        "SELECT id, email FROM users WHERE email = $1 AND is_active = true",
    )
    .bind(&body.email)
    .fetch_optional(pool.get_ref())
    .await?;

    if let Some((user_id, _email)) = user {
        // Invalidate any existing reset tokens for this user
        sqlx::query(
            "UPDATE password_reset_tokens SET used_at = NOW() WHERE user_id = $1 AND used_at IS NULL",
        )
        .bind(user_id)
        .execute(pool.get_ref())
        .await?;

        // Generate a secure 6-char alphanumeric token (easy to type from an email)
        let raw_token = AuthService::generate_reset_token();
        let token_hash = AuthService::hash_password(&raw_token)?;
        let expires_at = chrono::Utc::now() + chrono::Duration::minutes(30);

        sqlx::query(
            "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)",
        )
        .bind(user_id)
        .bind(&token_hash)
        .bind(expires_at)
        .execute(pool.get_ref())
        .await?;

        // In production, send email via lettre/SMTP.
        // For development, log the token so it can be used for testing.
        if config.smtp_host.is_empty() {
            tracing::warn!("SMTP not configured — reset token for {}: {}", &body.email, &raw_token);
        } else {
            AuthService::send_reset_email(&body.email, &raw_token, &config).await.ok();
        }
    }

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(serde_json::json!({}), message)))
}

/// Reset password using token
#[utoipa::path(
    post,
    path = "/api/v1/auth/reset-password",
    request_body = ResetPasswordRequest,
    responses(
        (status = 200, description = "Password reset successfully"),
        (status = 400, description = "Invalid or expired token")
    )
)]
#[post("/api/v1/auth/reset-password")]
pub async fn reset_password(
    pool: web::Data<PgPool>,
    body: web::Json<ResetPasswordRequest>,
) -> Result<HttpResponse, AppError> {
    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    // Find non-expired, unused reset tokens
    let tokens = sqlx::query_as::<_, (uuid::Uuid, uuid::Uuid, String)>(
        r#"
        SELECT id, user_id, token_hash
        FROM password_reset_tokens
        WHERE used_at IS NULL
          AND expires_at > NOW()
        ORDER BY created_at DESC
        LIMIT 20
        "#,
    )
    .fetch_all(pool.get_ref())
    .await?;

    let mut matched_token_id: Option<uuid::Uuid> = None;
    let mut matched_user_id: Option<uuid::Uuid> = None;

    for (token_id, user_id, hash) in &tokens {
        if AuthService::verify_password(&body.token, hash)? {
            matched_token_id = Some(*token_id);
            matched_user_id = Some(*user_id);
            break;
        }
    }

    let token_id = matched_token_id
        .ok_or_else(|| AppError::validation("Token inválido ou expirado"))?;
    let user_id = matched_user_id.unwrap();

    // Mark token as used
    sqlx::query("UPDATE password_reset_tokens SET used_at = NOW() WHERE id = $1")
        .bind(token_id)
        .execute(pool.get_ref())
        .await?;

    // Hash new password and update user
    let new_hash = AuthService::hash_password(&body.new_password)?;
    sqlx::query(
        "UPDATE users SET password_hash = $1, failed_attempts = 0, locked_until = NULL WHERE id = $2",
    )
    .bind(&new_hash)
    .bind(user_id)
    .execute(pool.get_ref())
    .await?;

    // Revoke all refresh tokens for security
    sqlx::query(
        "UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL",
    )
    .bind(user_id)
    .execute(pool.get_ref())
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(serde_json::json!({}), "Senha redefinida com sucesso")))
}

/// Change password for authenticated user (forced or voluntary)
#[utoipa::path(
    put,
    path = "/api/v1/auth/change-password",
    request_body = ChangePasswordRequest,
    responses(
        (status = 200, description = "Password changed successfully"),
        (status = 400, description = "Validation error"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/auth/change-password")]
pub async fn change_password(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<ChangePasswordRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let user_id = middleware::get_user_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    if body.new_password != body.confirm_password {
        return Err(AppError::validation("Senhas não conferem"));
    }

    AuthService::change_password(pool.get_ref(), user_id, &body.new_password).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        serde_json::json!({}),
        "Senha alterada com sucesso",
    )))
}
