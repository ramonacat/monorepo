use std::{collections::HashMap, error::Error};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use fontdue::Font;

use crate::gui::{
    controls::stack_panel::Direction, BoundingBox, ComputedDimensions, ComputedPosition, Control,
    Dimension, Dimensions,
};

pub fn render_stack<
    'a,
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + 'static,
>(
    target: &mut TDrawTarget,
    items: impl Iterator<Item = &'a mut Box<dyn Control<TDrawTarget, TError>>>,
    dimensions: Dimensions,
    position: ComputedPosition,
    direction: Direction,
    fonts: &[Font],
) -> (HashMap<usize, BoundingBox>, BoundingBox) {
    let width = match dimensions.width {
        crate::gui::Dimension::Auto => 100, // FIXME: this should be based on the dimensions of the content as it renders!
        crate::gui::Dimension::Pixel(px) => px,
    };

    let height = match dimensions.height {
        crate::gui::Dimension::Auto => 100, // FIXME: this should be based on the dimensions of the content as it renders!
        crate::gui::Dimension::Pixel(px) => px,
    };

    let mut bounding_boxes = HashMap::new();

    let mut current_x = position.0;
    let mut current_y = position.1;

    for (index, control) in items.enumerate() {
        let inner_bounding_box = control.render(
            target,
            Some(Dimensions {
                width: if direction == Direction::Horizontal {
                    Dimension::Auto
                } else {
                    Dimension::Pixel(width)
                },
                height: if direction == Direction::Horizontal {
                    Dimension::Pixel(height)
                } else {
                    Dimension::Auto
                },
            }),
            Some(ComputedPosition(current_x, current_y)),
            fonts,
        );

        if direction == Direction::Horizontal {
            current_x = inner_bounding_box.position.0 + inner_bounding_box.dimensions.width;
        } else {
            current_y = inner_bounding_box.position.1 + inner_bounding_box.dimensions.height;
        }

        bounding_boxes.insert(index, inner_bounding_box);
    }

    (
        bounding_boxes,
        BoundingBox {
            position: ComputedPosition(position.0, position.1),
            dimensions: ComputedDimensions {
                width: if direction == Direction::Horizontal {
                    current_x - position.0
                } else {
                    width
                },
                height: if direction == Direction::Horizontal {
                    height
                } else {
                    current_y - position.1
                },
            },
        },
    )
}
