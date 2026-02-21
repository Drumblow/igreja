use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use serde::Deserialize;
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::ApiResponse;
use crate::application::dto::{
    AddUserToCongregationRequest, AssignMembersRequest, CongregationCompareFilter,
    CreateCongregationRequest, SetActiveCongregationRequest, UpdateCongregationRequest,
};
use crate::application::services::CongregationService;
use crate::application::services::AuditService;
use crate::config::AppConfig;
use crate::errors::AppError;
use crate::infrastructure::cache::CacheService;

#[derive(Debug, Deserialize)]
pub struct CongregationFilter {
    pub is_active: Option<bool>,
    #[serde(rename = "type")]
    pub congregation_type: Option<String>,
}

/// List congregations
#[utoipa::path(
    get,
    path = "/api/v1/congregations",
    params(
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
        ("type" = Option<String>, Query, description = "Filter by type: sede, congregacao, ponto_de_pregacao"),
    ),
    responses(
        (status = 200, description = "List of congregations"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/congregations")]
pub async fn list_congregations(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    filter: web::Query<CongregationFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let congregations = CongregationService::list(
        pool.get_ref(),
        church_id,
        filter.is_active,
        filter.congregation_type.clone(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(congregations)))
}

/// Get congregation by ID
#[utoipa::path(
    get,
    path = "/api/v1/congregations/{id}",
    params(("id" = uuid::Uuid, Path, description = "Congregation ID")),
    responses(
        (status = 200, description = "Congregation details"),
        (status = 404, description = "Congregation not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/congregations/{id}")]
pub async fn get_congregation(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let congregation_id = path.into_inner();

    let detail =
        CongregationService::get_detail(pool.get_ref(), church_id, congregation_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(detail)))
}

/// Create a new congregation
#[utoipa::path(
    post,
    path = "/api/v1/congregations",
    request_body = CreateCongregationRequest,
    responses(
        (status = 201, description = "Congregation created"),
        (status = 400, description = "Validation error"),
        (status = 409, description = "Conflict — sede already exists")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/congregations")]
pub async fn create_congregation(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    body: web::Json<CreateCongregationRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let congregation = CongregationService::create(pool.get_ref(), church_id, &body).await?;

    // Cache invalidation
    cache.del_pattern(&format!("congregations:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "create", "congregation", congregation.id,
    ).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        congregation,
        "Congregação criada com sucesso",
    )))
}

/// Update a congregation
#[utoipa::path(
    put,
    path = "/api/v1/congregations/{id}",
    params(("id" = uuid::Uuid, Path, description = "Congregation ID")),
    request_body = UpdateCongregationRequest,
    responses(
        (status = 200, description = "Congregation updated"),
        (status = 404, description = "Congregation not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/congregations/{id}")]
pub async fn update_congregation(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateCongregationRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let congregation_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let congregation =
        CongregationService::update(pool.get_ref(), church_id, congregation_id, &body).await?;

    // Cache invalidation
    cache.del_pattern(&format!("congregations:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "update", "congregation", congregation_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        congregation,
        "Congregação atualizada com sucesso",
    )))
}

/// Deactivate a congregation (soft delete)
#[utoipa::path(
    delete,
    path = "/api/v1/congregations/{id}",
    params(("id" = uuid::Uuid, Path, description = "Congregation ID")),
    responses(
        (status = 200, description = "Congregation deactivated"),
        (status = 404, description = "Congregation not found"),
        (status = 409, description = "Cannot deactivate sede with active congregations")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/congregations/{id}")]
pub async fn deactivate_congregation(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let congregation_id = path.into_inner();

    CongregationService::deactivate(pool.get_ref(), church_id, congregation_id).await?;

    // Cache invalidation
    cache.del_pattern(&format!("congregations:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "deactivate", "congregation", congregation_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::ok(
        serde_json::json!({"message": "Congregação desativada com sucesso"}),
    )))
}

/// Get congregation stats
#[utoipa::path(
    get,
    path = "/api/v1/congregations/{id}/stats",
    params(("id" = uuid::Uuid, Path, description = "Congregation ID")),
    responses(
        (status = 200, description = "Congregation stats"),
        (status = 404, description = "Congregation not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/congregations/{id}/stats")]
pub async fn get_congregation_stats(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let congregation_id = path.into_inner();

    let stats =
        CongregationService::get_stats(pool.get_ref(), church_id, congregation_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(stats)))
}

/// List users with access to a congregation
#[utoipa::path(
    get,
    path = "/api/v1/congregations/{id}/users",
    params(("id" = uuid::Uuid, Path, description = "Congregation ID")),
    responses(
        (status = 200, description = "List of congregation users"),
        (status = 404, description = "Congregation not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/congregations/{id}/users")]
pub async fn list_congregation_users(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let congregation_id = path.into_inner();

    let users =
        CongregationService::list_users(pool.get_ref(), church_id, congregation_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(users)))
}

/// Add user to a congregation
#[utoipa::path(
    post,
    path = "/api/v1/congregations/{id}/users",
    params(("id" = uuid::Uuid, Path, description = "Congregation ID")),
    request_body = AddUserToCongregationRequest,
    responses(
        (status = 201, description = "User added to congregation"),
        (status = 409, description = "User already has access")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/congregations/{id}/users")]
pub async fn add_congregation_user(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<AddUserToCongregationRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let congregation_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let uc =
        CongregationService::add_user(pool.get_ref(), church_id, congregation_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        uc,
        "Usuário adicionado à congregação",
    )))
}

/// Remove user from a congregation
#[utoipa::path(
    delete,
    path = "/api/v1/congregations/{congregation_id}/users/{user_id}",
    params(
        ("congregation_id" = uuid::Uuid, Path, description = "Congregation ID"),
        ("user_id" = uuid::Uuid, Path, description = "User ID")
    ),
    responses(
        (status = 200, description = "User removed from congregation"),
        (status = 404, description = "Association not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/congregations/{congregation_id}/users/{user_id}")]
pub async fn remove_congregation_user(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(uuid::Uuid, uuid::Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let (congregation_id, user_id) = path.into_inner();

    CongregationService::remove_user(pool.get_ref(), church_id, congregation_id, user_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(
        serde_json::json!({"message": "Usuário removido da congregação"}),
    )))
}

/// Assign members to a congregation in batch
#[utoipa::path(
    post,
    path = "/api/v1/congregations/{id}/assign-members",
    params(("id" = uuid::Uuid, Path, description = "Congregation ID")),
    request_body = AssignMembersRequest,
    responses(
        (status = 200, description = "Members assigned"),
        (status = 404, description = "Congregation not found")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/congregations/{id}/assign-members")]
pub async fn assign_members_batch(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<AssignMembersRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "settings:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let congregation_id = path.into_inner();

    let result =
        CongregationService::assign_members(pool.get_ref(), church_id, congregation_id, &body)
            .await?;

    let msg = format!(
        "{} membros associados à congregação",
        result.assigned
    );

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(result, msg)))
}

/// Set active congregation for the current user
#[utoipa::path(
    post,
    path = "/api/v1/user/active-congregation",
    request_body = SetActiveCongregationRequest,
    responses(
        (status = 200, description = "Active congregation updated"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/user/active-congregation")]
pub async fn set_active_congregation(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<SetActiveCongregationRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    // If a congregation_id is specified, validate it exists
    if let Some(congregation_id) = body.congregation_id {
        let name =
            CongregationService::validate_active_congregation(pool.get_ref(), church_id, congregation_id).await?;

        Ok(HttpResponse::Ok().json(ApiResponse::with_message(
            serde_json::json!({
                "active_congregation_id": congregation_id,
                "active_congregation_name": name,
            }),
            format!("Contexto alterado para {}", name),
        )))
    } else {
        Ok(HttpResponse::Ok().json(ApiResponse::with_message(
            serde_json::json!({
                "active_congregation_id": serde_json::Value::Null,
                "active_congregation_name": "Todas as Congregações",
            }),
            "Contexto alterado para Todas as congregações",
        )))
    }
}

/// Congregations overview report
#[utoipa::path(
    get,
    path = "/api/v1/reports/congregations/overview",
    responses(
        (status = 200, description = "Congregations overview"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/reports/congregations/overview")]
pub async fn congregations_overview_report(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let overview = CongregationService::get_overview(pool.get_ref(), church_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(overview)))
}

/// Congregations compare report
#[utoipa::path(
    get,
    path = "/api/v1/reports/congregations/compare",
    params(
        ("metric" = Option<String>, Query, description = "Metric: members, financial, ebd, assets"),
        ("period_start" = Option<String>, Query, description = "Period start date (YYYY-MM-DD)"),
        ("period_end" = Option<String>, Query, description = "Period end date (YYYY-MM-DD)"),
        ("congregation_ids" = Option<String>, Query, description = "Comma-separated congregation UUIDs to compare"),
    ),
    responses(
        (status = 200, description = "Congregations comparison report"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/reports/congregations/compare")]
pub async fn congregations_compare_report(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    filter: web::Query<CongregationCompareFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let report = CongregationService::compare(pool.get_ref(), church_id, &filter).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(report)))
}
