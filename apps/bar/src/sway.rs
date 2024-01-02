use swayipc_async::Connection;

pub struct Sway {
    connection: Connection
}

impl Sway {
    pub async fn connect() -> Self {
        let connection = Connection::new().await.unwrap();
        Self { connection }
    }


    pub async fn keyboard_layout(&mut self) -> String {
        let inputs = self.connection.get_inputs().await.unwrap();

        for input in inputs {
            if let Some(layout_name) = input.xkb_active_layout_name {
                return  layout_name.clone();
            }
        }

        String::new()
    }
}
