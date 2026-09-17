use async_trait::async_trait;
use axum::extract;
use axum::extract::FromRequestParts;
use http::Uri;

use crate::{
    auth::{
        Account, AuthenticateRedirectedError, AuthenticationError, AuthenticationMethod, Machine,
    },
    mtls::MtlsExtension,
};

#[derive(Debug)]
#[non_exhaustive]
pub struct MTls {}

#[async_trait]
impl AuthenticationMethod for MTls {
    async fn authenticate(
        &self,
        request_parts: &mut http::request::Parts,
    ) -> Result<Account, AuthenticationError> {
        let extract::Extension(mtls_state) =
            extract::Extension::<MtlsExtension>::from_request_parts(request_parts, &())
                .await
                .unwrap();

        match mtls_state {
            MtlsExtension::Authenticated => {
                // TODO this really should come from the certificate, but that might require a bit
                // more substantial change and getting rid of axum_server to access rustls directly
                let hostname = request_parts
                    .headers
                    .get("x-ramona-hostname")
                    .unwrap()
                    .to_str()
                    .unwrap();

                Ok(Account::Machine(Machine {
                    hostname: hostname.to_string(),
                    auth_method: "mtls".to_string(),
                }))
            }
            MtlsExtension::NotAuthenticated => {
                Err(AuthenticationError::NotAuthenticated { redirect: None })
            }
        }
    }

    async fn authenticate_redirected(
        &self,
        _request_parts: &mut http::request::Parts,
    ) -> Result<Uri, AuthenticateRedirectedError> {
        Err(AuthenticateRedirectedError::NoMatch)
    }
}

impl MTls {
    pub fn new() -> Self {
        Self {}
    }
}
