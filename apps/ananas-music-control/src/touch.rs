use std::{
    collections::{HashMap, HashSet},
    sync::mpsc::Sender,
};

use crate::touchpanel::{Touch, TouchPanel};

#[derive(Debug)]
#[allow(unused)]
pub struct Position {
    x: u32,
    y: u32,
    size: u32,
    id: u8,
}

impl Position {
    pub fn x(&self) -> u32 {
        self.x
    }

    pub fn y(&self) -> u32 {
        self.y
    }
}

impl From<Touch> for Position {
    fn from(value: Touch) -> Self {
        Self {
            x: value.x,
            y: value.y,
            size: value.size,
            id: value.track_id,
        }
    }
}

#[derive(Debug)]
pub enum Event {
    Started(Position),
    Ended(Position),
    Moved(Position),
}

pub struct EventCoalescer {
    panel: TouchPanel,
    tx: Sender<Event>,
}

impl EventCoalescer {
    pub fn new(panel: TouchPanel, tx: Sender<Event>) -> Self {
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
                        self.tx.send(Event::Moved(touch.into())).unwrap();
                    }
                } else {
                    self.tx.send(Event::Started(touch.clone().into())).unwrap();

                    current_touches.insert(touch.track_id, touch);
                }
            }

            for (key, value) in current_touches.clone() {
                if !touches_in_current.contains(&key) {
                    self.tx.send(Event::Ended(value.into())).unwrap();

                    current_touches.remove(&key);
                }
            }
        }
    }
}
