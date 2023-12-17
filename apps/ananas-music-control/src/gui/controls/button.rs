use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{Point, Size},
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};
use fontdue::Font;
use std::error::Error;
use std::fmt::Debug;

use crate::gui::{
    positioning::{compute_dimensions_with_override, compute_position_with_override},
    BoundingBox, ComputedDimensions, ComputedPosition, Control, Dimension, Dimensions, EventResult,
    Position,
};

pub struct Button<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    content: Box<dyn Control<TDrawTarget, TError>>,
    dimensions: Dimensions,
    position: Position,
    action: Box<dyn FnMut() -> EventResult>,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(
        content: Box<dyn Control<TDrawTarget, TError>>,
        dimensions: Dimensions,
        position: Position,
        action: Box<dyn FnMut() -> EventResult>,
    ) -> Self {
        Self {
            content,
            dimensions,
            position,
            action,
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for Button<TDrawTarget, TError>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions_override: Option<Dimensions>,
        position_override: Option<ComputedPosition>,
        fonts: &[Font],
    ) -> BoundingBox {
        let dimensions = compute_dimensions_with_override(self.dimensions, dimensions_override);
        let position = compute_position_with_override(self.position, position_override);

        let forced_width = match dimensions.width {
            Dimension::Auto => Dimension::Auto,
            Dimension::Pixel(px) => Dimension::Pixel(px + 2),
        };

        let forced_height = match dimensions.height {
            Dimension::Auto => Dimension::Auto,
            Dimension::Pixel(px) => Dimension::Pixel(px + 2),
        };

        let inner_position = ComputedPosition(position.0 + 1, position.1 + 1);

        let inner_bounding_box = self.content.render(
            target,
            Some(Dimensions {
                width: forced_width,
                height: forced_height,
            }),
            Some(inner_position),
            fonts,
        );
        let new_dimensions = ComputedDimensions {
            width: inner_bounding_box.dimensions.width + 2,
            height: inner_bounding_box.dimensions.height + 2,
        };

        let rectangle = Rectangle::new(
            Point {
                x: inner_position.0 as i32 - 1,
                y: inner_position.1 as i32 - 1,
            },
            Size {
                width: new_dimensions.width as u32,
                height: new_dimensions.height as u32,
            },
        );
        let style = PrimitiveStyleBuilder::new()
            .stroke_alignment(embedded_graphics::primitives::StrokeAlignment::Inside)
            .stroke_width(1)
            .stroke_color(BinaryColor::On)
            .build();
        rectangle.draw_styled(&style, target).unwrap();

        BoundingBox {
            position,
            dimensions: new_dimensions,
        }
    }

    fn on_touch(&mut self, _position: ComputedPosition) -> EventResult {
        (self.action)()
    }
}
