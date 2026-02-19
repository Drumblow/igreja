use crate::application::dto::{AssetLoanFilter, CreateAssetLoanRequest, ReturnAssetLoanRequest};
use crate::domain::entities::{AssetLoan, AssetLoanSummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct AssetLoanService;

impl AssetLoanService {
    /// List asset loans with pagination and filters
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &AssetLoanFilter,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<AssetLoanSummary>, i64), AppError> {
        let mut conditions = vec!["al.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if filter.asset_id.is_some() {
            conditions.push(format!("al.asset_id = ${param_idx}"));
            param_idx += 1;
        }

        if filter.borrower_member_id.is_some() {
            conditions.push(format!("al.borrower_member_id = ${param_idx}"));
            param_idx += 1;
        }

        if let Some(ref status) = filter.status {
            match status.as_str() {
                "active" => conditions.push("al.actual_return_date IS NULL".to_string()),
                "returned" => conditions.push("al.actual_return_date IS NOT NULL".to_string()),
                "overdue" => conditions.push(
                    "al.actual_return_date IS NULL AND al.expected_return_date < CURRENT_DATE"
                        .to_string(),
                ),
                _ => {}
            }
        }

        if search.is_some() {
            conditions.push(format!(
                "(unaccent(a.description) ILIKE '%' || unaccent(${param_idx}) || '%' OR unaccent(m.full_name) ILIKE '%' || unaccent(${param_idx}) || '%')"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            r#"SELECT COUNT(*)
            FROM asset_loans al
            LEFT JOIN assets a ON a.id = al.asset_id
            LEFT JOIN members m ON m.id = al.borrower_member_id
            WHERE {where_clause}"#
        );

        let query_sql = format!(
            r#"
            SELECT al.id, al.asset_id, a.asset_code, a.description AS asset_description,
                   al.borrower_member_id, m.full_name AS borrower_name,
                   al.loan_date, al.expected_return_date, al.actual_return_date,
                   al.condition_out, al.condition_in, al.created_at
            FROM asset_loans al
            LEFT JOIN assets a ON a.id = al.asset_id
            LEFT JOIN members m ON m.id = al.borrower_member_id
            WHERE {where_clause}
            ORDER BY al.loan_date DESC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(asset_id) = filter.asset_id {
            sqlx::Arguments::add(&mut count_args, asset_id).unwrap();
            sqlx::Arguments::add(&mut data_args, asset_id).unwrap();
        }

        if let Some(borrower_id) = filter.borrower_member_id {
            sqlx::Arguments::add(&mut count_args, borrower_id).unwrap();
            sqlx::Arguments::add(&mut data_args, borrower_id).unwrap();
        }

        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let loans = sqlx::query_as_with::<_, AssetLoanSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((loans, total))
    }

    /// Get loan by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        loan_id: Uuid,
    ) -> Result<AssetLoan, AppError> {
        sqlx::query_as::<_, AssetLoan>(
            "SELECT * FROM asset_loans WHERE id = $1 AND church_id = $2",
        )
        .bind(loan_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Empréstimo"))
    }

    /// Create a new asset loan
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateAssetLoanRequest,
    ) -> Result<AssetLoan, AppError> {
        // Validate that the asset exists and is available
        let asset_status: Option<String> = sqlx::query_scalar(
            "SELECT status FROM assets WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(req.asset_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?;

        match asset_status {
            None => return Err(AppError::not_found("Bem patrimonial")),
            Some(ref s) if s != "ativo" => {
                return Err(AppError::validation(format!(
                    "Bem não disponível para empréstimo (status atual: {s})"
                )));
            }
            _ => {}
        }

        // Check if asset is already loaned
        let active_loan: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM asset_loans WHERE asset_id = $1 AND church_id = $2 AND actual_return_date IS NULL",
        )
        .bind(req.asset_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        if active_loan > 0 {
            return Err(AppError::Conflict(
                "Este bem já está emprestado".into(),
            ));
        }

        // Create the loan
        let loan = sqlx::query_as::<_, AssetLoan>(
            r#"
            INSERT INTO asset_loans (
                church_id, asset_id, borrower_member_id, loan_date,
                expected_return_date, condition_out, notes
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(req.asset_id)
        .bind(req.borrower_member_id)
        .bind(req.loan_date)
        .bind(req.expected_return_date)
        .bind(&req.condition_out)
        .bind(&req.notes)
        .fetch_one(pool)
        .await?;

        // Update asset status to "cedido"
        sqlx::query(
            "UPDATE assets SET status = 'cedido', status_date = CURRENT_DATE WHERE id = $1 AND church_id = $2",
        )
        .bind(req.asset_id)
        .bind(church_id)
        .execute(pool)
        .await?;

        Ok(loan)
    }

    /// Return an asset loan
    pub async fn return_loan(
        pool: &PgPool,
        church_id: Uuid,
        loan_id: Uuid,
        req: &ReturnAssetLoanRequest,
    ) -> Result<AssetLoan, AppError> {
        let existing = Self::get_by_id(pool, church_id, loan_id).await?;

        if existing.actual_return_date.is_some() {
            return Err(AppError::Conflict(
                "Este empréstimo já foi devolvido".into(),
            ));
        }

        let loan = sqlx::query_as::<_, AssetLoan>(
            r#"
            UPDATE asset_loans
            SET actual_return_date = $1, condition_in = $2, notes = COALESCE($3, notes)
            WHERE id = $4 AND church_id = $5
            RETURNING *
            "#,
        )
        .bind(req.actual_return_date)
        .bind(&req.condition_in)
        .bind(&req.notes)
        .bind(loan_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        // Return asset to 'ativo'
        sqlx::query(
            "UPDATE assets SET status = 'ativo', status_date = CURRENT_DATE WHERE id = $1 AND church_id = $2 AND status = 'cedido'",
        )
        .bind(existing.asset_id)
        .bind(church_id)
        .execute(pool)
        .await?;

        Ok(loan)
    }
}
