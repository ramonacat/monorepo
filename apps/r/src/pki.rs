use std::{fs, io};

use chrono::{DateTime, Months, Utc};
use clap::Subcommand;
use openssl::{
    asn1::{Asn1Integer, Asn1Time},
    bn::{BigNum, MsbOption},
    hash::MessageDigest,
    pkey::{HasPublic, PKey, Private},
    rsa::Rsa,
    stack::Stack,
    x509::{
        X509, X509Builder, X509Name, X509NameBuilder,
        extension::{
            AuthorityKeyIdentifier, BasicConstraints, ExtendedKeyUsage, KeyUsage,
            SubjectAlternativeName, SubjectKeyIdentifier,
        },
    },
};
use thiserror::Error;

#[derive(Debug, Subcommand)]
#[allow(clippy::enum_variant_names)]
pub enum Action {
    GenerateCa,
    GenerateUser {
        name: String,
    },
    GenerateNode {
        name: String,
        #[arg(short = 's', long = "alternative-name")]
        alternative_names: Vec<String>,
    },
}

const ASN1_DATE_FORMAT: &str = "%Y%m%d%H%M%SZ";

const CA_CERT_FILENAME: &str = "ca.crt";
const CA_KEY_FILENAME: &str = "ca.key";

fn make_name(common_name: &str) -> Result<X509Name, openssl::error::ErrorStack> {
    let mut ca_name_builder = X509NameBuilder::new()?;
    ca_name_builder.append_entry_by_text("C", "DE")?;
    ca_name_builder.append_entry_by_text("CN", common_name)?;

    Ok(ca_name_builder.build())
}

fn make_serial_number() -> Result<Asn1Integer, openssl::error::ErrorStack> {
    let mut serial = BigNum::new()?;
    serial.rand(159, MsbOption::MAYBE_ZERO, false)?;

    serial.to_asn1_integer()
}

fn to_asn_time(when: DateTime<Utc>) -> Result<Asn1Time, openssl::error::ErrorStack> {
    Asn1Time::from_str(&when.format(ASN1_DATE_FORMAT).to_string())
}

fn make_cert_builder<TKey: HasPublic>(
    name: &str,
    ca_cert: &X509,
    key: &PKey<TKey>,
) -> Result<X509Builder, openssl::error::ErrorStack> {
    let now = Utc::now();
    let in_1_year = now + Months::new(12);

    let not_before = to_asn_time(now)?;
    let not_after = to_asn_time(in_1_year)?;

    let serial_number = make_serial_number()?;
    let subject_name = make_name(name)?;

    let mut cert_builder = X509::builder()?;

    cert_builder.set_version(2)?;
    cert_builder.set_serial_number(&serial_number)?;
    cert_builder.set_subject_name(&subject_name)?;
    cert_builder.set_issuer_name(ca_cert.subject_name())?;
    cert_builder.set_not_before(&not_before)?;
    cert_builder.set_not_after(&not_after)?;
    cert_builder.set_pubkey(key)?;
    cert_builder.append_extension(
        SubjectKeyIdentifier::new().build(&cert_builder.x509v3_context(Some(ca_cert), None))?,
    )?;
    cert_builder.append_extension(
        AuthorityKeyIdentifier::new()
            .keyid(false)
            .issuer(false)
            .build(&cert_builder.x509v3_context(Some(ca_cert), None))?,
    )?;
    cert_builder
        .append_extension(BasicConstraints::new().build().unwrap())
        .unwrap();
    cert_builder
        .append_extension(
            KeyUsage::new()
                .critical()
                .digital_signature()
                .key_encipherment()
                .build()
                .unwrap(),
        )
        .unwrap();

    Ok(cert_builder)
}

fn make_private_key() -> Result<PKey<Private>, openssl::error::ErrorStack> {
    let key = Rsa::generate(4096)?;

    PKey::from_rsa(key)
}

#[derive(Debug, Error)]
enum LoadError {
    #[error("openssl: {0}")]
    OpenSsl(#[from] openssl::error::ErrorStack),
    #[error("io: {0}")]
    Io(#[from] io::Error),
}

fn load_ca_cert() -> Result<X509, LoadError> {
    let raw_cert = fs::read(CA_CERT_FILENAME)?;

    Ok(X509::from_pem(&raw_cert)?)
}

fn load_ca_key() -> Result<PKey<Private>, LoadError> {
    let raw_key = fs::read(CA_KEY_FILENAME)?;
    let ca_key = Rsa::private_key_from_pem(&raw_key)?;

    Ok(PKey::from_rsa(ca_key)?)
}

pub fn cli(action: Action) {
    match action {
        Action::GenerateCa => {
            let now = Utc::now();
            let in_10_years = now + Months::new(12 * 10);

            let key = make_private_key().unwrap();

            let ca_name = make_name("ramona root A").unwrap();

            let mut extensions = Stack::new().unwrap();
            extensions
                .push(BasicConstraints::new().critical().ca().build().unwrap())
                .unwrap();
            extensions
                .push(
                    KeyUsage::new()
                        .critical()
                        .crl_sign()
                        .key_cert_sign()
                        .build()
                        .unwrap(),
                )
                .unwrap();

            let mut certificate = X509Builder::new().unwrap();
            certificate
                .set_serial_number(&make_serial_number().unwrap())
                .unwrap();
            certificate.set_subject_name(&ca_name).unwrap();
            certificate.set_issuer_name(&ca_name).unwrap();
            certificate.set_pubkey(&key).unwrap();
            certificate.set_version(2).unwrap();
            certificate
                .set_not_before(&to_asn_time(now).unwrap())
                .unwrap();
            certificate
                .set_not_after(&to_asn_time(in_10_years).unwrap())
                .unwrap();
            certificate
                .append_extension(BasicConstraints::new().critical().ca().build().unwrap())
                .unwrap();
            certificate
                .append_extension(
                    KeyUsage::new()
                        .critical()
                        .crl_sign()
                        .key_cert_sign()
                        .build()
                        .unwrap(),
                )
                .unwrap();

            certificate.sign(&key, MessageDigest::sha512()).unwrap();

            let certificate = certificate.build();

            fs::write(CA_KEY_FILENAME, key.private_key_to_pem_pkcs8().unwrap()).unwrap();
            fs::write(CA_CERT_FILENAME, certificate.to_pem().unwrap()).unwrap();
        }
        Action::GenerateUser { name } => {
            let ca_cert = load_ca_cert().unwrap();
            let ca_key = load_ca_key().unwrap();

            let key = make_private_key().unwrap();

            let mut cert_builder = make_cert_builder(&name, &ca_cert, &key).unwrap();
            cert_builder
                .append_extension(ExtendedKeyUsage::new().client_auth().build().unwrap())
                .unwrap();
            cert_builder.sign(&ca_key, MessageDigest::sha256()).unwrap();

            let certificate = cert_builder.build();

            fs::write(
                format!("{name}.key"),
                key.private_key_to_pem_pkcs8().unwrap(),
            )
            .unwrap();
            fs::write(format!("{name}.crt"), certificate.to_pem().unwrap()).unwrap();
        }
        Action::GenerateNode {
            name,
            alternative_names,
        } => {
            let ca_cert = load_ca_cert().unwrap();
            let ca_key = load_ca_key().unwrap();

            let key = make_private_key().unwrap();

            let mut cert_builder = make_cert_builder(&name, &ca_cert, &key).unwrap();
            cert_builder
                .append_extension(
                    ExtendedKeyUsage::new()
                        .client_auth()
                        .server_auth()
                        .build()
                        .unwrap(),
                )
                .unwrap();

            let mut san_extension = SubjectAlternativeName::new();

            for alt_name in alternative_names {
                let (kind, value) = alt_name.split_once(':').unwrap();

                match kind {
                    "ip" => {
                        san_extension.ip(value);
                    }
                    "dns" => {
                        san_extension.dns(value);
                    }
                    _ => {
                        panic!("alternate name kind must be \"ip\" or \"dns\", \"{kind}\" given")
                    }
                }
            }

            cert_builder
                .append_extension(
                    san_extension
                        .build(&cert_builder.x509v3_context(Some(&ca_cert), None))
                        .unwrap(),
                )
                .unwrap();
            cert_builder.sign(&ca_key, MessageDigest::sha256()).unwrap();

            let certificate = cert_builder.build();

            fs::write(
                format!("{name}.key"),
                key.private_key_to_pem_pkcs8().unwrap(),
            )
            .unwrap();
            fs::write(format!("{name}.crt"), certificate.to_pem().unwrap()).unwrap();
        }
    }
}
