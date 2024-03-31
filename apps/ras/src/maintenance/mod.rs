use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

use thiserror::Error;
use tracing::info;

#[derive(Error, Debug)]
pub enum Error {
    #[error("Already in progress")]
    AlreadyInProgress,
    #[error("DB: {0}")]
    DB(#[from] tokio_postgres::Error),
}

#[derive(Debug)]
pub struct MonitoringMaintainer {
    postgres_connection: Arc<tokio_postgres::Client>,
    maintenance_in_progress: Arc<AtomicBool>,
}

impl MonitoringMaintainer {
    pub fn new(postgres_connection: Arc<tokio_postgres::Client>) -> Self {
        Self {
            postgres_connection,
            maintenance_in_progress: Arc::new(AtomicBool::new(false)),
        }
    }

    #[tracing::instrument]
    pub async fn execute(&self) -> Result<(), Error> {
        if self
            .maintenance_in_progress
            .compare_exchange(false, true, Ordering::Acquire, Ordering::Relaxed)
            .is_err()
        {
            return Err(Error::AlreadyInProgress);
        }

        let rows = self
            .postgres_connection
            .query(
                "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'",
                &[],
            )
            .await?;

        for row in rows {
            let delete_query = format!(
                "DELETE FROM {} WHERE time < (NOW() - '30 days'::interval)",
                row.get::<_, String>(0)
            );
            let affected_rows = self.postgres_connection.execute(&delete_query, &[]).await?;

            info!(
                "Executed {query}, affected rows: {affected_rows}",
                query = delete_query,
                affected_rows = affected_rows
            );
        }

        self.maintenance_in_progress.store(false, Ordering::Release);

        Ok(())
    }
}
