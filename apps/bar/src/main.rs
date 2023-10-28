use std::{
    fmt::format,
    process::{Command, Stdio},
    time::Duration,
};

use regex::Regex;
use serde::Serialize;
use upower_dbus::UPowerProxy;

// https://i3wm.org/docs/i3bar-protocol.html
#[derive(Debug, Serialize)]
struct Block {
    full_text: String,
}

fn get_pa_volume() -> f64 {
    let cmd = Command::new("pactl")
        .args(&["get-sink-volume", "@DEFAULT_SINK@"])
        .stdout(Stdio::piped())
        .spawn()
        .unwrap()
        .wait_with_output()
        .unwrap();

    let regex = Regex::new(r"(\d+)%").unwrap();
    let output = String::from_utf8_lossy(&cmd.stdout);

    for x in regex.captures_iter(&output) {
        let (_, [val]) = x.extract();

        return val.parse::<f64>().unwrap() / 100.0f64;
    }

    0.0f64
}

fn get_pa_mute() -> bool {
    let cmd = Command::new("pactl")
        .args(&["get-sink-mute", "@DEFAULT_SINK@"])
        .stdout(Stdio::piped())
        .spawn()
        .unwrap()
        .wait_with_output()
        .unwrap();

    let regex = Regex::new(r"Mute: (yes|no)").unwrap();
    let output = String::from_utf8_lossy(&cmd.stdout);

    for x in regex.captures_iter(&output) {
        let (_, [val]) = x.extract();

        return val == "yes";
    }

    false
}

#[tokio::main]
async fn main() {
    let connection = zbus::Connection::system().await.unwrap();
    let upower = UPowerProxy::new(&connection).await.unwrap();

    println!("{}", "{\"version\": 1, \"click_events\": false}");
    println!("[");

    loop {
        let is_on_battery = upower.on_battery().await.unwrap();
        let battery = upower.get_display_device().await.unwrap();
        let battery_percent = battery.percentage().await.unwrap();
        let battery_emoji = if is_on_battery { "🔋" } else { "🔌" };

        let volume = get_pa_volume();
        let mute_emoji = if get_pa_mute() { "🔇" } else { "🔊" };
        let now = chrono::Local::now();

        let mut loadavg = [0.0f64; 2];
        unsafe {
            libc::getloadavg(loadavg.as_mut_ptr(), 2);
        }

        println!(
            "{},",
            serde_json::to_string(&[
                Block {
                    full_text: format!("{} {:.0}%", battery_emoji, battery_percent)
                },
                Block {
                    full_text: format!("{} {:.0}%", mute_emoji, volume * 100.0f64)
                },
                Block {
                    full_text: format!("🏋 {:.2} {:.2}", loadavg[0], loadavg[1])
                },
                Block {
                    full_text: now.format("🕛 %Y-%m-%d %H:%M").to_string()
                },
            ])
            .unwrap()
        );

        tokio::time::sleep(Duration::from_millis(500)).await;
    }
}
