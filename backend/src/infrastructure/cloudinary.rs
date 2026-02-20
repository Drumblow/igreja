use reqwest::multipart;
use serde::{Deserialize, Serialize};
use sha1::{Digest, Sha1};

use crate::config::AppConfig;
use crate::errors::AppError;

#[derive(Clone)]
pub struct CloudinaryService {
    cloud_name: String,
    api_key: String,
    api_secret: String,
    client: reqwest::Client,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CloudinaryUploadResult {
    pub public_id: String,
    pub secure_url: String,
    pub url: String,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub format: Option<String>,
    pub bytes: Option<u64>,
    pub resource_type: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CloudinaryDeleteResult {
    pub result: String,
}

impl CloudinaryService {
    pub fn new(config: &AppConfig) -> Self {
        Self {
            cloud_name: config.cloudinary_cloud_name.clone(),
            api_key: config.cloudinary_api_key.clone(),
            api_secret: config.cloudinary_api_secret.clone(),
            client: reqwest::Client::new(),
        }
    }

    pub fn is_configured(&self) -> bool {
        !self.cloud_name.is_empty() && !self.api_key.is_empty() && !self.api_secret.is_empty()
    }

    /// Generate SHA-1 signature for Cloudinary API
    fn generate_signature(&self, params: &[(&str, &str)]) -> String {
        let mut sorted: Vec<(&str, &str)> = params.to_vec();
        sorted.sort_by_key(|&(k, _)| k);

        let to_sign: String = sorted
            .iter()
            .map(|(k, v)| format!("{k}={v}"))
            .collect::<Vec<_>>()
            .join("&");

        let mut hasher = Sha1::new();
        hasher.update(format!("{to_sign}{}", self.api_secret));
        format!("{:x}", hasher.finalize())
    }

    /// Upload image bytes to Cloudinary
    pub async fn upload_image(
        &self,
        file_bytes: Vec<u8>,
        file_name: &str,
        folder: &str,
    ) -> Result<CloudinaryUploadResult, AppError> {
        if !self.is_configured() {
            return Err(AppError::Internal("Cloudinary não configurado".into()));
        }

        let timestamp = chrono::Utc::now().timestamp().to_string();
        let params = vec![
            ("folder", folder),
            ("timestamp", &timestamp),
        ];
        let signature = self.generate_signature(&params);

        let part = multipart::Part::bytes(file_bytes)
            .file_name(file_name.to_string())
            .mime_str("image/jpeg")
            .map_err(|e| AppError::Internal(format!("Erro ao criar upload: {e}")))?;

        let form = multipart::Form::new()
            .part("file", part)
            .text("folder", folder.to_string())
            .text("timestamp", timestamp)
            .text("api_key", self.api_key.clone())
            .text("signature", signature);

        let url = format!(
            "https://api.cloudinary.com/v1_1/{}/image/upload",
            self.cloud_name
        );

        let response = self
            .client
            .post(&url)
            .multipart(form)
            .send()
            .await
            .map_err(|e| AppError::Internal(format!("Erro no upload Cloudinary: {e}")))?;

        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_default();
            tracing::error!("Cloudinary upload error: {error_text}");
            return Err(AppError::Internal(format!(
                "Cloudinary retornou erro: {error_text}"
            )));
        }

        response
            .json::<CloudinaryUploadResult>()
            .await
            .map_err(|e| AppError::Internal(format!("Erro ao parsear resposta Cloudinary: {e}")))
    }

    /// Delete image from Cloudinary by public_id
    pub async fn delete_image(&self, public_id: &str) -> Result<CloudinaryDeleteResult, AppError> {
        if !self.is_configured() {
            return Err(AppError::Internal("Cloudinary não configurado".into()));
        }

        let timestamp = chrono::Utc::now().timestamp().to_string();
        let params = vec![
            ("public_id", public_id),
            ("timestamp", &timestamp),
        ];
        let signature = self.generate_signature(&params);

        let url = format!(
            "https://api.cloudinary.com/v1_1/{}/image/destroy",
            self.cloud_name
        );

        let response = self
            .client
            .post(&url)
            .form(&[
                ("public_id", public_id),
                ("timestamp", &timestamp),
                ("api_key", &self.api_key),
                ("signature", &signature),
            ])
            .send()
            .await
            .map_err(|e| AppError::Internal(format!("Erro ao deletar no Cloudinary: {e}")))?;

        response
            .json::<CloudinaryDeleteResult>()
            .await
            .map_err(|e| AppError::Internal(format!("Erro ao parsear resposta: {e}")))
    }
}
