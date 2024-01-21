use std::{
    sync::Arc,
    time::{Duration, SystemTime},
};

use tokio::{
    sync::{mpsc::Sender, Mutex},
    time::sleep,
};

pub struct Debouncer {
    timer: Arc<Mutex<Option<SystemTime>>>,
}

impl Debouncer {
    pub fn new(timeout: Duration, tx: Sender<()>) -> Self {
        let timer = Arc::new(Mutex::new(None));
        let timer_ = timer.clone();

        tokio::spawn(async move {
            loop {
                let timer_now = {
                    let lock = *timer_.lock().await;
                    lock.clone()
                };
                if let Some(timer_now) = timer_now {
                    let duration_since_set = SystemTime::now().duration_since(timer_now).unwrap();
                    if duration_since_set > timeout {
                        {
                            *timer_.lock().await = None;
                        }
                        let _ = tx.send(()).await;
                    } else {
                        sleep(timeout - duration_since_set).await;
                    }
                } else {
                    // todo: this should probably be like a condvar on the timer or something so
                    // we're no looping for no reason
                    sleep(Duration::from_secs(1)).await;
                }
            }
        });

        Self { timer }
    }

    pub async fn set(&mut self) {
        *self.timer.lock().await = Some(SystemTime::now());
    }

    pub async fn reset(&mut self) {
        *self.timer.lock().await = None;
    }
}
