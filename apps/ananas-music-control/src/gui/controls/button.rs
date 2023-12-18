use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::Size,
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};
use fontdue::Font;
use std::fmt::Debug;
use std::{error::Error, sync::mpsc::Sender};

use crate::gui::{Control, Dimensions, GuiCommand, Padding, Point};

pub struct Button<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    content: Box<dyn Control<TDrawTarget, TError>>,
    action: Box<dyn FnMut()>,
    command_channel: Option<Sender<GuiCommand>>,
    padding: Padding,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(
        content: Box<dyn Control<TDrawTarget, TError>>,
        padding: Padding,
        action: Box<dyn FnMut()>,
    ) -> Self {
        Self {
            content,
            action,
            padding,
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
                width: dimensions.width(),
                height: dimensions.height(),
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
            Dimensions::new(dimensions.width() - self.padding.left - self.padding.right - 2, dimensions.height() - self.padding.top - self.padding.bottom - 2),
            Point(
                position.0 + 1 + self.padding.left,
                position.1 + 1 + self.padding.top,
            ),
            fonts,
        );
    }

    fn on_touch(&mut self, _position: Point) {
        (self.action)();
    }

    fn compute_dimensions(&mut self, fonts: &[Font]) -> crate::gui::Dimensions {
        let child_dimensions = self.content.compute_dimensions(fonts);

        Dimensions::new(
            child_dimensions.width() + 2 + self.padding.left + self.padding.right,
            child_dimensions.height() + 2 + self.padding.top + self.padding.bottom,
        )
    }

    fn register_command_channel(&mut self, tx: std::sync::mpsc::Sender<crate::gui::GuiCommand>) {
        self.command_channel = Some(tx.clone());
        self.content.register_command_channel(tx);
    }
}
