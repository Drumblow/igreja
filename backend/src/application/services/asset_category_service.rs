use crate::application::dto::{CreateAssetCategoryRequest, UpdateAssetCategoryRequest};
use crate::domain::entities::{AssetCategory, AssetCategorySummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct AssetCategoryService;

impl AssetCategoryService {
    /// List asset categories with pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<AssetCategorySummary>, i64), AppError> {
        let mut conditions = vec!["ac.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if search.is_some() {
            conditions.push(format!(
                "unaccent(ac.name) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM asset_categories ac WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT ac.id, ac.parent_id, ac.name, ac.useful_life_months, ac.depreciation_rate,
                   (SELECT COUNT(*) FROM assets a WHERE a.category_id = ac.id AND a.deleted_at IS NULL) AS assets_count,
                   ac.created_at
            FROM asset_categories ac
            WHERE {where_clause}
            ORDER BY ac.name ASC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let categories = sqlx::query_as_with::<_, AssetCategorySummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((categories, total))
    }

    /// Get category by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        category_id: Uuid,
    ) -> Result<AssetCategory, AppError> {
        sqlx::query_as::<_, AssetCategory>(
            "SELECT * FROM asset_categories WHERE id = $1 AND church_id = $2",
        )
        .bind(category_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Categoria de patrimônio"))
    }

    /// Create a new asset category
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateAssetCategoryRequest,
    ) -> Result<AssetCategory, AppError> {
        let category = sqlx::query_as::<_, AssetCategory>(
            r#"
            INSERT INTO asset_categories (church_id, parent_id, name, useful_life_months, depreciation_rate)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(req.parent_id)
        .bind(&req.name)
        .bind(req.useful_life_months)
        .bind(req.depreciation_rate)
        .fetch_one(pool)
        .await?;

        Ok(category)
    }

    /// Update an asset category
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        category_id: Uuid,
        req: &UpdateAssetCategoryRequest,
    ) -> Result<AssetCategory, AppError> {
        let _existing = Self::get_by_id(pool, church_id, category_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut param_index = 3u32;

        sqlx::Arguments::add(&mut args, category_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref name) = req.name {
            set_clauses.push(format!("name = ${param_index}"));
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(months) = req.useful_life_months {
            set_clauses.push(format!("useful_life_months = ${param_index}"));
            sqlx::Arguments::add(&mut args, months).unwrap();
            param_index += 1;
        }

        if let Some(rate) = req.depreciation_rate {
            set_clauses.push(format!("depreciation_rate = ${param_index}"));
            sqlx::Arguments::add(&mut args, rate).unwrap();
            param_index += 1;
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, category_id).await;
        }

        let sql = format!(
            "UPDATE asset_categories SET {} WHERE id = $1 AND church_id = $2 RETURNING *",
            set_clauses.join(", ")
        );

        let category = sqlx::query_as_with::<_, AssetCategory, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(category)
    }
}
