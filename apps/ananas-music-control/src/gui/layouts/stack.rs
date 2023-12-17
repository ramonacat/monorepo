use std::{collections::HashMap, error::Error};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use fontdue::Font;

use crate::gui::{controls::stack_panel::Direction, Control, Dimensions, Point, Rectangle};

pub fn render_stack<
    'a,
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + 'static,
>(
    target: &mut TDrawTarget,
    items: impl Iterator<Item = &'a mut Box<dyn Control<TDrawTarget, TError>>>,
    dimensions: Dimensions,
    position: Point,
    direction: Direction,
    fonts: &[Font],
) -> HashMap<usize, Rectangle> {
    let mut bounding_boxes = HashMap::new();

    let mut current_x = position.0;
    let mut current_y = position.1;

    for (index, control) in items.enumerate() {
        let control_size = control.compute_dimensions(fonts);

        let control_dimensions = Dimensions {
            width: if direction == Direction::Horizontal {
                control_size.width
            } else {
                dimensions.width
            },
            height: if direction == Direction::Horizontal {
                dimensions.height
            } else {
                control_size.height
            },
        };
        let control_position = Point(current_x, current_y);
        control.render(target, control_dimensions, control_position, fonts);

        if direction == Direction::Horizontal {
            current_x = current_x + control_size.width;
        } else {
            current_y = current_y + control_size.height;
        }

        bounding_boxes.insert(
            index,
            Rectangle {
                position: control_position,
                dimensions: control_dimensions,
            },
        );
    }

    bounding_boxes
}
