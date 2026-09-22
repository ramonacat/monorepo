use std::fs;

use anyhow::Context;
use base64::Engine as _;
use rand::rng;
use x25519_dalek::{PublicKey, StaticSecret};

use crate::config::{self};

pub struct Key {
    public: PublicKey,
}

impl Key {
    pub fn load(config: &config::Wireguard) -> anyhow::Result<Key> {
        let private = match fs::read_to_string(&config.key_path) {
            Ok(contents) => {
                let bytes: [u8; 32] = base64::engine::general_purpose::STANDARD
                    .decode(contents)
                    .with_context(|| {
                        format!(
                            "failed to decode private wireguard key at {:?}",
                            config.key_path
                        )
                    })?
                    .try_into()
                    .unwrap();

                StaticSecret::from(bytes)
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                let secret = StaticSecret::random_from_rng(&mut rng());

                fs::write(
                    &config.key_path,
                    base64::engine::general_purpose::STANDARD.encode(secret.as_bytes()),
                )
                .with_context(|| {
                    format!(
                        "failed to write a new wireguard key at {:?}",
                        config.key_path
                    )
                })?;

                secret
            }
            Err(e) => {
                return Err(e).with_context(|| {
                    format!("failed to read wireguard key at {:?}", config.key_path)
                });
            }
        };

        let public = PublicKey::from(&private);

        Ok(Self { public })
    }

    pub fn to_public_base64(&self) -> String {
        base64::engine::general_purpose::STANDARD.encode(self.public.as_bytes())
    }
}
