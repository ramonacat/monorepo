use std::{collections::HashMap, error::Error};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use fontdue::Font;

use crate::gui::{
    controls::stack_panel::Direction, BoundingBox, ComputedDimensions, ComputedPosition, Control,
};

pub fn render_stack<
    'a,
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + 'static,
>(
    target: &mut TDrawTarget,
    items: impl Iterator<Item = &'a mut Box<dyn Control<TDrawTarget, TError>>>,
    dimensions: ComputedDimensions,
    position: ComputedPosition,
    direction: Direction,
    fonts: &[Font],
) -> (HashMap<usize, BoundingBox>, BoundingBox) {
    let mut bounding_boxes = HashMap::new();

    let mut current_x = position.0;
    let mut current_y = position.1;

    for (index, control) in items.enumerate() {
        let control_size = control.compute_dimensions(fonts);
        let inner_bounding_box = control.render(
            target,
            control_size,
            ComputedPosition(current_x, current_y),
            fonts,
        );

        println!("{:?} {:?} {:?}", index, control_size, inner_bounding_box);

        if direction == Direction::Horizontal {
            current_x = inner_bounding_box.position.0 + control_size.width;
        } else {
            current_y = inner_bounding_box.position.1 + control_size.height;
        }

        bounding_boxes.insert(index, inner_bounding_box);
    }

    (
        bounding_boxes,
        BoundingBox {
            position: ComputedPosition(position.0, position.1),
            dimensions: dimensions,
        },
    )
}
