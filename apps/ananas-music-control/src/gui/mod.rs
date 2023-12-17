use std::{
    error::Error,
    fmt::Debug,
    sync::mpsc::{Receiver, Sender}, time::Duration,
};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use fontdue::Font;

use crate::epaper::FlushableDrawTarget;

pub mod controls;
mod layouts;

#[derive(Debug, Clone, Copy)]
pub struct Position(pub u32, pub u32);

#[derive(Debug, Clone, Copy)]
pub struct Dimensions {
    width: u32,
    height: u32,
}

#[derive(Debug, Clone)]
pub struct BoundingBox {
    position: Position,
    dimensions: Dimensions,
}

impl BoundingBox {
    fn contains(&self, position: Position) -> bool {
        position.0 > self.position.0
            && position.0 < self.position.0 + self.dimensions.width
            && position.1 > self.position.1
            && position.1 < self.position.1 + self.dimensions.height
    }
}

pub struct Gui<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
{
    fonts: Vec<Font>,
    draw_target: TDrawTarget,
    root_control: Box<dyn Control<TDrawTarget, TError>>,
    events_rx: Receiver<Event>,
}

impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + FlushableDrawTarget,
        TError: Error + Debug,
    > Gui<TDrawTarget, TError>
{
    pub fn new(
        fonts: Vec<Font>,
        draw_target: TDrawTarget,
        root_control: Box<dyn Control<TDrawTarget, TError>>,
        events_rx: Receiver<Event>,
    ) -> Self {
        Gui {
            fonts,
            draw_target,
            root_control,
            events_rx,
        }
    }

    fn handle_event(&mut self, event: Event) {
        match event {
            Event::Touch(position) => {
                self.root_control.on_touch(position);
            }
        }
    }

    fn render(&mut self) {
        let top_left = self.draw_target.bounding_box().top_left;
        let size = self.draw_target.bounding_box().size;

        self.root_control.render(
            &mut self.draw_target,
            Dimensions {
                width: size.width,
                height: size.height,
            },
            Position(top_left.x as u32, top_left.y as u32),
            &self.fonts,
        );

        self.draw_target.flush();
    }

    pub fn run(mut self) {
        let (command_tx, command_rx) = std::sync::mpsc::channel();

        self.root_control.register_command_channel(command_tx);
        self.render();

        loop {
            if let Ok(event) = self.events_rx.recv_timeout(Duration::from_millis(50)) {
                self.handle_event(event);
            } else {
                continue;
            }

            while let Ok(event) = self.events_rx.try_recv() {
                self.handle_event(event);
            }

            let mut redraw = false;
            while let Ok(command) = command_rx.try_recv() {
                // TODO: Coalesce the events and do a partial redraw!

                match command {
                    GuiCommand::Redraw(_, _) => redraw = true,
                }
            }

            if redraw {
                self.render();
            }

            // todo sleep here?
        }
    }
}

pub enum Event {
    Touch(Position),
}

#[derive(Debug)]
pub enum GuiCommand {
    Redraw(Position, Dimensions),
}

pub trait Control<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
>
{
    fn register_command_channel(&mut self, tx: Sender<GuiCommand>);
    fn compute_dimensions(&mut self, fonts: &[Font]) -> Dimensions;

    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: Dimensions,
        position: Position,
        fonts: &[Font],
    ) -> BoundingBox;
    fn on_touch(&mut self, position: Position);
}
