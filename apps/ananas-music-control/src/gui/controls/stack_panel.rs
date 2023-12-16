use std::error::Error;
use std::fmt::Debug;

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::{
    positioning::{compute_dimensions_with_override, compute_position_with_override},
    BoundingBox, ComputedDimensions, ComputedPosition, Control, Dimension, Dimensions, Position,
};

pub struct StackPanel<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    position: Position,
    dimensions: Dimensions,
    children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    StackPanel<TDrawTarget, TError>
{
    pub fn new(
        position: Position,
        dimensions: Dimensions,
        children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
    ) -> Self {
        Self {
            position,
            dimensions,
            children,
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for StackPanel<TDrawTarget, TError>
{
    fn render(
        &self,
        target: &mut TDrawTarget,
        dimensions_override: Option<Dimensions>,
        position_override: Option<crate::gui::ComputedPosition>,
        fonts: &[fontdue::Font],
    ) -> crate::gui::BoundingBox {
        let dimensions = compute_dimensions_with_override(self.dimensions, dimensions_override);
        let position = compute_position_with_override(self.position, position_override);

        let width = match dimensions.width {
            crate::gui::Dimension::Auto => 100, // FIXME: this should be based on the dimensions of the content as it renders!
            crate::gui::Dimension::Pixel(px) => px,
        };

        let mut current_y = position.1;

        for control in self.children.iter() {
            let inner_bounding_box = control.render(
                target,
                Some(Dimensions {
                    width: Dimension::Pixel(width),
                    height: Dimension::Auto,
                }),
                Some(ComputedPosition(position.0, current_y)),
                fonts,
            );

            current_y = inner_bounding_box.position.1 + inner_bounding_box.dimensions.height;
        }

        BoundingBox {
            position: ComputedPosition(position.0, current_y),
            dimensions: ComputedDimensions {
                width,
                height: current_y - position.1,
            },
        }
    }

    fn on_touch(&mut self, _position: crate::gui::ComputedPosition) -> crate::gui::EventResult {
        todo!()
    }
}
