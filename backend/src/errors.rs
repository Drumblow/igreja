use actix_web::{HttpResponse, ResponseError};
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct ErrorBody {
    pub code: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<Vec<FieldError>>,
}

#[derive(Debug, Clone, Serialize)]
pub struct FieldError {
    pub field: String,
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub success: bool,
    pub error: ErrorBody,
}

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("Validation error: {message}")]
    Validation {
        message: String,
        details: Option<Vec<FieldError>>,
    },

    #[error("Unauthorized: {0}")]
    Unauthorized(String),

    #[error("Forbidden: {0}")]
    Forbidden(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Conflict: {0}")]
    Conflict(String),

    #[error("Internal error: {0}")]
    Internal(String),

    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
}

impl AppError {
    pub fn validation(message: impl Into<String>) -> Self {
        Self::Validation {
            message: message.into(),
            details: None,
        }
    }

    #[allow(dead_code)]
    pub fn validation_with_details(message: impl Into<String>, details: Vec<FieldError>) -> Self {
        Self::Validation {
            message: message.into(),
            details: Some(details),
        }
    }

    pub fn not_found(entity: &str) -> Self {
        Self::NotFound(format!("{entity} não encontrado"))
    }

    pub fn conflict(message: impl Into<String>) -> Self {
        Self::Conflict(message.into())
    }
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, code, message, details): (actix_web::http::StatusCode, &str, String, Option<Vec<FieldError>>) = match self {
            AppError::Validation { message, details } => (
                actix_web::http::StatusCode::BAD_REQUEST,
                "VALIDATION_ERROR",
                message.clone(),
                details.clone(),
            ),
            AppError::Unauthorized(msg) => (
                actix_web::http::StatusCode::UNAUTHORIZED,
                "UNAUTHORIZED",
                msg.clone(),
                None,
            ),
            AppError::Forbidden(msg) => (
                actix_web::http::StatusCode::FORBIDDEN,
                "FORBIDDEN",
                msg.clone(),
                None,
            ),
            AppError::NotFound(msg) => (
                actix_web::http::StatusCode::NOT_FOUND,
                "NOT_FOUND",
                msg.clone(),
                None,
            ),
            AppError::Conflict(msg) => (
                actix_web::http::StatusCode::CONFLICT,
                "CONFLICT",
                msg.clone(),
                None,
            ),
            AppError::Internal(msg) => {
                tracing::error!("Internal error: {}", msg);
                (
                    actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                    "INTERNAL_ERROR",
                    "Erro interno do servidor".to_string(),
                    None,
                )
            }
            AppError::Database(e) => {
                tracing::error!("Database error: {:?}", e);
                (
                    actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                    "INTERNAL_ERROR",
                    "Erro interno do servidor".to_string(),
                    None,
                )
            }
        };

        HttpResponse::build(status).json(ErrorResponse {
            success: false,
            error: ErrorBody {
                code: code.to_string(),
                message,
                details,
            },
        })
    }
}
