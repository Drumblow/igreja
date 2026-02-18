use actix_web::{get, HttpResponse};
use serde::Serialize;
use sqlx::PgPool;
use utoipa::ToSchema;

#[derive(Serialize, ToSchema)]
pub struct HealthResponse {
    pub status: String,
    pub version: String,
    pub database: String,
}

/// Health check endpoint
#[utoipa::path(
    get,
    path = "/api/health",
    responses(
        (status = 200, description = "Service is healthy", body = HealthResponse)
    )
)]
#[get("/api/health")]
pub async fn health_check(pool: actix_web::web::Data<PgPool>) -> HttpResponse {
    let db_status = match sqlx::query_scalar::<_, i32>("SELECT 1").fetch_one(pool.get_ref()).await {
        Ok(_) => "connected".to_string(),
        Err(e) => format!("error: {e}"),
    };

    HttpResponse::Ok().json(HealthResponse {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        database: db_status,
    })
}
