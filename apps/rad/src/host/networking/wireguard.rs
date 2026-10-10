use std::{
    fmt::Debug,
    fs::{self, OpenOptions},
    io::Write as _,
    os::unix::fs::OpenOptionsExt,
    path::Path,
};

use anyhow::Context;
use base64::Engine as _;
use rand::rng;
use x25519_dalek::{PublicKey, StaticSecret};

// TODO move to rlib
pub struct Key {
    public: PublicKey,
    private: StaticSecret,
}

impl Debug for Key {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Key")
            .field("public", &self.public)
            .finish_non_exhaustive()
    }
}

impl Key {
    pub fn load(path: &Path) -> anyhow::Result<Key> {
        let private = match fs::read_to_string(path) {
            Ok(contents) => {
                let bytes: [u8; 32] = base64::engine::general_purpose::STANDARD
                    .decode(contents)
                    .with_context(|| {
                        format!("failed to decode private wireguard key at {:?}", path)
                    })?
                    .try_into()
                    .unwrap();

                StaticSecret::from(bytes)
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                let secret = StaticSecret::random_from_rng(&mut rng());

                let mut key_file = OpenOptions::new()
                    .write(true)
                    .create(true)
                    .truncate(true)
                    .mode(0o600)
                    .open(path)?;

                key_file
                    .write_all(
                        base64::engine::general_purpose::STANDARD
                            .encode(secret.as_bytes())
                            .as_bytes(),
                    )
                    .with_context(|| {
                        format!("failed to write a new wireguard key at {:?}", path)
                    })?;

                secret
            }
            Err(e) => {
                return Err(e)
                    .with_context(|| format!("failed to read wireguard key at {:?}", path));
            }
        };

        let public = PublicKey::from(&private);

        Ok(Self { private, public })
    }

    pub fn to_public_base64(&self) -> String {
        base64::engine::general_purpose::STANDARD.encode(self.public.as_bytes())
    }

    pub fn to_private_base64(&self) -> String {
        base64::engine::general_purpose::STANDARD.encode(self.private.as_bytes())
    }
}
