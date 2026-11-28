use std::{fs, net::Ipv4Addr, path::PathBuf};

use base64_light::base64_encode;
use clap::Subcommand;
use kube::config::{
    AuthInfo, Cluster, Context, Kubeconfig, NamedAuthInfo, NamedCluster, NamedContext,
};

#[derive(Debug, Subcommand)]
pub enum Action {
    CreateConfig {
        name: String,
        ca: PathBuf,
        cert: PathBuf,
        key: PathBuf,
        server_ip: Ipv4Addr,
        server_port: u16,
        output: PathBuf,
    },
}

pub fn cli(action: Action) {
    match action {
        Action::CreateConfig {
            name,
            ca,
            cert,
            key,
            server_ip,
            server_port,
            output,
        } => {
            let ca = fs::read_to_string(ca).unwrap();

            // TODO generate the cert automagically?
            let user_cert = fs::read_to_string(cert).unwrap();
            let user_key = fs::read_to_string(key).unwrap();

            let cluster_name = "kubernetes".to_string();
            let context_name = format!("{name}@{cluster_name}");

            let kubeconfig = Kubeconfig {
                clusters: vec![NamedCluster {
                    name: cluster_name.clone(),
                    cluster: Some(Cluster {
                        server: Some(format!("https://{server_ip}:{server_port}/")),
                        certificate_authority_data: Some(base64_encode(&ca)),
                        ..Default::default()
                    }),
                    ..Default::default()
                }],
                contexts: vec![NamedContext {
                    name: context_name.clone(),
                    context: Some(Context {
                        cluster: cluster_name,
                        user: Some(name.clone()),
                        ..Default::default()
                    }),
                    ..Default::default()
                }],
                current_context: Some(context_name),
                auth_infos: vec![NamedAuthInfo {
                    name,
                    auth_info: Some(AuthInfo {
                        client_certificate_data: Some(base64_encode(&user_cert)),
                        client_key_data: Some(base64_encode(&user_key).into()),
                        ..Default::default()
                    }),
                    ..Default::default()
                }],
                ..Default::default()
            };

            let mut writer = fs::File::create(output).unwrap();
            serde_saphyr::to_io_writer(&mut writer, &kubeconfig).unwrap();
        }
    }
}
