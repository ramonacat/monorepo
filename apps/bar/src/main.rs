mod upower;
mod sway;

use std::{
    process::{Command, Stdio},
    time::Duration,
};

use regex::Regex;
use serde::Serialize;
use upower::UPowerProxy;

// https://i3wm.org/docs/i3bar-protocol.html
#[derive(Debug, Serialize)]
struct Block {
    full_text: String,
}

fn get_pa_volume() -> f64 {
    let cmd = Command::new("pactl")
        .args(["get-sink-volume", "@DEFAULT_SINK@"])
        .stdout(Stdio::piped())
        .spawn()
        .unwrap()
        .wait_with_output()
        .unwrap();

    let regex = Regex::new(r"(\d+)%").unwrap();
    let output = String::from_utf8_lossy(&cmd.stdout);

    if let Some(x) = regex.captures_iter(&output).next() {
        let (_, [val]) = x.extract();

        return val.parse::<f64>().unwrap() / 100.0f64;
    }

    0.0f64
}

fn get_pa_mute() -> bool {
    let cmd = Command::new("pactl")
        .args(["get-sink-mute", "@DEFAULT_SINK@"])
        .stdout(Stdio::piped())
        .spawn()
        .unwrap()
        .wait_with_output()
        .unwrap();

    let regex = Regex::new(r"Mute: (yes|no)").unwrap();
    let output = String::from_utf8_lossy(&cmd.stdout);

    if let Some(x) = regex.captures_iter(&output).next() {
        let (_, [val]) = x.extract();

        return val == "yes";
    }

    false
}

struct BatteryState {
    is_on_battery: bool,
    percent: f64,
    energy_rate: f64,
    time_left: Duration
}

async fn get_battery_state(upower: Option<&UPowerProxy<'_>>) -> Option<BatteryState> {
    match upower {
        Some(ref x) => {
            let Ok(is_on_battery) = x.on_battery().await else { 
                return None; 
            };

            let Ok(display_device) = x.get_display_device().await else {
                return None;
            };

            let Ok(energy) = display_device.energy().await else {
                return None;
            };

            let Ok(energy_empty) = display_device.energy_empty().await else {
                return None;
            };

            let Ok(energy_full) = display_device.energy_full().await else {
                return None;
            };

            let Ok(energy_rate) = display_device.energy_rate().await else {
                return None;
            };

            let Ok(time_left) = (if is_on_battery { display_device.time_to_empty().await } else { display_device.time_to_full().await }) else {
                return None;
            };

            let percent = ((energy - energy_empty) / (energy_full - energy_empty)) * 100.0;

            Some(BatteryState {
                is_on_battery,
                percent,
                energy_rate,
                time_left: Duration::from_secs(time_left as u64)
            } )
        }
        None => None
    }
}

fn format_duration(duration: Duration) -> String {
    let mut result = String::new();

    let total_seconds = duration.as_secs();

    let hours = total_seconds/(60*60);
    let minutes = total_seconds/60 - hours * 60;
    let seconds = total_seconds - hours*60*60 - minutes*60;

    if hours > 0 {
        result += &format!("{:0>2}:", hours);
    }

    result + &format!("{:0>2}:{:0>2}", minutes, seconds)
}

#[tokio::main]
async fn main() {
    let mut sway = sway::Sway::connect().await;
    let connection = zbus::Connection::system().await.unwrap();
    let upower = UPowerProxy::new(&connection).await.ok();

    println!("{}", "{\"version\": 1, \"click_events\": false}");
    println!("[");

    loop {
        let battery_state = get_battery_state(upower.as_ref()).await;
        let volume = get_pa_volume();
        let mute_emoji = if get_pa_mute() { "🔇" } else { "🔊" };
        let now = chrono::Local::now();
        let keyboard_layout = match sway.keyboard_layout().await.as_str() {
            "Polish" => "🇲🇨", // yes, I think this is funny
            "German" => "🇩🇪",
            other => other
        }.to_string();

        let mut loadavg = [0.0f64; 2];
        unsafe {
            libc::getloadavg(loadavg.as_mut_ptr(), 2);
        }

        let mut blocks = vec![];
        if let Some(battery_state) = battery_state {
            let battery_emoji = if battery_state.is_on_battery { "🔋" } else { "🔌" };
            let mut battery_string = format!("{} {:.0}%", battery_emoji, battery_state.percent);

            let energy_rate = battery_state.energy_rate;

            if energy_rate > 0.0 || battery_state.time_left.as_secs() > 0 {
                battery_string += " (";

                if energy_rate > 0.0 {
                    battery_string += &format!("{:.2}W ", energy_rate);
                }

                if battery_state.time_left.as_secs() > 0 {
                    battery_string += &format_duration(battery_state.time_left);
                }

                battery_string += ")";
            }

            blocks.push(Block {
                full_text: battery_string
            })
        }

        blocks.push(Block {
            full_text: keyboard_layout
        });

        blocks.push(Block {
            full_text: format!("{} {:.0}%", mute_emoji, volume * 100.0f64)
        });
        blocks.push( Block {
            full_text: format!("🏋 {:.2} {:.2}", loadavg[0], loadavg[1])
        });
        blocks.push(Block {
            full_text: now.format("🕛 %Y-%m-%d %H:%M").to_string()
        });

        println!(
            "{},",
            serde_json::to_string(&blocks)
            .unwrap()
        );

        tokio::time::sleep(Duration::from_millis(500)).await;
    }
}
