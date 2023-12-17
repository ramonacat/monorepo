use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::Size,
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};
use fontdue::Font;
use std::fmt::Debug;
use std::{error::Error, sync::mpsc::Sender};

use crate::gui::{Control, Dimensions, GuiCommand, Point};

pub struct Button<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    content: Box<dyn Control<TDrawTarget, TError>>,
    action: Box<dyn FnMut() -> ()>,
    command_channel: Option<Sender<GuiCommand>>,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(
        content: Box<dyn Control<TDrawTarget, TError>>,
        action: Box<dyn FnMut() -> ()>,
    ) -> Self {
        Self {
            content,
            action,
            command_channel: None,
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for Button<TDrawTarget, TError>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: Dimensions,
        position: Point,
        fonts: &[Font],
    ) {
        let rectangle = Rectangle::new(
            embedded_graphics::geometry::Point {
                x: position.0 as i32,
                y: position.1 as i32,
            },
            Size {
                width: dimensions.width as u32,
                height: dimensions.height as u32,
            },
        );
        let style = PrimitiveStyleBuilder::new()
            .stroke_alignment(embedded_graphics::primitives::StrokeAlignment::Inside)
            .stroke_width(1)
            .stroke_color(BinaryColor::On)
            .fill_color(BinaryColor::Off)
            .build();
        rectangle.draw_styled(&style, target).unwrap();

        self.content.render(
            target,
            Dimensions {
                width: dimensions.width - 2,
                height: dimensions.height - 2,
            },
            Point(position.0 + 1, position.1 + 1),
            fonts,
        );
    }

    fn on_touch(&mut self, _position: Point) {
        (self.action)();
    }

    fn compute_dimensions(&mut self, fonts: &[Font]) -> crate::gui::Dimensions {
        let from_child = self.content.compute_dimensions(fonts);

        Dimensions {
            width: from_child.width + 2,
            height: from_child.height + 2,
        }
    }

    fn register_command_channel(&mut self, tx: std::sync::mpsc::Sender<crate::gui::GuiCommand>) {
        self.command_channel = Some(tx.clone());
        self.content.register_command_channel(tx);
    }
}
