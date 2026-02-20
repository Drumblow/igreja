use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::ApiResponse;
use crate::application::dto::{CreateChurchRoleRequest, UpdateChurchRoleRequest};
use crate::application::services::ChurchRoleService;
use crate::config::AppConfig;
use crate::errors::AppError;

/// List active church roles
#[utoipa::path(
    get,
    path = "/api/v1/church-roles",
    responses(
        (status = 200, description = "List of church roles"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/church-roles")]
pub async fn list_church_roles(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let roles = ChurchRoleService::list(pool.get_ref(), church_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(roles)))
}

/// Create a new church role
#[utoipa::path(
    post,
    path = "/api/v1/church-roles",
    request_body = CreateChurchRoleRequest,
    responses(
        (status = 201, description = "Role created"),
        (status = 400, description = "Validation error"),
        (status = 409, description = "Role already exists")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/church-roles")]
pub async fn create_church_role(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateChurchRoleRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let role = ChurchRoleService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        role,
        "Cargo criado com sucesso",
    )))
}

/// Update a church role
#[utoipa::path(
    put,
    path = "/api/v1/church-roles/{id}",
    params(("id" = uuid::Uuid, Path, description = "Role ID")),
    request_body = UpdateChurchRoleRequest,
    responses(
        (status = 200, description = "Role updated"),
        (status = 404, description = "Role not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/church-roles/{id}")]
pub async fn update_church_role(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateChurchRoleRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let role_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let role = ChurchRoleService::update(pool.get_ref(), church_id, role_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        role,
        "Cargo atualizado com sucesso",
    )))
}

/// Delete a custom church role
#[utoipa::path(
    delete,
    path = "/api/v1/church-roles/{id}",
    params(("id" = uuid::Uuid, Path, description = "Role ID")),
    responses(
        (status = 200, description = "Role deleted"),
        (status = 404, description = "Role not found"),
        (status = 400, description = "Cannot delete default role")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/church-roles/{id}")]
pub async fn delete_church_role(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let role_id = path.into_inner();

    ChurchRoleService::delete(pool.get_ref(), church_id, role_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(
        serde_json::json!({"message": "Cargo removido com sucesso"}),
    )))
}
