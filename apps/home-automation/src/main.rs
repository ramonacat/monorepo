use amqprs::{
    channel::{
        BasicAckArguments, BasicConsumeArguments, BasicPublishArguments, Channel,
        QueueBindArguments, QueueDeclareArguments,
    },
    connection::{Connection, OpenConnectionArguments},
    consumer::{AsyncConsumer, DefaultConsumer},
    BasicProperties, Deliver,
};
use async_trait::async_trait;
use serde_json::{json, Value};
use tokio::sync::Notify;
use tracing::{debug, info};

struct MyConsumer {}

#[async_trait]
impl AsyncConsumer for MyConsumer {
    async fn consume(
        &mut self, // use `&mut self` to make trait object to be `Sync`
        channel: &Channel,
        deliver: Deliver,
        basic_properties: BasicProperties,
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

        // info!("{:?}: {:?}", deliver.routing_key(), val);

        if deliver.routing_key() == "zigbee2mqtt.0x001788010b5aa77d" {
            if let Some(action) = val.get("action") {
                if let Some(action) = action.as_str() {
                    match action {
                        "on_press" => {
                            let message_val = json!({
                                "state": "ON",
                                "brightness": 254,
                                "color_temp": 210
                            });
                            let message = serde_json::to_string(&message_val).unwrap();
                            channel
                                .basic_publish(
                                    BasicProperties::default(),
                                    message.as_bytes().to_vec(),
                                    BasicPublishArguments::new(
                                        "amq.topic",
                                        "zigbee2mqtt.0x001788010c030841.set",
                                    ),
                                )
                                .await
                                .unwrap();
                            channel
                                .basic_publish(
                                    BasicProperties::default(),
                                    message.as_bytes().to_vec(),
                                    BasicPublishArguments::new(
                                        "amq.topic",
                                        "zigbee2mqtt.0x001788010c0ac9f3.set",
                                    ),
                                )
                                .await
                                .unwrap();
                            channel
                                .basic_publish(
                                    BasicProperties::default(),
                                    message.as_bytes().to_vec(),
                                    BasicPublishArguments::new(
                                        "amq.topic",
                                        "zigbee2mqtt.0x001788010c0bb998.set",
                                    ),
                                )
                                .await
                                .unwrap();
                        }
                        "off_press" => {
                            let message_val = json!({
                                "state": "OFF"
                            });
                            let message = serde_json::to_string(&message_val).unwrap();
                            channel
                                .basic_publish(
                                    BasicProperties::default(),
                                    message.as_bytes().to_vec(),
                                    BasicPublishArguments::new(
                                        "amq.topic",
                                        "zigbee2mqtt.0x001788010c030841.set",
                                    ),
                                )
                                .await
                                .unwrap();
                            channel
                                .basic_publish(
                                    BasicProperties::default(),
                                    message.as_bytes().to_vec(),
                                    BasicPublishArguments::new(
                                        "amq.topic",
                                        "zigbee2mqtt.0x001788010c0ac9f3.set",
                                    ),
                                )
                                .await
                                .unwrap();
                            channel
                                .basic_publish(
                                    BasicProperties::default(),
                                    message.as_bytes().to_vec(),
                                    BasicPublishArguments::new(
                                        "amq.topic",
                                        "zigbee2mqtt.0x001788010c0bb998.set",
                                    ),
                                )
                                .await
                                .unwrap();
                        }
                        _ => {
                            debug!("unknown action from remote: {}", action);
                        }
                    }
                }
            }
        }

        channel
            .basic_ack(BasicAckArguments::new(deliver.delivery_tag(), false))
            .await
            .unwrap();
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();

    let connection = Connection::open(&OpenConnectionArguments::new(
        "shadowmend",
        5672,
        "ha",
        "hahaha",
    ))
    .await
    .unwrap();

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
    channel.basic_consume(MyConsumer {}, args).await.unwrap();

    let guard = Notify::new();
    guard.notified().await;
}
