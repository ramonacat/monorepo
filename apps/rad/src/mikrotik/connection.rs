use std::{collections::HashMap, net::SocketAddr, sync::Arc, time::Duration};

use rlib::sensitive::Sensitive;
use rustls_platform_verifier::ConfigVerifierExt as _;
use thiserror::Error;
use tokio::{
    io::{AsyncRead, AsyncWrite},
    net::TcpStream,
    time::timeout,
};
use tokio_rustls::{
    TlsConnector,
    client::TlsStream,
    rustls::{ClientConfig, pki_types::ServerName},
};

use crate::mikrotik::protocol::{MikrotikStream, Sentence};

#[derive(Debug, PartialEq, Eq)]
pub enum ResponseLine {
    Done,
    Trap(String),
    Data(HashMap<String, String>),
    Empty,
    Fatal(String),
}

#[derive(Debug, Error)]
pub enum ParseAttirbuteWordsError {
    #[error("invalid word: {0}")]
    InvalidWord(String),
}

fn parse_attribute_words(
    words: &[String],
) -> Result<HashMap<String, String>, ParseAttirbuteWordsError> {
    let mut result = HashMap::new();

    for word in words {
        if let Some((key, value)) = word[1..].split_once("=") {
            result.insert(key.to_owned(), value.to_owned());
        } else {
            return Err(ParseAttirbuteWordsError::InvalidWord(word.to_owned()));
        }
    }

    Ok(result)
}

#[derive(Debug, Error)]
pub enum ResponseLineError {
    #[error("sentence empty")]
    SentenceEmpty,
    #[error("unknown reply word")]
    UnknownReplyWord,
    #[error("invalid data line: {0}")]
    InvalidDataLine(#[from] ParseAttirbuteWordsError),
}

impl TryFrom<Sentence> for ResponseLine {
    type Error = ResponseLineError;

    fn try_from(value: Sentence) -> Result<Self, Self::Error> {
        let Some((kind, rest)) = value.words().split_first() else {
            return Err(ResponseLineError::SentenceEmpty);
        };

        match kind.as_str() {
            "!done" => Ok(Self::Done),
            "!trap" => Ok(Self::Trap(
                value.words().iter().fold(String::new(), |a, x| a + " " + x),
            )),
            "!re" => Ok(Self::Data(parse_attribute_words(rest)?)),
            "!empty" => Ok(Self::Empty),
            "!fatal" => Ok(Self::Fatal(
                value.words().iter().fold(String::new(), |a, x| a + " " + x),
            )),

            _ => Err(ResponseLineError::UnknownReplyWord),
        }
    }
}

#[derive(Debug, Error)]
pub enum ConnectionError {
    #[error("unexpected response: {0:?}")]
    UnexpectedResponse(Vec<ResponseLine>),
}

pub struct Connection<T>(MikrotikStream<T>);

impl Connection<TlsStream<TcpStream>> {
    pub async fn connect(
        endpoint: SocketAddr,
        username: &str,
        password: Sensitive<&str>,
    ) -> anyhow::Result<Self> {
        let tcp_stream = TcpStream::connect(endpoint).await?;
        let client_config = ClientConfig::with_platform_verifier()?;
        let connector = TlsConnector::from(Arc::new(client_config));
        let tls_stream = timeout(
            Duration::from_secs(5),
            connector.connect(ServerName::IpAddress(endpoint.ip().into()), tcp_stream),
        )
        .await??;
        let stream = MikrotikStream::new(tls_stream);
        let mut connection = Connection(stream);

        let login_response = connection
            .send(
                "login",
                [("name", username), ("password", password.unseal())],
                [],
            )
            .await?;

        match login_response.first() {
            None | Some(ResponseLine::Done) => Ok(connection),
            Some(_) => Err(ConnectionError::UnexpectedResponse(login_response).into()),
        }
    }
}

impl<T: Unpin + AsyncWrite + AsyncRead> Connection<T> {
    pub async fn send(
        &mut self,
        command: &str,
        attributes: impl IntoIterator<Item = (&str, &str)>,
        queries: impl IntoIterator<Item = &str>,
    ) -> anyhow::Result<Vec<ResponseLine>> {
        let mut words = vec![format!("/{command}")];

        for (name, value) in attributes {
            words.push(format!("={name}={value}"));
        }

        for query in queries {
            words.push(format!("?{query}"));
        }

        let sentence = Sentence::new(words);

        self.0.write(sentence).await?;

        let mut result = vec![];

        loop {
            let sentence = self.0.read().await?;

            let response_line: ResponseLine = sentence.try_into()?;

            if ResponseLine::Done == response_line {
                break;
            }

            result.push(response_line);
        }

        Ok(result)
    }
}
