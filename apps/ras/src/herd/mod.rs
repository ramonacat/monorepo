use std::sync::Arc;

use sqlx::{query, Pool, Postgres};

pub struct Store {
    pool: Arc<Pool<Postgres>>,
}

impl Store {
    pub fn new(pool: Arc<Pool<Postgres>>) -> Self {
        Self { pool }
    }

    pub async fn update_host(&self, hostname: String, running_closure: String) {
        let mut transaction = self.pool.begin().await.unwrap();

        query!("
                INSERT INTO 
                    hosts AS h(hostname, last_seen, running_closure_path, last_running_closure_change) 
                VALUES($1, NOW(), $2, NOW())
                ON CONFLICT(hostname) DO UPDATE 
                    SET 
                        last_seen = NOW(), 
                        running_closure_path = $2, 
                        last_running_closure_change = CASE 
                            WHEN h.running_closure_path != $2 THEN NOW() 
                            ELSE h.last_running_closure_change 
                        END
              ", &hostname, &running_closure)
            .execute(&mut *transaction)
            .await
            .unwrap();

        transaction.commit().await.unwrap();
    }
}
