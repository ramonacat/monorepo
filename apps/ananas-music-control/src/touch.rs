use std::{
    collections::{HashMap, HashSet},
    thread::current,
};

use tokio::sync::mpsc::{Sender, UnboundedSender};

use crate::touchpanel::{Touch, TouchPanel};

#[derive(Debug)]
pub struct Position {
    x: usize,
    y: usize,
    strength: usize,
    id: u8,
}

impl Position {
    pub fn x(&self) -> usize {
        self.x
    }

    pub fn y(&self) -> usize {
        self.y
    }
}

impl From<Touch> for Position {
    fn from(value: Touch) -> Self {
        Self {
            x: value.x,
            y: value.y,
            strength: value.strength,
            id: value.track_id,
        }
    }
}

#[derive(Debug)]
pub enum Event {
    TouchStarted(Position),
    TouchEnded(Position),
    TouchMoved(Position),
}

pub struct EventCoalescer {
    panel: TouchPanel,
    tx: UnboundedSender<Event>,
}

impl EventCoalescer {
    pub fn new(panel: TouchPanel, tx: UnboundedSender<Event>) -> Self {
        Self { panel, tx }
    }

    pub fn run(mut self) {
        let mut current_touches: HashMap<u8, Touch> = HashMap::with_capacity(5);

        loop {
            let Some(touches) = self.panel.wait_for_touch() else {
                continue;
            };

            let touches_in_current: HashSet<_> = touches.iter().map(|x| x.track_id).collect();

            for touch in touches {
                if let Some(current_touch) = current_touches.get(&touch.track_id) {
                    if *current_touch != touch {
                        self.tx.send(Event::TouchMoved(touch.into())).unwrap();
                    }
                } else {
                    self.tx
                        .send(Event::TouchStarted(touch.clone().into()))
                        .unwrap();

                    current_touches.insert(touch.track_id, touch);
                }
            }

            for (key, value) in current_touches.clone() {
                if !touches_in_current.contains(&key) {
                    self.tx.send(Event::TouchEnded(value.into())).unwrap();

                    current_touches.remove(&key);
                }
            }
        }
    }
}
