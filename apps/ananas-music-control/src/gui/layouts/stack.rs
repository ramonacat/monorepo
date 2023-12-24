use std::{cmp::max, collections::BTreeMap, error::Error};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::{
    fonts::Fonts, geometry::Rectangle, Control, Dimensions, Orientation, Point, StackUnitDimension,
};

pub fn render_stack<
    'a,
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + 'static,
>(
    target: &mut TDrawTarget,
    items: impl Iterator<Item = &'a mut Box<dyn Control<TDrawTarget, TError>>>,
    dimensions: Dimensions,
    position: Point,
    direction: Orientation,
    unit_dimensions: &[StackUnitDimension],
    fonts: &Fonts,
) -> BTreeMap<usize, Rectangle> {
    let mut bounding_boxes = BTreeMap::new();

    let mut current_x = position.0;
    let mut current_y = position.1;

    let mut items: Vec<_> = items.collect();

    // TODO: do an if here instead and return an error as needed
    assert!(unit_dimensions.len() <= items.len());

    let stretch_count = unit_dimensions
        .iter()
        .filter(|x| matches!(x, StackUnitDimension::Stretch))
        .count() as u32;

    for (index, control) in items.iter_mut().enumerate() {
        let control_size = control.compute_natural_dimensions(fonts);
        let current_control_unit_dimension = unit_dimensions
            .get(index)
            .unwrap_or(&StackUnitDimension::Auto);

        let control_dimensions = Dimensions::new(
            if direction == Orientation::Horizontal {
                match current_control_unit_dimension {
                    StackUnitDimension::Auto => control_size.width(),
                    StackUnitDimension::Stretch => 0, // we will handle this later
                    StackUnitDimension::Pixel(px) => *px,
                }
            } else {
                dimensions.width()
            },
            if direction == Orientation::Horizontal {
                dimensions.height()
            } else {
                match current_control_unit_dimension {
                    StackUnitDimension::Auto => control_size.height(),
                    StackUnitDimension::Stretch => 0, // we will handle this later
                    StackUnitDimension::Pixel(px) => *px,
                }
            },
        );
        let control_position = Point(current_x, current_y);

        if direction == Orientation::Horizontal {
            current_x += control_dimensions.width();
        } else {
            current_y += control_dimensions.height();
        }

        bounding_boxes.insert(index, Rectangle::new(control_position, control_dimensions));
    }

    let stretch_dimension = if direction == Orientation::Horizontal {
        (dimensions.width() - (current_x - position.0)) / max(stretch_count, 1)
    } else {
        (dimensions.height() - (current_y - position.1)) / max(stretch_count, 1)
    };

    let mut dimension_offset: u32 = 0;
    for (control_index, bounding_box) in bounding_boxes.iter_mut() {
        let adjusted_positon = Point(
            bounding_box.position().0
                + if direction == Orientation::Horizontal {
                    dimension_offset
                } else {
                    0
                },
            bounding_box.position().1
                + if direction == Orientation::Horizontal {
                    0
                } else {
                    dimension_offset
                },
        );

        match unit_dimensions
            .get(*control_index)
            .unwrap_or(&StackUnitDimension::Auto)
        {
            StackUnitDimension::Stretch => {
                let new_width = if direction == Orientation::Horizontal {
                    stretch_dimension
                } else {
                    bounding_box.dimensions().width()
                };

                let new_height = if direction == Orientation::Horizontal {
                    bounding_box.dimensions().height()
                } else {
                    stretch_dimension
                };

                *bounding_box =
                    Rectangle::new(adjusted_positon, Dimensions::new(new_width, new_height));

                dimension_offset += stretch_dimension;
            }
            StackUnitDimension::Auto | StackUnitDimension::Pixel(_) => {
                *bounding_box = Rectangle::new(adjusted_positon, bounding_box.dimensions());
            }
        }
    }

    for (index, bounding_box) in bounding_boxes.iter() {
        items[*index].render(
            target,
            bounding_box.dimensions(),
            bounding_box.position(),
            fonts,
        );
    }

    bounding_boxes
}
