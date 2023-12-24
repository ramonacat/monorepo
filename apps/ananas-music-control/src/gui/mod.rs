use std::{
    error::Error,
    fmt::Debug,
    sync::mpsc::{Receiver, Sender},
    time::Duration,
};

use embedded_graphics::{
    draw_target::DrawTarget,
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};

use crate::epaper::FlushableDrawTarget;

use self::{
    fonts::Fonts,
    geometry::{Dimensions, Point},
};

pub mod controls;
pub mod fonts;
pub mod geometry;

mod layouts;
pub mod reactivity;

pub struct Padding {
    top: u32,
    bottom: u32,
    left: u32,
    right: u32,
}

impl Padding {
    pub fn new(top: u32, bottom: u32, left: u32, right: u32) -> Self {
        Self {
            top,
            bottom,
            left,
            right,
        }
    }

    pub fn zero() -> Self {
        Self {
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
        }
    }

    pub fn vertical(top: u32, bottom: u32) -> Self {
        Self {
            top,
            bottom,
            left: 0,
            right: 0,
        }
    }

    pub fn total_vertical(&self) -> u32 {
        self.top + self.bottom
    }

    pub fn total_horizontal(&self) -> u32 {
        self.left + self.right
    }

    pub fn adjust_position(&self, point: Point) -> Point {
        Point(point.0 + self.left, point.1 + self.top)
    }

    pub fn adjust_dimensions(&self, dimensions: Dimensions) -> Dimensions {
        Dimensions::new(
            dimensions.width() - self.total_horizontal(),
            dimensions.height() - self.total_vertical(),
        )
    }
}

#[derive(Debug, Eq, PartialEq, Clone, Copy)]
pub enum Orientation {
    Vertical,
    Horizontal,
}

#[derive(Debug, Eq, PartialEq, Clone, Copy)]
pub enum StackUnitDimension {
    Auto,
    Stretch,
    Pixel(u32),
}

pub struct Gui<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
{
    fonts: Fonts,
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
        fonts: Fonts,
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
        self.root_control.on_event(event);
    }

    fn render(&mut self) {
        self.clear_screen();

        let top_left = self.draw_target.bounding_box().top_left;
        let size = self.draw_target.bounding_box().size;

        self.root_control.render(
            &mut self.draw_target,
            Dimensions::new(size.width, size.height),
            Point(top_left.x as u32, top_left.y as u32),
            &self.fonts,
        );

        self.draw_target.flush();
    }

    fn clear_screen(&mut self) {
        let rectangle = Rectangle::new(
            embedded_graphics::geometry::Point::new(0, 0),
            self.draw_target.bounding_box().size,
        );
        let style = PrimitiveStyleBuilder::new()
            .fill_color(BinaryColor::Off)
            .build();

        rectangle
            .draw_styled(&style, &mut self.draw_target)
            .unwrap();
    }

    pub fn run(mut self) {
        let (command_tx, command_rx) = std::sync::mpsc::channel();

        self.root_control
            .register_command_channel(command_tx.clone());
        self.render();

        loop {
            self.handle_event(Event::Heartbeat);

            if let Ok(event) = self.events_rx.recv_timeout(Duration::from_millis(50)) {
                self.handle_event(event);

                while let Ok(event) = self.events_rx.try_recv() {
                    self.handle_event(event);
                }
            }

            let mut redraw = false;
            while let Ok(command) = command_rx.try_recv() {
                // TODO: Coalesce the events and do a partial redraw!

                match command {
                    GuiCommand::Redraw(_, _) => redraw = true,
                    GuiCommand::ReplaceRoot(mut new_root) => {
                        new_root.register_command_channel(command_tx.clone());
                        self.root_control = new_root;
                        redraw = true;
                    }
                }
            }

            if redraw {
                self.render();
            }
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub enum Event {
    Touch(Point),
    Heartbeat,
}

pub enum GuiCommand<TDrawTarget: DrawTarget, TError: Error + Debug> {
    Redraw(Point, Dimensions),
    ReplaceRoot(Box<dyn Control<TDrawTarget, TError>>),
}

pub trait Control<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
>
{
    fn register_command_channel(&mut self, tx: Sender<GuiCommand<TDrawTarget, TError>>);
    fn compute_natural_dimensions(&mut self, fonts: &Fonts) -> Dimensions;

    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: Dimensions,
        position: Point,
        fonts: &Fonts,
    );

    fn on_event(&mut self, event: Event);
}
