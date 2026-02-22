use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use chrono::NaiveDate;
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{
    CloneClassesRequest, CreateActivityResponsesRequest, CreateEbdAttendanceRequest,
    CreateEbdClassRequest, CreateEbdEnrollmentRequest, CreateEbdLessonRequest,
    CreateEbdTermRequest, CreateLessonActivityRequest, CreateLessonContentRequest,
    CreateLessonMaterialRequest, CreateStudentNoteRequest, DeleteLessonParams, EbdClassFilter,
    EbdLessonFilter, EbdStudentFilter, ReorderContentsRequest, StudentNoteFilter,
    TermComparisonQuery, UpdateActivityResponseRequest, UpdateEbdClassRequest,
    UpdateEbdLessonRequest, UpdateEbdTermRequest, UpdateLessonActivityRequest,
    UpdateLessonContentRequest, UpdateStudentNoteRequest,
};
use crate::application::services::{
    AuditService, EbdAttendanceService, EbdClassService, EbdLessonActivityService,
    EbdLessonContentService, EbdLessonMaterialService, EbdLessonService,
    EbdReportService, EbdStudentNoteService, EbdStudentService, EbdTermService,
};
use crate::config::AppConfig;
use crate::errors::AppError;
use crate::infrastructure::cache::CacheService;

// ==========================================
// EBD Terms (Períodos/Trimestres)
// ==========================================

/// List EBD terms
#[utoipa::path(
    get,
    path = "/api/v1/ebd/terms",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
    ),
    responses(
        (status = 200, description = "List of EBD terms"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/terms")]
pub async fn list_ebd_terms(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let is_active: Option<bool> = None;
    let congregation_id: Option<Uuid> = None; // TODO: get from query params

    let (terms, total) = EbdTermService::list(
        pool.get_ref(),
        church_id,
        &is_active,
        congregation_id,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        terms,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get EBD term by ID
#[utoipa::path(
    get,
    path = "/api/v1/ebd/terms/{term_id}",
    params(
        ("term_id" = Uuid, Path, description = "Term ID"),
    ),
    responses(
        (status = 200, description = "EBD term details"),
        (status = 404, description = "Term not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/terms/{term_id}")]
pub async fn get_ebd_term(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let term_id = path.into_inner();

    let term = EbdTermService::get_by_id(pool.get_ref(), church_id, term_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(term)))
}

/// Create a new EBD term
#[utoipa::path(
    post,
    path = "/api/v1/ebd/terms",
    request_body = CreateEbdTermRequest,
    responses(
        (status = 201, description = "Term created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/terms")]
pub async fn create_ebd_term(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    body: web::Json<CreateEbdTermRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let term = EbdTermService::create(pool.get_ref(), church_id, &body).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "create", "ebd_term", term.id).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(term, "Período EBD criado com sucesso")))
}

/// Update an EBD term
#[utoipa::path(
    put,
    path = "/api/v1/ebd/terms/{term_id}",
    params(
        ("term_id" = Uuid, Path, description = "Term ID"),
    ),
    request_body = UpdateEbdTermRequest,
    responses(
        (status = 200, description = "Term updated"),
        (status = 404, description = "Term not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/terms/{term_id}")]
pub async fn update_ebd_term(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<UpdateEbdTermRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let term_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let term = EbdTermService::update(pool.get_ref(), church_id, term_id, &body).await?;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "update", "ebd_term", term_id).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(term, "Período EBD atualizado")))
}

/// Delete an EBD term
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/terms/{term_id}",
    params(("term_id" = Uuid, Path, description = "Term ID")),
    responses(
        (status = 200, description = "Term deleted"),
        (status = 404, description = "Term not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/terms/{term_id}")]
pub async fn delete_ebd_term(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let term_id = path.into_inner();

    EbdTermService::delete(pool.get_ref(), church_id, term_id).await?;

    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "delete", "ebd_term", term_id).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Período EBD removido")))
}

// ==========================================
// EBD Classes (Turmas)
// ==========================================

#[derive(Deserialize)]
pub struct EbdClassQueryParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub search: Option<String>,
    pub term_id: Option<Uuid>,
    pub is_active: Option<bool>,
    pub teacher_id: Option<Uuid>,
    pub congregation_id: Option<Uuid>,
}

/// List EBD classes
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("term_id" = Option<Uuid>, Query, description = "Filter by term"),
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
        ("teacher_id" = Option<Uuid>, Query, description = "Filter by teacher"),
    ),
    responses(
        (status = 200, description = "List of EBD classes"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes")]
pub async fn list_ebd_classes(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    query: web::Query<EbdClassQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let filter = EbdClassFilter {
        term_id: query.term_id,
        is_active: query.is_active,
        teacher_id: query.teacher_id,
        congregation_id: query.congregation_id,
    };

    let (classes, total) = EbdClassService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &query.search,
        per_page,
        offset,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(classes, page, per_page, total)))
}

/// Get EBD class by ID
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes/{class_id}",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    responses(
        (status = 200, description = "EBD class details"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes/{class_id}")]
pub async fn get_ebd_class(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    let class = EbdClassService::get_by_id(pool.get_ref(), church_id, class_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(class)))
}

/// Create a new EBD class
#[utoipa::path(
    post,
    path = "/api/v1/ebd/classes",
    request_body = CreateEbdClassRequest,
    responses(
        (status = 201, description = "Class created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/classes")]
pub async fn create_ebd_class(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    body: web::Json<CreateEbdClassRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let class = EbdClassService::create(pool.get_ref(), church_id, &body).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "create", "ebd_class", class.id).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(class, "Turma EBD criada com sucesso")))
}

/// Update an EBD class
#[utoipa::path(
    put,
    path = "/api/v1/ebd/classes/{class_id}",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    request_body = UpdateEbdClassRequest,
    responses(
        (status = 200, description = "Class updated"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/classes/{class_id}")]
pub async fn update_ebd_class(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<UpdateEbdClassRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let class = EbdClassService::update(pool.get_ref(), church_id, class_id, &body).await?;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "update", "ebd_class", class_id).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(class, "Turma EBD atualizada")))
}

/// Delete an EBD class
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/classes/{class_id}",
    params(("class_id" = Uuid, Path, description = "Class ID")),
    responses(
        (status = 200, description = "Class deleted"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/classes/{class_id}")]
pub async fn delete_ebd_class(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    EbdClassService::delete(pool.get_ref(), church_id, class_id).await?;

    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "delete", "ebd_class", class_id).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Turma EBD removida")))
}

// ==========================================
// EBD Enrollments (Matrículas)
// ==========================================

/// List enrollments for a class
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes/{class_id}/enrollments",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    responses(
        (status = 200, description = "List of enrollments"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes/{class_id}/enrollments")]
pub async fn list_class_enrollments(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let class_id = path.into_inner();

    let enrollments = EbdClassService::list_enrollments(pool.get_ref(), class_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(enrollments)))
}

/// Enroll a member in a class
#[utoipa::path(
    post,
    path = "/api/v1/ebd/classes/{class_id}/enrollments",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    request_body = CreateEbdEnrollmentRequest,
    responses(
        (status = 201, description = "Member enrolled"),
        (status = 409, description = "Member already enrolled")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/classes/{class_id}/enrollments")]
pub async fn enroll_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
    body: web::Json<CreateEbdEnrollmentRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let enrollment = EbdClassService::enroll_member(pool.get_ref(), class_id, &body).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "create", "ebd_enrollment", enrollment.id).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(enrollment, "Membro matriculado com sucesso")))
}

/// Remove enrollment
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/classes/{class_id}/enrollments/{enrollment_id}",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
        ("enrollment_id" = Uuid, Path, description = "Enrollment ID"),
    ),
    responses(
        (status = 200, description = "Enrollment removed"),
        (status = 404, description = "Enrollment not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/classes/{class_id}/enrollments/{enrollment_id}")]
pub async fn remove_enrollment(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<(Uuid, Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let (class_id, enrollment_id) = path.into_inner();

    EbdClassService::remove_enrollment(pool.get_ref(), class_id, enrollment_id).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "delete", "ebd_enrollment", enrollment_id).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Matrícula removida")))
}

// ==========================================
// EBD Lessons (Aulas)
// ==========================================

#[derive(Deserialize)]
pub struct EbdLessonQueryParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub class_id: Option<Uuid>,
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
}

/// List EBD lessons
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("class_id" = Option<Uuid>, Query, description = "Filter by class"),
        ("date_from" = Option<NaiveDate>, Query, description = "Start date filter"),
        ("date_to" = Option<NaiveDate>, Query, description = "End date filter"),
    ),
    responses(
        (status = 200, description = "List of EBD lessons"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons")]
pub async fn list_ebd_lessons(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    query: web::Query<EbdLessonQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let filter = EbdLessonFilter {
        class_id: query.class_id,
        date_from: query.date_from,
        date_to: query.date_to,
    };

    let (lessons, total) = EbdLessonService::list(
        pool.get_ref(),
        church_id,
        &filter,
        per_page,
        offset,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(lessons, page, per_page, total)))
}

/// Get EBD lesson by ID
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons/{lesson_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
    ),
    responses(
        (status = 200, description = "EBD lesson details"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons/{lesson_id}")]
pub async fn get_ebd_lesson(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    let lesson = EbdLessonService::get_by_id(pool.get_ref(), church_id, lesson_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(lesson)))
}

/// Create a new EBD lesson
#[utoipa::path(
    post,
    path = "/api/v1/ebd/lessons",
    request_body = CreateEbdLessonRequest,
    responses(
        (status = 201, description = "Lesson created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/lessons")]
pub async fn create_ebd_lesson(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateEbdLessonRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let lesson = EbdLessonService::create(pool.get_ref(), church_id, &body).await?;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "create", "ebd_lesson", lesson.id).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(lesson, "Aula EBD criada com sucesso")))
}

// ==========================================
// EBD Attendance (Frequência)
// ==========================================

/// Record attendance for a lesson (batch)
#[utoipa::path(
    post,
    path = "/api/v1/ebd/lessons/{lesson_id}/attendance",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
    ),
    request_body = CreateEbdAttendanceRequest,
    responses(
        (status = 201, description = "Attendance recorded"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/lessons/{lesson_id}/attendance")]
pub async fn record_attendance(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
    body: web::Json<CreateEbdAttendanceRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;
    let lesson_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let attendances = EbdAttendanceService::record_attendance(
        pool.get_ref(),
        lesson_id,
        user_id,
        &body,
    )
    .await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "create", "ebd_attendance", lesson_id).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        attendances,
        "Frequência registrada com sucesso",
    )))
}

/// Get attendance records for a lesson
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons/{lesson_id}/attendance",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
    ),
    responses(
        (status = 200, description = "Attendance records"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons/{lesson_id}/attendance")]
pub async fn get_lesson_attendance(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let lesson_id = path.into_inner();

    let attendances = EbdAttendanceService::get_by_lesson(pool.get_ref(), lesson_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(attendances)))
}

/// Get attendance report for a class
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes/{class_id}/report",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
        ("date_from" = Option<NaiveDate>, Query, description = "Start date"),
        ("date_to" = Option<NaiveDate>, Query, description = "End date"),
    ),
    responses(
        (status = 200, description = "Class attendance report"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes/{class_id}/report")]
pub async fn get_class_report(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    query: web::Query<ReportQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    let report = EbdAttendanceService::report(
        pool.get_ref(),
        church_id,
        class_id,
        &query.date_from,
        &query.date_to,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(report)))
}

#[derive(Deserialize)]
pub struct ReportQueryParams {
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
}

// ==========================================
// EBD Stats
// ==========================================

/// Get EBD statistics for the dashboard
#[utoipa::path(
    get,
    path = "/api/v1/ebd/stats",
    responses(
        (status = 200, description = "EBD statistics"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/stats")]
pub async fn ebd_stats(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    // Try cache first
    let cache_key = format!("ebd:stats:{church_id}");
    if let Some(cached) = cache.get::<serde_json::Value>(&cache_key).await {
        return Ok(HttpResponse::Ok().json(ApiResponse::ok(cached)));
    }

    let total_classes = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ebd_classes WHERE church_id = $1 AND is_active = TRUE"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let total_enrolled = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ebd_enrollments en \
         JOIN ebd_classes c ON c.id = en.class_id \
         WHERE c.church_id = $1 AND c.is_active = TRUE AND en.is_active = TRUE"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let active_terms = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ebd_terms WHERE church_id = $1 AND is_active = TRUE"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    // Average attendance rate for the current month
    let avg_attendance: Option<f64> = sqlx::query_scalar(
        "SELECT AVG(CASE WHEN ea.status = 'presente' THEN 1.0 ELSE 0.0 END) \
         FROM ebd_attendances ea \
         JOIN ebd_lessons el ON el.id = ea.lesson_id \
         JOIN ebd_classes ec ON ec.id = el.class_id \
         WHERE ec.church_id = $1 \
         AND EXTRACT(MONTH FROM el.lesson_date) = EXTRACT(MONTH FROM NOW()) \
         AND EXTRACT(YEAR FROM el.lesson_date) = EXTRACT(YEAR FROM NOW())"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let stats = serde_json::json!({
        "total_classes": total_classes,
        "total_enrolled": total_enrolled,
        "active_terms": active_terms,
        "avg_attendance_rate": avg_attendance.unwrap_or(0.0)
    });

    // Cache for 120 seconds
    cache.set(&cache_key, &stats, 120).await;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(stats)))
}

// ==========================================
// EBD Lessons — Update / Delete (F1.2)
// ==========================================

/// Update an EBD lesson
#[utoipa::path(
    put,
    path = "/api/v1/ebd/lessons/{lesson_id}",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    request_body = UpdateEbdLessonRequest,
    responses(
        (status = 200, description = "Lesson updated"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/lessons/{lesson_id}")]
pub async fn update_ebd_lesson(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
    body: web::Json<UpdateEbdLessonRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let lesson = EbdLessonService::update(pool.get_ref(), church_id, lesson_id, &body).await?;

    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "update", "ebd_lesson", lesson_id).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(lesson, "Aula EBD atualizada")))
}

/// Delete an EBD lesson
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/lessons/{lesson_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
        ("force" = Option<bool>, Query, description = "Force delete even with attendance"),
    ),
    responses(
        (status = 200, description = "Lesson deleted"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/lessons/{lesson_id}")]
pub async fn delete_ebd_lesson(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
    query: web::Query<DeleteLessonParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    EbdLessonService::delete(pool.get_ref(), church_id, lesson_id, query.force.unwrap_or(false)).await?;

    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "delete", "ebd_lesson", lesson_id).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Aula EBD removida")))
}

// ==========================================
// EBD Lesson Contents (E1)
// ==========================================

/// List contents for a lesson
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons/{lesson_id}/contents",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    responses(
        (status = 200, description = "List of lesson contents"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons/{lesson_id}/contents")]
pub async fn list_lesson_contents(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    let contents = EbdLessonContentService::list(pool.get_ref(), lesson_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(contents)))
}

/// Create a lesson content block
#[utoipa::path(
    post,
    path = "/api/v1/ebd/lessons/{lesson_id}/contents",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    request_body = CreateLessonContentRequest,
    responses(
        (status = 201, description = "Content created"),
        (status = 400, description = "Validation error or limit reached")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/lessons/{lesson_id}/contents")]
pub async fn create_lesson_content(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<CreateLessonContentRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let content = EbdLessonContentService::create(pool.get_ref(), lesson_id, church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(content, "Conteúdo criado")))
}

/// Update a lesson content block
#[utoipa::path(
    put,
    path = "/api/v1/ebd/lessons/{lesson_id}/contents/{content_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
        ("content_id" = Uuid, Path, description = "Content ID"),
    ),
    request_body = UpdateLessonContentRequest,
    responses(
        (status = 200, description = "Content updated"),
        (status = 404, description = "Content not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/lessons/{lesson_id}/contents/{content_id}")]
pub async fn update_lesson_content(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
    body: web::Json<UpdateLessonContentRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let (lesson_id, content_id) = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let content = EbdLessonContentService::update(pool.get_ref(), lesson_id, content_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(content, "Conteúdo atualizado")))
}

/// Delete a lesson content block
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/lessons/{lesson_id}/contents/{content_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
        ("content_id" = Uuid, Path, description = "Content ID"),
    ),
    responses(
        (status = 200, description = "Content deleted"),
        (status = 404, description = "Content not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/lessons/{lesson_id}/contents/{content_id}")]
pub async fn delete_lesson_content(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let (lesson_id, content_id) = path.into_inner();

    EbdLessonContentService::delete(pool.get_ref(), lesson_id, content_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Conteúdo removido")))
}

/// Reorder lesson content blocks
#[utoipa::path(
    put,
    path = "/api/v1/ebd/lessons/{lesson_id}/contents/reorder",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    request_body = ReorderContentsRequest,
    responses(
        (status = 200, description = "Contents reordered"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/lessons/{lesson_id}/contents/reorder")]
pub async fn reorder_lesson_contents(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<ReorderContentsRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    EbdLessonContentService::reorder(pool.get_ref(), lesson_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Conteúdos reordenados")))
}

// ==========================================
// EBD Lesson Activities (E2)
// ==========================================

/// List activities for a lesson
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons/{lesson_id}/activities",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    responses(
        (status = 200, description = "List of lesson activities"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons/{lesson_id}/activities")]
pub async fn list_lesson_activities(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    // Teachers with write can see correct_answer; students get public version
    let _has_write = middleware::require_permission(&claims, "ebd:write").is_ok();

    let activities = EbdLessonActivityService::list(pool.get_ref(), lesson_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(activities)))
}

/// Create a lesson activity
#[utoipa::path(
    post,
    path = "/api/v1/ebd/lessons/{lesson_id}/activities",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    request_body = CreateLessonActivityRequest,
    responses(
        (status = 201, description = "Activity created"),
        (status = 400, description = "Validation error or limit reached")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/lessons/{lesson_id}/activities")]
pub async fn create_lesson_activity(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<CreateLessonActivityRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let activity = EbdLessonActivityService::create(pool.get_ref(), lesson_id, church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(activity, "Atividade criada")))
}

/// Update a lesson activity
#[utoipa::path(
    put,
    path = "/api/v1/ebd/lessons/{lesson_id}/activities/{activity_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
        ("activity_id" = Uuid, Path, description = "Activity ID"),
    ),
    request_body = UpdateLessonActivityRequest,
    responses(
        (status = 200, description = "Activity updated"),
        (status = 404, description = "Activity not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/lessons/{lesson_id}/activities/{activity_id}")]
pub async fn update_lesson_activity(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
    body: web::Json<UpdateLessonActivityRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let (lesson_id, activity_id) = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let activity = EbdLessonActivityService::update(pool.get_ref(), lesson_id, activity_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(activity, "Atividade atualizada")))
}

/// Delete a lesson activity
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/lessons/{lesson_id}/activities/{activity_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
        ("activity_id" = Uuid, Path, description = "Activity ID"),
    ),
    responses(
        (status = 200, description = "Activity deleted"),
        (status = 404, description = "Activity not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/lessons/{lesson_id}/activities/{activity_id}")]
pub async fn delete_lesson_activity(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let (lesson_id, activity_id) = path.into_inner();

    EbdLessonActivityService::delete(pool.get_ref(), lesson_id, activity_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Atividade removida")))
}

// ==========================================
// EBD Activity Responses (E2)
// ==========================================

/// List responses for an activity
#[utoipa::path(
    get,
    path = "/api/v1/ebd/activities/{activity_id}/responses",
    params(("activity_id" = Uuid, Path, description = "Activity ID")),
    responses(
        (status = 200, description = "List of activity responses"),
        (status = 404, description = "Activity not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/activities/{activity_id}/responses")]
pub async fn list_activity_responses(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let activity_id = path.into_inner();

    let responses = EbdLessonActivityService::list_responses(pool.get_ref(), activity_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(responses)))
}

/// Record responses for an activity (batch)
#[utoipa::path(
    post,
    path = "/api/v1/ebd/activities/{activity_id}/responses",
    params(("activity_id" = Uuid, Path, description = "Activity ID")),
    request_body = CreateActivityResponsesRequest,
    responses(
        (status = 201, description = "Responses recorded"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/activities/{activity_id}/responses")]
pub async fn record_activity_responses(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<CreateActivityResponsesRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let activity_id = path.into_inner();

    let responses = EbdLessonActivityService::record_responses(pool.get_ref(), activity_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(responses, "Respostas registradas")))
}

/// Update a single activity response
#[utoipa::path(
    put,
    path = "/api/v1/ebd/activities/{activity_id}/responses/{response_id}",
    params(
        ("activity_id" = Uuid, Path, description = "Activity ID"),
        ("response_id" = Uuid, Path, description = "Response ID"),
    ),
    request_body = UpdateActivityResponseRequest,
    responses(
        (status = 200, description = "Response updated"),
        (status = 404, description = "Response not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/activities/{activity_id}/responses/{response_id}")]
pub async fn update_activity_response(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
    body: web::Json<UpdateActivityResponseRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let (activity_id, response_id) = path.into_inner();

    let response = EbdLessonActivityService::update_response(pool.get_ref(), activity_id, response_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(response, "Resposta atualizada")))
}

// ==========================================
// EBD Lesson Materials (E4)
// ==========================================

/// List materials for a lesson
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons/{lesson_id}/materials",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    responses(
        (status = 200, description = "List of lesson materials"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons/{lesson_id}/materials")]
pub async fn list_lesson_materials(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    let materials = EbdLessonMaterialService::list(pool.get_ref(), lesson_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(materials)))
}

/// Add material to a lesson
#[utoipa::path(
    post,
    path = "/api/v1/ebd/lessons/{lesson_id}/materials",
    params(("lesson_id" = Uuid, Path, description = "Lesson ID")),
    request_body = CreateLessonMaterialRequest,
    responses(
        (status = 201, description = "Material added"),
        (status = 400, description = "Validation error or limit reached")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/lessons/{lesson_id}/materials")]
pub async fn create_lesson_material(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<CreateLessonMaterialRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let user_id = middleware::get_user_id(&claims)?;

    let material = EbdLessonMaterialService::create(pool.get_ref(), lesson_id, church_id, user_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(material, "Material adicionado")))
}

/// Delete a lesson material
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/lessons/{lesson_id}/materials/{material_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
        ("material_id" = Uuid, Path, description = "Material ID"),
    ),
    responses(
        (status = 200, description = "Material removed"),
        (status = 404, description = "Material not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/lessons/{lesson_id}/materials/{material_id}")]
pub async fn delete_lesson_material(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let (lesson_id, material_id) = path.into_inner();

    EbdLessonMaterialService::delete(pool.get_ref(), lesson_id, material_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Material removido")))
}

// ==========================================
// EBD Students (E3 — Perfil do Aluno)
// ==========================================

#[derive(Deserialize)]
pub struct EbdStudentQueryParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub search: Option<String>,
    pub class_id: Option<Uuid>,
    pub term_id: Option<Uuid>,
}

/// List EBD students with summary data
#[utoipa::path(
    get,
    path = "/api/v1/ebd/students",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("class_id" = Option<Uuid>, Query, description = "Filter by class"),
        ("term_id" = Option<Uuid>, Query, description = "Filter by term"),
    ),
    responses(
        (status = 200, description = "List of students with summary"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/students")]
pub async fn list_ebd_students(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    query: web::Query<EbdStudentQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let filter = EbdStudentFilter {
        search: query.search.clone(),
        class_id: query.class_id,
        term_id: query.term_id,
        min_attendance: None,
        max_attendance: None,
    };

    let (students, total) = EbdStudentService::list(
        pool.get_ref(),
        church_id,
        &filter,
        per_page,
        offset,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(students, page, per_page, total)))
}

/// Get student profile
#[utoipa::path(
    get,
    path = "/api/v1/ebd/students/{member_id}/profile",
    params(("member_id" = Uuid, Path, description = "Member ID")),
    responses(
        (status = 200, description = "Student profile data"),
        (status = 404, description = "Student not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/students/{member_id}/profile")]
pub async fn get_student_profile(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    let profile = EbdStudentService::get_profile(pool.get_ref(), church_id, member_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(profile)))
}

/// Get student enrollment history
#[utoipa::path(
    get,
    path = "/api/v1/ebd/students/{member_id}/history",
    params(("member_id" = Uuid, Path, description = "Member ID")),
    responses(
        (status = 200, description = "Student enrollment history"),
        (status = 404, description = "Student not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/students/{member_id}/history")]
pub async fn get_student_history(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    let history = EbdStudentService::get_history(pool.get_ref(), church_id, member_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(history)))
}

/// Get student activity participation
#[utoipa::path(
    get,
    path = "/api/v1/ebd/students/{member_id}/activities",
    params(("member_id" = Uuid, Path, description = "Member ID")),
    responses(
        (status = 200, description = "Student activity participation"),
        (status = 404, description = "Student not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/students/{member_id}/activities")]
pub async fn get_student_activities(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    let activities = EbdStudentService::get_activities(pool.get_ref(), church_id, member_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(activities)))
}

// ==========================================
// EBD Student Notes (E5)
// ==========================================

#[derive(Deserialize)]
pub struct StudentNoteQueryParams {
    pub term_id: Option<Uuid>,
    pub note_type: Option<String>,
}

/// List notes for a student
#[utoipa::path(
    get,
    path = "/api/v1/ebd/students/{member_id}/notes",
    params(
        ("member_id" = Uuid, Path, description = "Member ID"),
        ("term_id" = Option<Uuid>, Query, description = "Filter by term"),
        ("note_type" = Option<String>, Query, description = "Filter by note type"),
    ),
    responses(
        (status = 200, description = "List of student notes"),
        (status = 404, description = "Student not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/students/{member_id}/notes")]
pub async fn list_student_notes(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    query: web::Query<StudentNoteQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let _user_id = middleware::get_user_id(&claims)?;
    let member_id = path.into_inner();

    let has_write = middleware::require_permission(&claims, "ebd:write").is_ok();

    let filter = StudentNoteFilter {
        term_id: query.term_id,
        note_type: query.note_type.clone(),
    };

    let notes = EbdStudentNoteService::list(
        pool.get_ref(),
        church_id,
        member_id,
        &filter,
        has_write,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(notes)))
}

/// Create a note for a student
#[utoipa::path(
    post,
    path = "/api/v1/ebd/students/{member_id}/notes",
    params(("member_id" = Uuid, Path, description = "Member ID")),
    request_body = CreateStudentNoteRequest,
    responses(
        (status = 201, description = "Note created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/students/{member_id}/notes")]
pub async fn create_student_note(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<CreateStudentNoteRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;
    let member_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let note = EbdStudentNoteService::create(pool.get_ref(), church_id, member_id, user_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(note, "Nota registrada")))
}

/// Update a student note
#[utoipa::path(
    put,
    path = "/api/v1/ebd/students/{member_id}/notes/{note_id}",
    params(
        ("member_id" = Uuid, Path, description = "Member ID"),
        ("note_id" = Uuid, Path, description = "Note ID"),
    ),
    request_body = UpdateStudentNoteRequest,
    responses(
        (status = 200, description = "Note updated"),
        (status = 404, description = "Note not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/students/{member_id}/notes/{note_id}")]
pub async fn update_student_note(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
    body: web::Json<UpdateStudentNoteRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;
    let (member_id, note_id) = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let note = EbdStudentNoteService::update(pool.get_ref(), member_id, note_id, user_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(note, "Nota atualizada")))
}

/// Delete a student note
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/students/{member_id}/notes/{note_id}",
    params(
        ("member_id" = Uuid, Path, description = "Member ID"),
        ("note_id" = Uuid, Path, description = "Note ID"),
    ),
    responses(
        (status = 200, description = "Note deleted"),
        (status = 404, description = "Note not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/students/{member_id}/notes/{note_id}")]
pub async fn delete_student_note(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(Uuid, Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let _church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;
    let (member_id, note_id) = path.into_inner();

    EbdStudentNoteService::delete(pool.get_ref(), member_id, note_id, user_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Nota removida")))
}

// ==========================================
// EBD Clone Classes (E7)
// ==========================================

/// Clone classes from one term to another
#[utoipa::path(
    post,
    path = "/api/v1/ebd/terms/{term_id}/clone-classes",
    params(("term_id" = Uuid, Path, description = "Target Term ID")),
    request_body = CloneClassesRequest,
    responses(
        (status = 201, description = "Classes cloned"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/terms/{term_id}/clone-classes")]
pub async fn clone_classes(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
    body: web::Json<CloneClassesRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let target_term_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let classes = EbdClassService::clone_classes(pool.get_ref(), church_id, target_term_id, &body).await?;

    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(pool.get_ref(), church_id, Some(user_id), "create", "ebd_clone_classes", target_term_id).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        classes,
        "Turmas clonadas com sucesso",
    )))
}

// ==========================================
// EBD Advanced Reports (E6)
// ==========================================

/// Get consolidated term report
#[utoipa::path(
    get,
    path = "/api/v1/ebd/reports/term/{term_id}",
    params(("term_id" = Uuid, Path, description = "Term ID")),
    responses(
        (status = 200, description = "Consolidated term report"),
        (status = 401, description = "Not authenticated"),
        (status = 404, description = "Term not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/reports/term/{term_id}")]
pub async fn get_term_report(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let term_id = path.into_inner();

    let report = EbdReportService::term_report(pool.get_ref(), church_id, term_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(report)))
}

/// Get classes ranked by attendance percentage
#[utoipa::path(
    get,
    path = "/api/v1/ebd/reports/term/{term_id}/ranking",
    params(("term_id" = Uuid, Path, description = "Term ID")),
    responses(
        (status = 200, description = "Classes ranked by attendance"),
        (status = 401, description = "Not authenticated"),
        (status = 404, description = "Term not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/reports/term/{term_id}/ranking")]
pub async fn get_term_ranking(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let term_id = path.into_inner();

    let ranking = EbdReportService::term_ranking(pool.get_ref(), church_id, term_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(ranking)))
}

/// Compare multiple terms side by side
#[utoipa::path(
    get,
    path = "/api/v1/ebd/reports/comparison",
    params(("term_ids" = String, Query, description = "Comma-separated term UUIDs")),
    responses(
        (status = 200, description = "Term comparison data"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/reports/comparison")]
pub async fn get_term_comparison(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    query: web::Query<TermComparisonQuery>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let term_ids: Result<Vec<Uuid>, _> = query
        .term_ids
        .split(',')
        .map(|s| s.trim().parse::<Uuid>())
        .collect();

    let term_ids = term_ids.map_err(|_| AppError::validation("term_ids deve conter UUIDs válidos separados por vírgula"))?;

    if term_ids.is_empty() {
        return Err(AppError::validation("Informe ao menos um term_id"));
    }

    let comparison = EbdReportService::term_comparison(pool.get_ref(), church_id, term_ids).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(comparison)))
}

/// Get students with 3+ consecutive absences
#[utoipa::path(
    get,
    path = "/api/v1/ebd/reports/students/attendance",
    responses(
        (status = 200, description = "Students with consecutive absences"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/reports/students/attendance")]
pub async fn get_absent_students(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let absent = EbdReportService::absent_students(pool.get_ref(), church_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(absent)))
}