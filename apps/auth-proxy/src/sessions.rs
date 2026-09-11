use axum::extract::FromRequestParts;
use axum::response::Response;
use axum_extra::extract::CookieJar;
use axum_extra::extract::cookie::{Cookie, Expiration};
use chrono::{DateTime, Days, Utc};
use diesel::QueryDsl as _;
use diesel::dsl::insert_into;
use diesel::upsert::excluded;
use diesel::{ExpressionMethods, OptionalExtension};
use diesel_async::RunQueryDsl;
use futures::future::BoxFuture;
use http::header::SET_COOKIE;
use http::{HeaderValue, Request};
use serde::{Deserialize, Serialize};
use tower::{Layer, Service};
use uuid::Uuid;

use crate::infra::DatabaseConnector;
use crate::oauth::{OAuthSessionData, RamonaTokenSessionData};

const COOKIE_NAME_SESSION_ID: &str = "ramona-session-id";

#[derive(Debug, Serialize, Deserialize, Default, Clone)]
pub struct SessionData {
    pub oauth: Option<OAuthSessionData>,
    pub token: Option<RamonaTokenSessionData>,
}

#[derive(Debug, Clone)]
struct SessionStore {
    database: DatabaseConnector,
}

#[derive(Debug, Clone)]
pub struct SessionHandle {
    id: Uuid,
    store: SessionStore,
}

impl SessionHandle {
    pub async fn data(&self) -> SessionData {
        self.store.get(self.id).await
    }

    pub async fn update(&self, callback: impl FnOnce(&mut SessionData)) {
        let mut data = self.data().await;
        callback(&mut data);

        self.store
            .upsert(self.id, data, Utc::now() + Days::new(7))
            .await;
    }
}

impl SessionStore {
    pub fn new(database: DatabaseConnector) -> Self {
        Self { database }
    }

    async fn get(&self, session_id: Uuid) -> SessionData {
        use crate::schema::sessions::dsl;
        let mut connection = self.database.connect().await;

        let session: Option<crate::models::Session> = dsl::sessions
            .find(session_id.to_string())
            .first(&mut connection)
            .await
            .optional()
            .unwrap();

        session
            .map(|s| serde_json::from_str(&s.contents).unwrap())
            .unwrap_or_default()
    }

    async fn upsert(&self, id: Uuid, data: SessionData, expiration: DateTime<Utc>) {
        use crate::schema::sessions::dsl;
        let mut connection = self.database.connect().await;

        insert_into(dsl::sessions)
            .values((
                dsl::id.eq(id.to_string()),
                dsl::contents.eq(serde_json::to_string(&data).unwrap()),
                dsl::expiration.eq(expiration),
            ))
            .on_conflict(dsl::id)
            .do_update()
            .set((
                dsl::contents.eq(excluded(dsl::contents)),
                dsl::expiration.eq(excluded(dsl::expiration)),
            ))
            .execute(&mut connection)
            .await
            .unwrap();
    }
}

#[derive(Debug, Clone)]
pub struct SessionService<TInner> {
    inner: TInner,
    store: SessionStore,
    cookie_domain: String,
}

impl<
    TRequestBody: Send + 'static,
    TResponseBody: Send + 'static,
    TInnner: Service<Request<TRequestBody>, Response = Response<TResponseBody>> + Clone + Send + 'static,
> Service<Request<TRequestBody>> for SessionService<TInnner>
where
    TInnner::Future: Send + 'static,
{
    type Response = TInnner::Response;
    type Error = TInnner::Error;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn poll_ready(
        &mut self,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx)
    }

    fn call(&mut self, req: Request<TRequestBody>) -> Self::Future {
        let not_ready_inner = self.inner.clone();
        let mut ready_inner = std::mem::replace(&mut self.inner, not_ready_inner);

        let store = self.store.clone();
        let cookie_domain = self.cookie_domain.clone();
        Box::pin(async move {
            let (mut parts, body) = req.into_parts();
            let cookies = CookieJar::from_request_parts(&mut parts, &())
                .await
                .unwrap();

            let session_id = if let Some(session_id) = cookies.get(COOKIE_NAME_SESSION_ID) {
                Uuid::parse_str(session_id.value()).unwrap()
            } else {
                Uuid::now_v7()
            };

            let mut req = Request::from_parts(parts, body);
            req.extensions_mut().insert(SessionHandle {
                id: session_id,
                store,
            });

            let mut response = ready_inner.call(req).await?;
            let mut cookie = Cookie::new(COOKIE_NAME_SESSION_ID, session_id.to_string());

            cookie.set_path("/");
            cookie.set_domain(cookie_domain);
            cookie.set_expires(Expiration::Session);

            response.headers_mut().append(
                SET_COOKIE,
                HeaderValue::from_str(&cookie.encoded().to_string()).unwrap(),
            );

            Ok(response)
        })
    }
}

#[derive(Debug, Clone)]
pub struct SessionLayer {
    store: SessionStore,
    cookie_domain: String,
}

impl SessionLayer {
    pub fn new(database: DatabaseConnector, cookie_domain: String) -> Self {
        Self {
            store: SessionStore::new(database),
            cookie_domain,
        }
    }
}

impl<TInner> Layer<TInner> for SessionLayer {
    type Service = SessionService<TInner>;

    fn layer(&self, inner: TInner) -> Self::Service {
        SessionService {
            inner,
            store: self.store.clone(),
            cookie_domain: self.cookie_domain.clone(),
        }
    }
}
