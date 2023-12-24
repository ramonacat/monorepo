use std::sync::mpsc::{channel, Receiver, Sender};

pub struct ReactiveProperty<T: Send> {
    tx: Sender<T>,
}

pub struct ReactivePropertyReceiver<T: Send>(Receiver<T>);

impl<T: Send> ReactivePropertyReceiver<T> {
    pub fn latest_value(&self) -> Option<T> {
        let mut result = None;
        while let Ok(latest) = self.0.try_recv() {
            result = Some(latest);
        }

        result
    }
}

impl<T: Send> ReactiveProperty<T> {
    pub fn new() -> (Self, ReactivePropertyReceiver<T>) {
        let (tx, rx) = channel();
        (Self { tx }, ReactivePropertyReceiver(rx))
    }

    pub fn send(&self, new_value: T) {
        self.tx.send(new_value).unwrap();
    }
}
