use serde::Serialize;
use utoipa::ToSchema;

#[derive(Debug, Serialize, ToSchema)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub data: T,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meta: Option<PaginationMeta>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct PaginationMeta {
    pub page: i64,
    pub per_page: i64,
    pub total: i64,
    pub total_pages: i64,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn ok(data: T) -> Self {
        Self {
            success: true,
            data,
            message: None,
            meta: None,
        }
    }

    pub fn with_message(data: T, message: impl Into<String>) -> Self {
        Self {
            success: true,
            data,
            message: Some(message.into()),
            meta: None,
        }
    }

    pub fn paginated(data: T, page: i64, per_page: i64, total: i64) -> Self {
        let total_pages = (total as f64 / per_page as f64).ceil() as i64;
        Self {
            success: true,
            data,
            message: None,
            meta: Some(PaginationMeta {
                page,
                per_page,
                total,
                total_pages,
            }),
        }
    }
}

#[derive(Debug, serde::Deserialize)]
pub struct PaginationParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub sort_by: Option<String>,
    pub sort_order: Option<String>,
    pub search: Option<String>,
}

impl PaginationParams {
    pub fn page(&self) -> i64 {
        self.page.unwrap_or(1).max(1)
    }

    pub fn per_page(&self) -> i64 {
        self.per_page.unwrap_or(20).clamp(1, 100)
    }

    pub fn offset(&self) -> i64 {
        (self.page() - 1) * self.per_page()
    }
}
