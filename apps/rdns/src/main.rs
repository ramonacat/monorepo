use askama::Template;
use nix::{
    sys::signal::{Signal, kill},
    unistd::Pid,
};
use serde::Deserialize;
use std::{collections::HashMap, fs, path::PathBuf, str::FromStr, time::Duration};
use tracing::error;
use uuid::Uuid;

use rlib::{
    config,
    dns::Zone,
    ras_client::{RasClient, RasConnectionConfig},
};
use tokio::{
    process::{Child, Command},
    signal::ctrl_c,
    time::sleep,
};

#[derive(Debug, Template)]
#[template(path = "dns.zone")]
struct ZoneFile<'a> {
    zone: &'a Zone,
    nameserver: &'a str,
    nameserver_contact: &'a str,
}

#[derive(Debug)]
struct ConfigZone<'a> {
    name: &'a str,
    filename: String,
}

#[derive(Debug, Template)]
#[template(path = "nsd.conf")]
struct NsdConfig<'a> {
    zones: &'a [ConfigZone<'a>],
    nameserver: &'a str,
}

#[derive(Debug, Deserialize)]
struct Config {
    nameserver: String,
    nameserver_contact: String,
}

const NSD_CONFIG_PATH: &str = "/var/ramona/nsd.conf";
const NSD_ZONE_DIRECTORY: &str = "/var/ramona/zones/";

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();
    rustls::crypto::aws_lc_rs::default_provider()
        .install_default()
        .unwrap();

    let ras_client = RasClient::new(RasConnectionConfig::LocalUnencrypted).unwrap();

    let mut last_serial: HashMap<Uuid, u32> = HashMap::new();
    let mut nsd_process = None;

    let mut ctrl_c = Box::pin(ctrl_c());
    loop {
        let config: Config = config::load().unwrap();
        let zones = ras_client.get_all_dns_zones().await.unwrap();
        let mut config_zones = vec![];
        let mut zone_updated = false;

        for zone in &zones.zones {
            if *last_serial.get(&zone.id).unwrap_or(&0u32) < zone.serial {
                let zone_file = ZoneFile {
                    zone,
                    nameserver: &config.nameserver,
                    nameserver_contact: &config.nameserver_contact,
                };

                let filename = &zone
                    .name
                    .split('.')
                    .rev()
                    .fold(String::new(), |acc, x| format!("{acc}.{x}"))[1..];

                let mut full_path = PathBuf::from_str(NSD_ZONE_DIRECTORY).unwrap();
                full_path.push(filename);

                let contents = zone_file.render().unwrap();

                config_zones.push(ConfigZone {
                    name: &zone.name,
                    filename: full_path.to_string_lossy().to_string(),
                });

                fs::create_dir_all(full_path.parent().unwrap()).unwrap();
                fs::write(full_path, contents).unwrap();

                zone_updated = true;

                last_serial.insert(zone.id, zone.serial);
            }
        }

        if zone_updated {
            let nsd_config = NsdConfig {
                zones: &config_zones,
                nameserver: &config.nameserver,
            };
            let nsd_config_contents = nsd_config.render().unwrap();

            std::fs::write(NSD_CONFIG_PATH, nsd_config_contents).unwrap();

            if let Some(nsd_pid) = nsd_process
                .as_ref()
                .and_then(|x: &Child| x.id().map(|y| y as i32))
            {
                kill(Pid::from_raw(nsd_pid), Signal::SIGHUP).unwrap();
            }
        }

        if nsd_process
            .as_mut()
            .is_none_or(|p: &mut Child| match p.try_wait().unwrap() {
                Some(exit_status) => {
                    error!(?exit_status, "nsd exited");

                    true
                }
                None => false,
            })
        {
            nsd_process = Some(
                Command::new("nsd")
                    .args(["-c", NSD_CONFIG_PATH])
                    .kill_on_drop(true)
                    .spawn()
                    .unwrap(),
            );
        }

        tokio::select! {
            _ = (&mut ctrl_c) => {
                break;
            }
            _ = sleep(Duration::from_secs(60)) => {}
        };
    }
}
