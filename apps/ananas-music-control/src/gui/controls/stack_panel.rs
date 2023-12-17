use std::cmp::max;
use std::fmt::Debug;
use std::{collections::HashMap, error::Error};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::{BoundingBox, Control};
use crate::gui::{ComputedDimensions, ComputedPosition};

#[derive(Debug, Eq, PartialEq, Clone, Copy)]
pub enum Direction {
    Vertical,
    Horizontal,
}

pub struct StackPanel<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
    bounding_boxes: HashMap<usize, BoundingBox>,
    direction: Direction,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    StackPanel<TDrawTarget, TError>
{
    pub fn new(children: Vec<Box<dyn Control<TDrawTarget, TError>>>, direction: Direction) -> Self {
        Self {
            children,
            bounding_boxes: HashMap::new(),
            direction,
        }
    }
}

impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    > Control<TDrawTarget, TError> for StackPanel<TDrawTarget, TError>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: ComputedDimensions,
        position: ComputedPosition,
        fonts: &[fontdue::Font],
    ) -> crate::gui::BoundingBox {
        let render_result = crate::gui::layouts::stack::render_stack(
            target,
            self.children.iter_mut(),
            dimensions,
            position,
            self.direction,
            fonts,
        );

        for (child_index, child_bounding_box) in render_result.0 {
            self.bounding_boxes.insert(child_index, child_bounding_box);
        }

        render_result.1
    }

    fn on_touch(&mut self, position: crate::gui::ComputedPosition) -> crate::gui::EventResult {
        for (i, bounding_box) in self.bounding_boxes.iter() {
            if bounding_box.contains(position) {
                return self.children.get_mut(*i).unwrap().on_touch(position);
            }
        }

        return crate::gui::EventResult::NoChange;
    }

    fn compute_dimensions(&mut self, fonts: &[fontdue::Font]) -> crate::gui::ComputedDimensions {
        let mut width = 0;
        let mut height = 0;
        for child in self.children.iter_mut() {
            let child_dimensions = child.compute_dimensions(fonts);

            width = max(width, child_dimensions.width);
            height += child_dimensions.height;
        }

        ComputedDimensions { width, height }
    }
}
