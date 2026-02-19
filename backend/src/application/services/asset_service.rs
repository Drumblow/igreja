use crate::application::dto::{AssetFilter, CreateAssetRequest, UpdateAssetRequest};
use crate::domain::entities::{Asset, AssetSummary};
use crate::errors::AppError;
use chrono::NaiveDate;
use sqlx::PgPool;
use uuid::Uuid;

pub struct AssetService;

impl AssetService {
    /// List assets with pagination and filters
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &AssetFilter,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<AssetSummary>, i64), AppError> {
        let mut conditions = vec![
            "a.church_id = $1".to_string(),
            "a.deleted_at IS NULL".to_string(),
        ];
        let mut param_idx = 2u32;

        if filter.category_id.is_some() {
            conditions.push(format!("a.category_id = ${param_idx}"));
            param_idx += 1;
        }

        if filter.status.is_some() {
            conditions.push(format!("a.status = ${param_idx}"));
            param_idx += 1;
        }

        if filter.condition.is_some() {
            conditions.push(format!("a.condition = ${param_idx}"));
            param_idx += 1;
        }

        if filter.location.is_some() {
            conditions.push(format!(
                "unaccent(a.location) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        if search.is_some() {
            conditions.push(format!(
                "(unaccent(a.description) ILIKE '%' || unaccent(${param_idx}) || '%' OR a.asset_code ILIKE '%' || ${param_idx} || '%')"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM assets a WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT a.id, a.asset_code, a.description,
                   ac.name AS category_name,
                   a.brand, a.model, a.location, a.condition, a.status,
                   a.acquisition_date, a.acquisition_value, a.current_value,
                   a.created_at
            FROM assets a
            LEFT JOIN asset_categories ac ON ac.id = a.category_id
            WHERE {where_clause}
            ORDER BY a.asset_code ASC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        // Helper macro to push args in order
        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(cat_id) = filter.category_id {
            sqlx::Arguments::add(&mut count_args, cat_id).unwrap();
            sqlx::Arguments::add(&mut data_args, cat_id).unwrap();
        }

        if let Some(ref status) = filter.status {
            sqlx::Arguments::add(&mut count_args, status.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, status.as_str()).unwrap();
        }

        if let Some(ref condition) = filter.condition {
            sqlx::Arguments::add(&mut count_args, condition.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, condition.as_str()).unwrap();
        }

        if let Some(ref location) = filter.location {
            sqlx::Arguments::add(&mut count_args, location.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, location.as_str()).unwrap();
        }

        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let assets = sqlx::query_as_with::<_, AssetSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((assets, total))
    }

    /// Get asset by ID with full details
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        asset_id: Uuid,
    ) -> Result<Asset, AppError> {
        sqlx::query_as::<_, Asset>(
            "SELECT * FROM assets WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(asset_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Bem patrimonial"))
    }

    /// Create a new asset
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateAssetRequest,
    ) -> Result<Asset, AppError> {
        // Validate acquisition_type
        if let Some(ref at) = req.acquisition_type {
            let valid = ["compra", "doacao", "construcao", "outro"];
            if !valid.contains(&at.as_str()) {
                return Err(AppError::validation(
                    "Tipo de aquisição deve ser: compra, doacao, construcao ou outro",
                ));
            }
        }

        // Validate condition
        let condition = req.condition.as_deref().unwrap_or("bom");
        let valid_conditions = ["novo", "bom", "regular", "ruim", "inservivel"];
        if !valid_conditions.contains(&condition) {
            return Err(AppError::validation(
                "Condição deve ser: novo, bom, regular, ruim ou inservivel",
            ));
        }

        let asset = sqlx::query_as::<_, Asset>(
            r#"
            INSERT INTO assets (
                church_id, category_id, description, brand, model, serial_number,
                acquisition_date, acquisition_value, acquisition_type, donor_member_id,
                invoice_url, current_value, residual_value, location, condition, notes
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(req.category_id)
        .bind(&req.description)
        .bind(&req.brand)
        .bind(&req.model)
        .bind(&req.serial_number)
        .bind(req.acquisition_date)
        .bind(req.acquisition_value)
        .bind(&req.acquisition_type)
        .bind(req.donor_member_id)
        .bind(&req.invoice_url)
        .bind(req.current_value)
        .bind(req.residual_value)
        .bind(&req.location)
        .bind(condition)
        .bind(&req.notes)
        .fetch_one(pool)
        .await?;

        Ok(asset)
    }

    /// Update an asset
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        asset_id: Uuid,
        req: &UpdateAssetRequest,
    ) -> Result<Asset, AppError> {
        let _existing = Self::get_by_id(pool, church_id, asset_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut pi = 3u32;

        sqlx::Arguments::add(&mut args, asset_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref v) = req.category_id {
            set_clauses.push(format!("category_id = ${pi}"));
            sqlx::Arguments::add(&mut args, *v).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.description {
            set_clauses.push(format!("description = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.brand {
            set_clauses.push(format!("brand = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.model {
            set_clauses.push(format!("model = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.serial_number {
            set_clauses.push(format!("serial_number = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(v) = req.acquisition_date {
            set_clauses.push(format!("acquisition_date = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(v) = req.acquisition_value {
            set_clauses.push(format!("acquisition_value = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.acquisition_type {
            let valid = ["compra", "doacao", "construcao", "outro"];
            if !valid.contains(&v.as_str()) {
                return Err(AppError::validation(
                    "Tipo de aquisição deve ser: compra, doacao, construcao ou outro",
                ));
            }
            set_clauses.push(format!("acquisition_type = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(v) = req.donor_member_id {
            set_clauses.push(format!("donor_member_id = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.invoice_url {
            set_clauses.push(format!("invoice_url = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(v) = req.current_value {
            set_clauses.push(format!("current_value = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(v) = req.residual_value {
            set_clauses.push(format!("residual_value = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.location {
            set_clauses.push(format!("location = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.condition {
            let valid = ["novo", "bom", "regular", "ruim", "inservivel"];
            if !valid.contains(&v.as_str()) {
                return Err(AppError::validation(
                    "Condição deve ser: novo, bom, regular, ruim ou inservivel",
                ));
            }
            set_clauses.push(format!("condition = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.status {
            let valid = ["ativo", "em_manutencao", "baixado", "cedido", "alienado"];
            if !valid.contains(&v.as_str()) {
                return Err(AppError::validation(
                    "Status deve ser: ativo, em_manutencao, baixado, cedido ou alienado",
                ));
            }
            set_clauses.push(format!("status = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;

            // Set status_date to today
            set_clauses.push(format!("status_date = ${pi}"));
            sqlx::Arguments::add(&mut args, chrono::Utc::now().date_naive()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.status_reason {
            set_clauses.push(format!("status_reason = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.notes {
            set_clauses.push(format!("notes = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }

        let _ = pi;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, asset_id).await;
        }

        let sql = format!(
            "UPDATE assets SET {} WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL RETURNING *",
            set_clauses.join(", ")
        );

        let asset = sqlx::query_as_with::<_, Asset, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(asset)
    }

    /// Soft-delete an asset (baixa)
    pub async fn delete(
        pool: &PgPool,
        church_id: Uuid,
        asset_id: Uuid,
        reason: Option<&str>,
    ) -> Result<(), AppError> {
        let _existing = Self::get_by_id(pool, church_id, asset_id).await?;

        let today: NaiveDate = chrono::Utc::now().date_naive();

        sqlx::query(
            r#"
            UPDATE assets
            SET deleted_at = NOW(), status = 'baixado', status_date = $3, status_reason = $4
            WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL
            "#,
        )
        .bind(asset_id)
        .bind(church_id)
        .bind(today)
        .bind(reason)
        .execute(pool)
        .await?;

        Ok(())
    }
}
