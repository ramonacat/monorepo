use super::{ComputedPosition, Dimension, Dimensions, Position};

pub fn compute_dimensions_with_override(
    dimensions: Dimensions,
    dimensions_override: Option<Dimensions>,
) -> Dimensions {
    dimensions_override
        .map(|x| {
            let width = match x.width {
                Dimension::Auto => dimensions.width,
                px @ Dimension::Pixel(_) => px,
            };

            let height = match x.height {
                Dimension::Auto => dimensions.height,
                px @ Dimension::Pixel(_) => px,
            };

            Dimensions { width, height }
        })
        .unwrap_or(dimensions)
}

pub fn compute_position_with_override(
    position: Position,
    position_override: Option<ComputedPosition>,
) -> ComputedPosition {
    let position_x = position_override.map(|p| p.0).unwrap_or_else(|| {
        match position {
            Position::Specified(x, _) => x,
            Position::FromParent => 0, // FIXME: should this be an error instead?
        }
    });

    let position_y = position_override.map(|p| p.1).unwrap_or_else(|| {
        match position {
            Position::Specified(_, y) => y,
            Position::FromParent => 0, // FIXME: should this be an error instead?
        }
    });

    ComputedPosition(position_x, position_y)
}
