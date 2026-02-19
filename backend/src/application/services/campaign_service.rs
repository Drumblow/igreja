use crate::application::dto::{CreateCampaignRequest, UpdateCampaignRequest};
use crate::domain::entities::{Campaign, CampaignSummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct CampaignService;

impl CampaignService {
    /// List campaigns with pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        status: Option<&str>,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<CampaignSummary>, i64), AppError> {
        let mut conditions = vec!["c.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if status.is_some() {
            conditions.push(format!("c.status = ${param_idx}"));
            param_idx += 1;
        }

        if search.is_some() {
            conditions.push(format!(
                "unaccent(c.name) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM campaigns c WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT c.id, c.name, c.description, c.goal_amount, c.raised_amount,
                   c.start_date, c.end_date, c.status,
                   (SELECT COUNT(*) FROM financial_entries fe 
                    WHERE fe.campaign_id = c.id AND fe.deleted_at IS NULL AND fe.status != 'cancelado') AS entries_count,
                   c.created_at
            FROM campaigns c
            WHERE {where_clause}
            ORDER BY c.created_at DESC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(s) = status {
            sqlx::Arguments::add(&mut count_args, s).unwrap();
            sqlx::Arguments::add(&mut data_args, s).unwrap();
        }

        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let campaigns = sqlx::query_as_with::<_, CampaignSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((campaigns, total))
    }

    /// Get campaign by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        campaign_id: Uuid,
    ) -> Result<Campaign, AppError> {
        sqlx::query_as::<_, Campaign>(
            "SELECT * FROM campaigns WHERE id = $1 AND church_id = $2",
        )
        .bind(campaign_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Campanha"))
    }

    /// Create a new campaign
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateCampaignRequest,
    ) -> Result<Campaign, AppError> {
        let campaign = sqlx::query_as::<_, Campaign>(
            r#"
            INSERT INTO campaigns (church_id, name, description, goal_amount, start_date, end_date)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(&req.name)
        .bind(&req.description)
        .bind(req.goal_amount)
        .bind(req.start_date)
        .bind(req.end_date)
        .fetch_one(pool)
        .await?;

        Ok(campaign)
    }

    /// Update a campaign
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        campaign_id: Uuid,
        req: &UpdateCampaignRequest,
    ) -> Result<Campaign, AppError> {
        let _existing = Self::get_by_id(pool, church_id, campaign_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut param_index = 3u32;

        sqlx::Arguments::add(&mut args, campaign_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref name) = req.name {
            set_clauses.push(format!("name = ${param_index}"));
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(ref desc) = req.description {
            set_clauses.push(format!("description = ${param_index}"));
            sqlx::Arguments::add(&mut args, desc.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(goal) = req.goal_amount {
            set_clauses.push(format!("goal_amount = ${param_index}"));
            sqlx::Arguments::add(&mut args, goal).unwrap();
            param_index += 1;
        }

        if let Some(end_date) = req.end_date {
            set_clauses.push(format!("end_date = ${param_index}"));
            sqlx::Arguments::add(&mut args, end_date).unwrap();
            param_index += 1;
        }

        if let Some(ref status) = req.status {
            let valid_statuses = ["ativa", "encerrada", "cancelada"];
            if !valid_statuses.contains(&status.as_str()) {
                return Err(AppError::validation(
                    "Status deve ser: ativa, encerrada ou cancelada",
                ));
            }
            set_clauses.push(format!("status = ${param_index}"));
            sqlx::Arguments::add(&mut args, status.as_str()).unwrap();
            param_index += 1;
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, campaign_id).await;
        }

        let sql = format!(
            "UPDATE campaigns SET {} WHERE id = $1 AND church_id = $2 RETURNING *",
            set_clauses.join(", ")
        );

        let campaign = sqlx::query_as_with::<_, Campaign, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(campaign)
    }
}
