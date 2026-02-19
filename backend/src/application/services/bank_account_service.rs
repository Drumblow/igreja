use crate::application::dto::{CreateBankAccountRequest, UpdateBankAccountRequest};
use crate::domain::entities::BankAccount;
use crate::errors::AppError;
use rust_decimal::Decimal;
use sqlx::PgPool;
use uuid::Uuid;

pub struct BankAccountService;

impl BankAccountService {
    /// List bank accounts
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        is_active: Option<bool>,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<BankAccount>, i64), AppError> {
        let mut conditions = vec!["church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if is_active.is_some() {
            conditions.push(format!("is_active = ${param_idx}"));
            param_idx += 1;
        }

        if search.is_some() {
            conditions.push(format!(
                "unaccent(name) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM bank_accounts WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT id, church_id, name, type, bank_name, agency, account_number,
                   initial_balance, current_balance, is_active, created_at, updated_at
            FROM bank_accounts
            WHERE {where_clause}
            ORDER BY name ASC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

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

        let accounts = sqlx::query_as_with::<_, BankAccount, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((accounts, total))
    }

    /// Get bank account by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        account_id: Uuid,
    ) -> Result<BankAccount, AppError> {
        sqlx::query_as::<_, BankAccount>(
            "SELECT id, church_id, name, type, bank_name, agency, account_number, initial_balance, current_balance, is_active, created_at, updated_at FROM bank_accounts WHERE id = $1 AND church_id = $2",
        )
        .bind(account_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Conta bancária"))
    }

    /// Create a new bank account
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateBankAccountRequest,
    ) -> Result<BankAccount, AppError> {
        let valid_types = ["caixa", "conta_corrente", "poupanca", "digital"];
        if !valid_types.contains(&req.account_type.as_str()) {
            return Err(AppError::validation(
                "Tipo deve ser: caixa, conta_corrente, poupanca ou digital",
            ));
        }

        let initial_balance = req.initial_balance.unwrap_or(Decimal::ZERO);

        let account = sqlx::query_as::<_, BankAccount>(
            r#"
            INSERT INTO bank_accounts (church_id, name, type, bank_name, agency, account_number, initial_balance, current_balance)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
            RETURNING id, church_id, name, type, bank_name, agency, account_number, initial_balance, current_balance, is_active, created_at, updated_at
            "#,
        )
        .bind(church_id)
        .bind(&req.name)
        .bind(&req.account_type)
        .bind(&req.bank_name)
        .bind(&req.agency)
        .bind(&req.account_number)
        .bind(initial_balance)
        .fetch_one(pool)
        .await?;

        Ok(account)
    }

    /// Update a bank account
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        account_id: Uuid,
        req: &UpdateBankAccountRequest,
    ) -> Result<BankAccount, AppError> {
        let _existing = Self::get_by_id(pool, church_id, account_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut param_index = 3u32;

        sqlx::Arguments::add(&mut args, account_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref name) = req.name {
            set_clauses.push(format!("name = ${param_index}"));
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(ref bank_name) = req.bank_name {
            set_clauses.push(format!("bank_name = ${param_index}"));
            sqlx::Arguments::add(&mut args, bank_name.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(ref agency) = req.agency {
            set_clauses.push(format!("agency = ${param_index}"));
            sqlx::Arguments::add(&mut args, agency.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(ref account_number) = req.account_number {
            set_clauses.push(format!("account_number = ${param_index}"));
            sqlx::Arguments::add(&mut args, account_number.as_str()).unwrap();
            param_index += 1;
        }

        if let Some(is_active) = req.is_active {
            set_clauses.push(format!("is_active = ${param_index}"));
            sqlx::Arguments::add(&mut args, is_active).unwrap();
            param_index += 1;
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, account_id).await;
        }

        let sql = format!(
            "UPDATE bank_accounts SET {} WHERE id = $1 AND church_id = $2 RETURNING id, church_id, name, type, bank_name, agency, account_number, initial_balance, current_balance, is_active, created_at, updated_at",
            set_clauses.join(", ")
        );

        let account = sqlx::query_as_with::<_, BankAccount, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(account)
    }
}
