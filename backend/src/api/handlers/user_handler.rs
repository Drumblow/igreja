use actix_web::{get, post, put, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{CreateUserRequest, UpdateUserRequest};
use crate::application::services::UserService;
use crate::config::AppConfig;
use crate::errors::AppError;

// ==========================================
// Users
// ==========================================

/// List users for the current church
#[utoipa::path(
    get,
    path = "/api/v1/users",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by email"),
    ),
    responses(
        (status = 200, description = "List of users"),
        (status = 401, description = "Not authenticated"),
        (status = 403, description = "Forbidden")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/users")]
pub async fn list_users(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    // Only admin-level roles can manage users
    if claims.role != "super_admin" {
        middleware::require_permission(&claims, "settings:read")?;
    }
    let church_id = middleware::get_church_id(&claims)?;

    let (users, total) = UserService::list(
        pool.get_ref(),
        church_id,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        users,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get user details
#[utoipa::path(
    get,
    path = "/api/v1/users/{id}",
    params(("id" = uuid::Uuid, Path, description = "User ID")),
    responses(
        (status = 200, description = "User details"),
        (status = 404, description = "User not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/users/{id}")]
pub async fn get_user(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    if claims.role != "super_admin" {
        middleware::require_permission(&claims, "settings:read")?;
    }
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = path.into_inner();

    let user = UserService::get_by_id(pool.get_ref(), church_id, user_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(user)))
}

/// Create a new user
#[utoipa::path(
    post,
    path = "/api/v1/users",
    request_body = CreateUserRequest,
    responses(
        (status = 201, description = "User created"),
        (status = 400, description = "Validation error"),
        (status = 409, description = "Email conflict")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/users")]
pub async fn create_user(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateUserRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    if claims.role != "super_admin" {
        middleware::require_permission(&claims, "settings:write")?;
    }
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let user = UserService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        serde_json::json!({
            "id": user.id,
            "email": user.email,
            "is_active": user.is_active
        }),
        "Usuário criado com sucesso",
    )))
}

/// Update a user
#[utoipa::path(
    put,
    path = "/api/v1/users/{id}",
    params(("id" = uuid::Uuid, Path, description = "User ID")),
    request_body = UpdateUserRequest,
    responses(
        (status = 200, description = "User updated"),
        (status = 400, description = "Validation error"),
        (status = 404, description = "User not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/users/{id}")]
pub async fn update_user(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateUserRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    if claims.role != "super_admin" {
        middleware::require_permission(&claims, "settings:write")?;
    }
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let user = UserService::update(pool.get_ref(), church_id, user_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        serde_json::json!({
            "id": user.id,
            "email": user.email,
            "is_active": user.is_active
        }),
        "Usuário atualizado com sucesso",
    )))
}

// ==========================================
// Roles
// ==========================================

/// List all roles
#[utoipa::path(
    get,
    path = "/api/v1/roles",
    responses(
        (status = 200, description = "List of roles"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/roles")]
pub async fn list_roles(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    if claims.role != "super_admin" {
        middleware::require_permission(&claims, "settings:read")?;
    }

    let roles = UserService::list_roles(pool.get_ref()).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(roles)))
}
