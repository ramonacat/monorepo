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
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(
        content: Box<dyn Control<TDrawTarget, TError>>,
        dimensions: Dimensions,
        position: Position,
    ) -> Self {
        Self {
            content,
            dimensions,
            position,
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for Button<TDrawTarget, TError>
{
    fn render(
        &self,
        target: &mut TDrawTarget,
        dimensions_override: Option<Dimensions>,
        position_override: Option<ComputedPosition>,
        fonts: &[Font],
    ) -> BoundingBox {
        let dimensions = dimensions_override.map(|x| {
            let width = match x.width {
                Dimension::Auto => self.dimensions.width,
                px@Dimension::Pixel(_) => px,
            };

            let height = match x.height {
                Dimension::Auto => self.dimensions.height,
                px@Dimension::Pixel(_) => px,
            };

            Dimensions { width, height }
        }).unwrap_or(self.dimensions);

        let forced_width = match dimensions.width {
            Dimension::Auto => Dimension::Auto,
            Dimension::Pixel(px) => Dimension::Pixel(px + 2),
        };

        let forced_height = match dimensions.height {
            Dimension::Auto => Dimension::Auto,
            Dimension::Pixel(px) => Dimension::Pixel(px),
        };

        let position_x = position_override.map(|p| p.0).unwrap_or_else(|| {
            match self.position {
                Position::Specified(x, _) => x,
                Position::FromParent => 0, // FIXME: should this be an error instead?
            }
        });

        let position_y = position_override.map(|p| p.1).unwrap_or_else(|| {
            match self.position {
                Position::Specified(_, y) => y,
                Position::FromParent => 0, // FIXME: should this be an error instead?
            }
        });

        let inner_position = ComputedPosition(position_x + 1, position_y + 1);

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
            position: ComputedPosition(position_x, position_y),
            dimensions: new_dimensions,
        }
    }

    fn on_touch(&mut self, _position: ComputedPosition) -> EventResult {
        todo!()
    }
}
