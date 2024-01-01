use std::{
    error::Error,
    fmt::Debug,
    sync::mpsc::{Receiver, Sender},
    time::Duration,
};

use embedded_graphics::{
    draw_target::DrawTarget,
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable}, geometry::OriginDimensions,
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

    pub fn horizontal(left: u32, right: u32) -> Self {
        Self {
            top: 0,
            bottom: 0,
            left,
            right
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
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + FlushableDrawTarget + OriginDimensions,
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

    fn render(&mut self, location: geometry::Rectangle) {
        self.clear_screen();

        let top_left = self.draw_target.bounding_box().top_left;
        let size = self.draw_target.bounding_box().size;

        self.root_control.render(
            &mut self.draw_target,
            Dimensions::new(size.width, size.height),
            Point(top_left.x as u32, top_left.y as u32),
            &self.fonts,
        );

        self.draw_target.flush(
            location
        );
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
        self.render(geometry::Rectangle::new(Point(0, 0), Dimensions::new(self.draw_target.size().width, self.draw_target.size().height)));

        loop {
            self.handle_event(Event::Heartbeat);

            if let Ok(event) = self.events_rx.recv_timeout(Duration::from_millis(50)) {
                self.handle_event(event);

                while let Ok(event) = self.events_rx.try_recv() {
                    self.handle_event(event);
                }
            }

            let mut redraw = false;
            let mut redraw_start_x = self.draw_target.size().width;
            let mut redraw_start_y = self.draw_target.size().height;
            let mut redraw_end_x = 0;
            let mut redraw_end_y = 0;

            while let Ok(command) = command_rx.try_recv() {
                // TODO: Coalesce the events and do a partial redraw!

                match command {
                    GuiCommand::Redraw(position, dimensions) => {
                        if position.0 < redraw_start_x {
                            redraw_start_x = position.0;
                        }

                        if position.1 < redraw_start_y {
                            redraw_start_y = position.1;
                        }

                        if position.0 + dimensions.width() > redraw_end_x {
                            redraw_end_x = position.0 + dimensions.width();
                        }

                        if position.1 + dimensions.height() > redraw_end_y {
                            redraw_end_y = position.1 + dimensions.height();
                        }
                        redraw = true;
                    },
                    GuiCommand::ReplaceRoot(mut new_root) => {
                        new_root.register_command_channel(command_tx.clone());
                        self.root_control = new_root;
                        redraw = true;
                        redraw_start_x = 0;
                        redraw_start_y = 0;
                        redraw_end_x = self.draw_target.size().width;
                        redraw_end_y = self.draw_target.size().height;
                    }
                }
            }

            if redraw {
                println!("{} {} {} {}", redraw_start_x, redraw_start_y, redraw_end_x, redraw_end_y);
                self.render(geometry::Rectangle::new(Point(redraw_start_x, redraw_start_y), Dimensions::new(redraw_end_x - redraw_start_x, redraw_end_y - redraw_start_y)));
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
