use std::error::Error;
use std::fmt::Debug;

use embedded_graphics::{
    draw_target::{self, DrawTarget},
    pixelcolor::BinaryColor,
};

use crate::gui::{
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
        dimension_override: Option<Dimensions>,
        position_override: Option<crate::gui::ComputedPosition>,
        fonts: &[fontdue::Font],
    ) -> crate::gui::BoundingBox {
        let dimensions = dimension_override.unwrap_or(self.dimensions);

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

        let width = match dimensions.width {
            crate::gui::Dimension::Auto => 100, // FIXME: this should be based on the dimensions of the content as it renders!
            crate::gui::Dimension::Pixel(px) => px,
        };

        let mut current_y = position_y;

        for control in self.children.iter() {
            let inner_bounding_box = control.render(
                target,
                Some(Dimensions {
                    width: Dimension::Pixel(width),
                    height: Dimension::Auto,
                }),
                Some(ComputedPosition(position_x, current_y)),
                fonts,
            );

            current_y += inner_bounding_box.position.1 + inner_bounding_box.dimensions.height;
        }

        BoundingBox {
            position: ComputedPosition(position_x, current_y),
            dimensions: ComputedDimensions {
                width,
                height: current_y - position_y,
            },
        }
    }

    fn on_touch(&mut self, position: crate::gui::ComputedPosition) -> crate::gui::EventResult {
        todo!()
    }
}
