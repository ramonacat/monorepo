use crate::hosts::Hostname;
use crate::sensitive::Sensitive;

#[derive(Debug, Clone)]
pub struct HostIdentity {
    hostname: Hostname,
    certificate: Vec<u8>,
    certificate_key: Sensitive<Vec<u8>>,
}

impl HostIdentity {
    pub fn new(
        hostname: Hostname,
        certificate: Vec<u8>,
        certificate_key: Sensitive<Vec<u8>>,
    ) -> Self {
        Self {
            hostname,
            certificate,
            certificate_key,
        }
    }

    pub fn hostname(&self) -> &Hostname {
        &self.hostname
    }

    pub fn to_pem_bundle(&self) -> Vec<u8> {
        Vec::from_iter(
            self.certificate_key
                .iter()
                .chain(b"\n".iter())
                .chain(self.certificate.iter())
                .copied(),
        )
    }
}
