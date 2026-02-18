use actix_web::{get, post, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::ApiResponse;
use crate::application::dto::CreateMemberHistoryRequest;
use crate::application::services::MemberHistoryService;
use crate::config::AppConfig;
use crate::errors::AppError;

/// Get history events for a member
#[utoipa::path(
    get,
    path = "/api/v1/members/{id}/history",
    params(("id" = uuid::Uuid, Path, description = "Member ID")),
    responses(
        (status = 200, description = "Member history events"),
        (status = 404, description = "Member not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/members/{id}/history")]
pub async fn get_member_history(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    let history = MemberHistoryService::list(pool.get_ref(), church_id, member_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(history)))
}

/// Create a history event for a member
#[utoipa::path(
    post,
    path = "/api/v1/members/{id}/history",
    params(("id" = uuid::Uuid, Path, description = "Member ID")),
    request_body = CreateMemberHistoryRequest,
    responses(
        (status = 201, description = "History event created"),
        (status = 404, description = "Member not found")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/members/{id}/history")]
pub async fn create_member_history(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<CreateMemberHistoryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;
    let member_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let history = MemberHistoryService::create(pool.get_ref(), church_id, member_id, user_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(history, "Evento registrado com sucesso")))
}
