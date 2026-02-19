use crate::application::dto::{CreateChurchRequest, UpdateChurchRequest, ChurchSummary};
use crate::domain::entities::church::Church;
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct ChurchService;

impl ChurchService {
    /// List all churches with pagination (super_admin only)
    pub async fn list(
        pool: &PgPool,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<ChurchSummary>, i64), AppError> {
        if let Some(term) = search {
            let pattern = format!("%{term}%");
            let total = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM churches WHERE unaccent(name) ILIKE '%' || unaccent($1) || '%'",
            )
            .bind(&pattern)
            .fetch_one(pool)
            .await?;

            let churches = sqlx::query_as::<_, ChurchSummaryRow>(
                r#"SELECT c.id, c.name, c.denomination, c.city, c.state, c.pastor_name, c.is_active,
                   COALESCE((SELECT COUNT(*) FROM members m WHERE m.church_id = c.id AND m.deleted_at IS NULL), 0) AS member_count
                   FROM churches c
                   WHERE unaccent(c.name) ILIKE '%' || unaccent($1) || '%'
                   ORDER BY c.name ASC LIMIT $2 OFFSET $3"#,
            )
            .bind(&pattern)
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await?;

            Ok((churches.into_iter().map(|r| r.into()).collect(), total))
        } else {
            let total = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM churches",
            )
            .fetch_one(pool)
            .await?;

            let churches = sqlx::query_as::<_, ChurchSummaryRow>(
                r#"SELECT c.id, c.name, c.denomination, c.city, c.state, c.pastor_name, c.is_active,
                   COALESCE((SELECT COUNT(*) FROM members m WHERE m.church_id = c.id AND m.deleted_at IS NULL), 0) AS member_count
                   FROM churches c
                   ORDER BY c.name ASC LIMIT $1 OFFSET $2"#,
            )
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await?;

            Ok((churches.into_iter().map(|r| r.into()).collect(), total))
        }
    }

    /// Get church by ID
    pub async fn get_by_id(pool: &PgPool, church_id: Uuid) -> Result<Church, AppError> {
        sqlx::query_as::<_, Church>(
            "SELECT * FROM churches WHERE id = $1",
        )
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Igreja"))
    }

    /// Create a new church (super_admin only)
    pub async fn create(
        pool: &PgPool,
        req: &CreateChurchRequest,
    ) -> Result<Church, AppError> {
        let church = sqlx::query_as::<_, Church>(
            r#"INSERT INTO churches (name, legal_name, cnpj, email, phone, website,
                zip_code, street, number, complement, neighborhood, city, state,
                denomination, founded_at, pastor_name)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
               RETURNING *"#,
        )
        .bind(&req.name)
        .bind(&req.legal_name)
        .bind(&req.cnpj)
        .bind(&req.email)
        .bind(&req.phone)
        .bind(&req.website)
        .bind(&req.zip_code)
        .bind(&req.street)
        .bind(&req.number)
        .bind(&req.complement)
        .bind(&req.neighborhood)
        .bind(&req.city)
        .bind(&req.state)
        .bind(&req.denomination)
        .bind(&req.founded_at)
        .bind(&req.pastor_name)
        .fetch_one(pool)
        .await?;

        Ok(church)
    }

    /// Update an existing church
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        req: &UpdateChurchRequest,
    ) -> Result<Church, AppError> {
        // Get existing
        let existing = Self::get_by_id(pool, church_id).await?;

        let church = sqlx::query_as::<_, Church>(
            r#"UPDATE churches SET
                name = $2, legal_name = $3, cnpj = $4, email = $5, phone = $6, website = $7,
                zip_code = $8, street = $9, number = $10, complement = $11,
                neighborhood = $12, city = $13, state = $14,
                logo_url = $15, denomination = $16, founded_at = $17, pastor_name = $18,
                is_active = $19, updated_at = NOW()
               WHERE id = $1
               RETURNING *"#,
        )
        .bind(church_id)
        .bind(req.name.as_deref().unwrap_or(&existing.name))
        .bind(req.legal_name.as_ref().or(existing.legal_name.as_ref()))
        .bind(req.cnpj.as_ref().or(existing.cnpj.as_ref()))
        .bind(req.email.as_ref().or(existing.email.as_ref()))
        .bind(req.phone.as_ref().or(existing.phone.as_ref()))
        .bind(req.website.as_ref().or(existing.website.as_ref()))
        .bind(req.zip_code.as_ref().or(existing.zip_code.as_ref()))
        .bind(req.street.as_ref().or(existing.street.as_ref()))
        .bind(req.number.as_ref().or(existing.number.as_ref()))
        .bind(req.complement.as_ref().or(existing.complement.as_ref()))
        .bind(req.neighborhood.as_ref().or(existing.neighborhood.as_ref()))
        .bind(req.city.as_ref().or(existing.city.as_ref()))
        .bind(req.state.as_ref().or(existing.state.as_ref()))
        .bind(req.logo_url.as_ref().or(existing.logo_url.as_ref()))
        .bind(req.denomination.as_ref().or(existing.denomination.as_ref()))
        .bind(req.founded_at.or(existing.founded_at))
        .bind(req.pastor_name.as_ref().or(existing.pastor_name.as_ref()))
        .bind(req.is_active.unwrap_or(existing.is_active))
        .fetch_one(pool)
        .await?;

        Ok(church)
    }
}

/// Internal row struct for the summary query
#[derive(Debug, sqlx::FromRow)]
struct ChurchSummaryRow {
    pub id: Uuid,
    pub name: String,
    pub denomination: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub pastor_name: Option<String>,
    pub is_active: bool,
    pub member_count: i64,
}

impl From<ChurchSummaryRow> for ChurchSummary {
    fn from(row: ChurchSummaryRow) -> Self {
        ChurchSummary {
            id: row.id,
            name: row.name,
            denomination: row.denomination,
            city: row.city,
            state: row.state,
            pastor_name: row.pastor_name,
            is_active: row.is_active,
            member_count: row.member_count,
        }
    }
}
