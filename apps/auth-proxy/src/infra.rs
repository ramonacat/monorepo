use diesel_async::{AsyncConnection as _, AsyncPgConnection};

#[derive(Debug, Clone)]
pub struct DatabaseConnector {
    url: String,
}

impl DatabaseConnector {
    pub fn new(url: String) -> Self {
        Self { url }
    }

    pub async fn connect(&self) -> AsyncPgConnection {
        AsyncPgConnection::establish(&self.url)
            .await
            .expect("database connection did not succeed")
    }
}
