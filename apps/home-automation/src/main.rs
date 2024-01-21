mod debouncer;

use std::{sync::Arc, time::Duration};

use amqprs::{
    channel::{
        BasicAckArguments, BasicConsumeArguments, BasicPublishArguments, Channel,
        QueueBindArguments, QueueDeclareArguments,
    },
    connection::{Connection, OpenConnectionArguments},
    consumer::AsyncConsumer,
    BasicProperties, Deliver,
};
use async_trait::async_trait;
use chrono::{DateTime, Local};
use debouncer::Debouncer;
use serde_json::{json, Value};
use tokio::{
    sync::{
        mpsc::{channel, unbounded_channel, UnboundedSender},
        Mutex,
    },
    time::sleep,
};
use tracing::{debug, info, warn};

const LIGHTBULB_IDS: [&str; 3] = [
    "0x001788010c030841",
    "0x001788010c0ac9f3",
    "0x001788010c0bb998",
];

async fn send_message(channel: &Channel, device_id: &str, message: &str) {
    channel
        .basic_publish(
            BasicProperties::default(),
            message.as_bytes().to_vec(),
            BasicPublishArguments::new("amq.topic", &format!("zigbee2mqtt.{}.set", device_id)),
        )
        .await
        .unwrap();
}

async fn lights_on(channel: &Channel) {
    let message_val = json!({
        "state": "ON",
        "brightness": 254,
        "color_temp": 210
    });
    let message = serde_json::to_string(&message_val).unwrap();

    for id in LIGHTBULB_IDS {
        send_message(channel, id, &message).await;
    }
}

async fn lights_off(channel: &Channel) {
    let message_val = json!({
        "state": "OFF"
    });
    let message = serde_json::to_string(&message_val).unwrap();

    for id in LIGHTBULB_IDS {
        send_message(channel, id, &message).await;
    }
}

#[derive(Debug)]
enum Event {
    LightsOnRequested,
    LightsOffRequested,
    OccupancyEnded,
    OccupancyStarted,
}

struct MyConsumer {
    sender: UnboundedSender<Event>,
    occupancy_debouncer: Debouncer,
}

impl MyConsumer {
    fn new(sender: UnboundedSender<Event>) -> Self {
        let (tx, mut rx) = channel(50);

        let sender_ = sender.clone();
        tokio::spawn(async move {
            loop {
                if let Some(_) = rx.recv().await {
                    let _ = sender_.send(Event::OccupancyEnded);
                }
            }
        });

        let occupancy_debouncer = Debouncer::new(Duration::from_secs(600), tx);
        Self {
            sender,
            occupancy_debouncer,
        }
    }
}

#[async_trait]
impl AsyncConsumer for MyConsumer {
    async fn consume(
        &mut self, // use `&mut self` to make trait object to be `Sync`
        channel: &Channel,
        deliver: Deliver,
        _basic_properties: BasicProperties,
        content: Vec<u8>,
    ) {
        if deliver.routing_key().starts_with("zigbee2mqtt.bridge") {
            channel
                .basic_ack(BasicAckArguments::new(deliver.delivery_tag(), false))
                .await
                .unwrap();
            return;
        }

        if deliver.routing_key().ends_with(".action") {
            channel
                .basic_ack(BasicAckArguments::new(deliver.delivery_tag(), false))
                .await
                .unwrap();
            return;
        }

        let val: Value = serde_json::from_slice(&content).unwrap();

        if deliver.routing_key() == "zigbee2mqtt.0x001788010b5aa77d" {
            if let Some(action) = val.get("action") {
                if let Some(action) = action.as_str() {
                    match action {
                        "on_press" => {
                            self.sender.send(Event::LightsOnRequested).unwrap();
                        }
                        "off_press" => {
                            self.sender.send(Event::LightsOffRequested).unwrap();
                        }
                        _ => {
                            debug!("unknown action from remote: {}", action);
                        }
                    }
                }
            }
        } else if deliver.routing_key() == "zigbee2mqtt.0x000d6f000f83fc15" {
            if let Some(occupancy) = val.get("occupancy") {
                if let Some(occupancy) = occupancy.as_bool() {
                    if occupancy {
                        self.sender.send(Event::OccupancyStarted).unwrap();
                        self.occupancy_debouncer.reset().await;
                    } else {
                        self.occupancy_debouncer.set().await;
                    }
                }
            }
        } else {
            info!("Unknown message from {}: {:?}", deliver.routing_key(), val);
        }

        channel
            .basic_ack(BasicAckArguments::new(deliver.delivery_tag(), false))
            .await
            .unwrap();
    }
}

async fn connect_to_rabbitmq(password: &str) -> Connection {
    loop {
        match Connection::open(&OpenConnectionArguments::new(
            "shadowmend",
            5672,
            "ha",
            password,
        ))
        .await
        {
            Ok(connection) => return connection,
            Err(e) => {
                warn!(
                    "Failed to connect to RabbitMQ({}), waiting and retrying...",
                    e
                );
                sleep(Duration::from_secs(1)).await;
            }
        }
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();

    let rabbit_password = std::fs::read_to_string("/run/agenix/rabbitmq-ha")
        .expect("Failed to read the RabbitMQ password");

    let connection = connect_to_rabbitmq(rabbit_password.trim()).await;

    let channel = connection.open_channel(None).await.unwrap();

    let (queue_name, _, _) = channel
        .queue_declare(QueueDeclareArguments::default().exclusive(true).finish())
        .await
        .unwrap()
        .unwrap();
    channel
        .queue_bind(QueueBindArguments::new(
            &queue_name,
            "amq.topic",
            "zigbee2mqtt.#",
        ))
        .await
        .unwrap();

    let args = BasicConsumeArguments::new(&queue_name, "home-automation");
    let (tx, mut rx) = unbounded_channel();
    channel
        .basic_consume(MyConsumer::new(tx.clone()), args)
        .await
        .unwrap();

    while let Some(event) = rx.recv().await {
        println!("{:?}", event);
        match event {
            Event::LightsOnRequested => {
                lights_on(&channel).await;
            }
            Event::LightsOffRequested => {
                lights_off(&channel).await;
            }
            Event::OccupancyEnded => {
                tx.send(Event::LightsOffRequested).unwrap();
            }
            Event::OccupancyStarted => {}
        };
    }
}
