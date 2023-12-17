use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{Point, Size},
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};
use fontdue::Font;
use std::error::Error;
use std::fmt::Debug;

use crate::gui::{BoundingBox, ComputedDimensions, ComputedPosition, Control, EventResult};

pub struct Button<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    content: Box<dyn Control<TDrawTarget, TError>>,
    action: Box<dyn FnMut() -> EventResult>,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(
        content: Box<dyn Control<TDrawTarget, TError>>,
        action: Box<dyn FnMut() -> EventResult>,
    ) -> Self {
        Self { content, action }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for Button<TDrawTarget, TError>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: ComputedDimensions,
        position: ComputedPosition,
        fonts: &[Font],
    ) -> BoundingBox {
        let rectangle = Rectangle::new(
            Point {
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
            ComputedDimensions {
                width: dimensions.width - 2,
                height: dimensions.height - 2,
            },
            ComputedPosition(position.0 + 1, position.1 + 1),
            fonts,
        );

        BoundingBox {
            position,
            dimensions,
        }
    }

    fn on_touch(&mut self, _position: ComputedPosition) -> EventResult {
        (self.action)()
    }

    fn compute_dimensions(&mut self, fonts: &[Font]) -> crate::gui::ComputedDimensions {
        let from_child = self.content.compute_dimensions(fonts);

        ComputedDimensions {
            width: from_child.width + 2,
            height: from_child.height + 2,
        }
    }
}
