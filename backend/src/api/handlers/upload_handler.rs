use actix_multipart::Multipart;
use actix_web::{delete, post, web, HttpRequest, HttpResponse};
use futures_util::StreamExt;
use serde::Deserialize;
use utoipa::ToSchema;

use crate::api::middleware::{auth_middleware, get_church_id};
use crate::api::response::ApiResponse;
use crate::config::AppConfig;
use crate::errors::AppError;
use crate::infrastructure::cloudinary::CloudinaryService;

/// Upload image to Cloudinary
///
/// Receives multipart form with file and optional folder parameter.
/// Returns the Cloudinary URL for the uploaded image.
#[utoipa::path(
    post,
    path = "/api/v1/upload/image",
    request_body(content_type = "multipart/form-data"),
    responses(
        (status = 200, description = "Image uploaded successfully"),
        (status = 400, description = "Invalid file"),
        (status = 401, description = "Unauthorized"),
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/upload/image")]
pub async fn upload_image(
    req: HttpRequest,
    config: web::Data<AppConfig>,
    cloudinary: web::Data<CloudinaryService>,
    mut payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let claims = auth_middleware(req, config.clone()).await?;
    let church_id = get_church_id(&claims)?;

    let mut file_bytes: Vec<u8> = Vec::new();
    let mut file_name = String::from("upload.jpg");
    let mut folder = format!("igreja/{church_id}");

    while let Some(item) = payload.next().await {
        let mut field = item.map_err(|e| AppError::validation(format!("Erro no multipart: {e}")))?;

        let field_name = field.name().map(|n| n.to_string()).unwrap_or_default();

        match field_name.as_str() {
            "file" => {
                if let Some(cd) = field.content_disposition() {
                    if let Some(name) = cd.get_filename() {
                        file_name = name.to_string();
                    }
                }
                while let Some(chunk) = field.next().await {
                    let data = chunk.map_err(|e| {
                        AppError::validation(format!("Erro ao ler chunk: {e}"))
                    })?;
                    file_bytes.extend_from_slice(&data);
                }
            }
            "folder" => {
                let mut buf = Vec::new();
                while let Some(chunk) = field.next().await {
                    let data = chunk.map_err(|e| {
                        AppError::validation(format!("Erro ao ler campo: {e}"))
                    })?;
                    buf.extend_from_slice(&data);
                }
                if let Ok(f) = String::from_utf8(buf) {
                    if !f.is_empty() {
                        folder = format!("igreja/{church_id}/{f}");
                    }
                }
            }
            _ => {}
        }
    }

    if file_bytes.is_empty() {
        return Err(AppError::validation("Nenhum arquivo enviado"));
    }

    // Validate file size (max from config)
    let max_bytes = config.max_upload_size_mb * 1024 * 1024;
    if file_bytes.len() > max_bytes {
        return Err(AppError::validation(format!(
            "Arquivo muito grande. Máximo: {}MB",
            config.max_upload_size_mb
        )));
    }

    // Validate it's an image by checking magic bytes
    let is_image = file_bytes.len() >= 4
        && (file_bytes.starts_with(&[0xFF, 0xD8, 0xFF])       // JPEG
            || file_bytes.starts_with(&[0x89, 0x50, 0x4E, 0x47]) // PNG
            || file_bytes.starts_with(b"GIF8")                    // GIF
            || file_bytes.starts_with(b"RIFF"));                  // WebP

    if !is_image {
        return Err(AppError::validation(
            "Formato inválido. Envie JPEG, PNG, GIF ou WebP",
        ));
    }

    let result = cloudinary.upload_image(file_bytes, &file_name, &folder).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({
        "url": result.secure_url,
        "public_id": result.public_id,
        "width": result.width,
        "height": result.height,
        "format": result.format,
        "bytes": result.bytes,
    }))))
}

#[derive(Deserialize, ToSchema)]
pub struct DeleteImageRequest {
    pub public_id: String,
}

/// Delete image from Cloudinary
#[utoipa::path(
    delete,
    path = "/api/v1/upload/image",
    request_body = DeleteImageRequest,
    responses(
        (status = 200, description = "Image deleted successfully"),
        (status = 401, description = "Unauthorized"),
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/upload/image")]
pub async fn delete_image(
    req: HttpRequest,
    config: web::Data<AppConfig>,
    cloudinary: web::Data<CloudinaryService>,
    body: web::Json<DeleteImageRequest>,
) -> Result<HttpResponse, AppError> {
    let _claims = auth_middleware(req, config).await?;

    let result = cloudinary.delete_image(&body.public_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({
        "result": result.result,
    }))))
}
