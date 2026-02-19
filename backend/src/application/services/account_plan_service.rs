use crate::application::dto::{CreateAccountPlanRequest, UpdateAccountPlanRequest};
use crate::domain::entities::{AccountPlan, AccountPlanSummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct AccountPlanService;

impl AccountPlanService {
    /// List account plans with optional type filter
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        plan_type: Option<&str>,
        is_active: Option<bool>,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<AccountPlanSummary>, i64), AppError> {
        let mut conditions = vec!["ap.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if plan_type.is_some() {
            conditions.push(format!("ap.type = ${param_idx}"));
            param_idx += 1;
        }

        if is_active.is_some() {
            conditions.push(format!("ap.is_active = ${param_idx}"));
            param_idx += 1;
        }

        if search.is_some() {
            conditions.push(format!(
                "unaccent(ap.name) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM account_plans ap WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT ap.id, ap.parent_id, ap.code, ap.name,
                   ap.type, ap.level, ap.is_active,
                   p.name AS parent_name,
                   (SELECT COUNT(*) FROM account_plans c WHERE c.parent_id = ap.id) AS children_count,
                   ap.created_at
            FROM account_plans ap
            LEFT JOIN account_plans p ON p.id = ap.parent_id
            WHERE {where_clause}
            ORDER BY ap.code ASC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(pt) = plan_type {
            sqlx::Arguments::add(&mut count_args, pt).unwrap();
            sqlx::Arguments::add(&mut data_args, pt).unwrap();
        }

        if let Some(active) = is_active {
            sqlx::Arguments::add(&mut count_args, active).unwrap();
            sqlx::Arguments::add(&mut data_args, active).unwrap();
        }

        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let plans = sqlx::query_as_with::<_, AccountPlanSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((plans, total))
    }

    /// Get account plan by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        plan_id: Uuid,
    ) -> Result<AccountPlan, AppError> {
        sqlx::query_as::<_, AccountPlan>(
            "SELECT id, church_id, parent_id, code, name, type, level, is_active, created_at, updated_at FROM account_plans WHERE id = $1 AND church_id = $2",
        )
        .bind(plan_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Plano de contas"))
    }

    /// Create a new account plan
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateAccountPlanRequest,
    ) -> Result<AccountPlan, AppError> {
        // Validate type
        if req.plan_type != "receita" && req.plan_type != "despesa" {
            return Err(AppError::validation("Tipo deve ser 'receita' ou 'despesa'"));
        }

        // Check unique code per church
        let existing = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM account_plans WHERE church_id = $1 AND code = $2",
        )
        .bind(church_id)
        .bind(&req.code)
        .fetch_optional(pool)
        .await?;

        if existing.is_some() {
            return Err(AppError::Conflict("Código já existe nesta igreja".into()));
        }

        // If there's a parent, verify it exists and determine level
        let level = if let Some(parent_id) = req.parent_id {
            let parent = Self::get_by_id(pool, church_id, parent_id).await?;
            parent.level + 1
        } else {
            req.level.unwrap_or(1)
        };

        let plan = sqlx::query_as::<_, AccountPlan>(
            r#"
            INSERT INTO account_plans (church_id, parent_id, code, name, type, level)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, church_id, parent_id, code, name, type, level, is_active, created_at, updated_at
            "#,
        )
        .bind(church_id)
        .bind(req.parent_id)
        .bind(&req.code)
        .bind(&req.name)
        .bind(&req.plan_type)
        .bind(level)
        .fetch_one(pool)
        .await?;

        Ok(plan)
    }

    /// Update an account plan
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        plan_id: Uuid,
        req: &UpdateAccountPlanRequest,
    ) -> Result<AccountPlan, AppError> {
        let _existing = Self::get_by_id(pool, church_id, plan_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut param_index = 3u32;

        sqlx::Arguments::add(&mut args, plan_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref code) = req.code {
            // Check unique code
            let existing = sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM account_plans WHERE church_id = $1 AND code = $2 AND id != $3",
            )
            .bind(church_id)
            .bind(code.as_str())
            .bind(plan_id)
            .fetch_optional(pool)
            .await?;

            if existing.is_some() {
                return Err(AppError::Conflict("Código já existe nesta igreja".into()));
            }

            set_clauses.push(format!("code = ${param_index}"));
            sqlx::Arguments::add(&mut args, code.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(ref name) = req.name {
            set_clauses.push(format!("name = ${param_index}"));
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(is_active) = req.is_active {
            set_clauses.push(format!("is_active = ${param_index}"));
            sqlx::Arguments::add(&mut args, is_active).unwrap();
            param_index += 1;
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, plan_id).await;
        }

        let sql = format!(
            "UPDATE account_plans SET {} WHERE id = $1 AND church_id = $2 RETURNING id, church_id, parent_id, code, name, type, level, is_active, created_at, updated_at",
            set_clauses.join(", ")
        );

        let plan = sqlx::query_as_with::<_, AccountPlan, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(plan)
    }
}
