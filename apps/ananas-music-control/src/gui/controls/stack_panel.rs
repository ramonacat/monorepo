use std::{error::Error, collections::HashMap};
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
    bounding_boxes: HashMap<usize, BoundingBox>
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
            bounding_boxes: HashMap::new()
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for StackPanel<TDrawTarget, TError>
{
    fn render(
        &mut self,
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

        for (index, control) in self.children.iter_mut().enumerate() {
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

            self.bounding_boxes.insert(index, inner_bounding_box);
        }

        BoundingBox {
            position: ComputedPosition(position.0, current_y),
            dimensions: ComputedDimensions {
                width,
                height: current_y - position.1,
            },
        }
    }

    fn on_touch(&mut self, position: crate::gui::ComputedPosition) -> crate::gui::EventResult {
        for (i, bounding_box) in self.bounding_boxes.iter() {
           if bounding_box.contains(position)  {
            return self.children.get_mut(*i).unwrap().on_touch(position);
           }
        }

        return crate::gui::EventResult::NoChange;
    }
}
