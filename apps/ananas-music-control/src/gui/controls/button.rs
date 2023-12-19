use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::Size,
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyle, PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};
use fontdue::Font;
use std::fmt::Debug;
use std::{error::Error, sync::mpsc::Sender};

use crate::gui::{Control, Dimensions, GuiCommand, Padding, Point};

type Callback<TDrawTarget, TError> = Box<dyn FnMut(Sender<GuiCommand<TDrawTarget, TError>>)>;

pub struct Button<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    content: Box<dyn Control<TDrawTarget, TError>>,
    action: Callback<TDrawTarget, TError>,
    command_channel: Option<Sender<GuiCommand<TDrawTarget, TError>>>,
    padding: Padding,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(
        content: Box<dyn Control<TDrawTarget, TError>>,
        padding: Padding,
        action: Callback<TDrawTarget, TError>,
    ) -> Self {
        Self {
            content,
            action,
            padding,
            command_channel: None,
        }
    }
}

const BUTTON_STYLE: PrimitiveStyle<BinaryColor> = PrimitiveStyleBuilder::new()
    .stroke_alignment(embedded_graphics::primitives::StrokeAlignment::Inside)
    .stroke_width(1)
    .stroke_color(BinaryColor::On)
    .fill_color(BinaryColor::Off)
    .build();

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
        rectangle.draw_styled(&BUTTON_STYLE, target).unwrap();

        let dimensions = self.padding.adjust_dimensions(dimensions);
        let position = self.padding.adjust_position(position);

        self.content.render(
            target,
            Dimensions::new(dimensions.width() - 2, dimensions.height() - 2),
            Point(position.0 + 1, position.1 + 1),
            fonts,
        );
    }

    fn on_touch(&mut self, _position: Point) {
        if let Some(command_channel) = self.command_channel.as_ref() {
            (self.action)(command_channel.clone());
        }
    }

    fn compute_dimensions(&mut self, fonts: &[Font]) -> crate::gui::Dimensions {
        let child_dimensions = self.content.compute_dimensions(fonts);

        Dimensions::new(
            child_dimensions.width() + 2 + self.padding.total_horizontal(),
            child_dimensions.height() + 2 + self.padding.total_vertical(),
        )
    }

    fn register_command_channel(
        &mut self,
        tx: std::sync::mpsc::Sender<crate::gui::GuiCommand<TDrawTarget, TError>>,
    ) {
        self.command_channel = Some(tx.clone());
        self.content.register_command_channel(tx);
    }
}
