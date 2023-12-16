use std::fmt::Debug;
use std::{cmp::min, error::Error};

use embedded_graphics::geometry::Point;
use embedded_graphics::image::{Image, ImageRaw};
use embedded_graphics::Drawable;
use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use fontdue::{
    layout::{Layout, TextStyle},
    Font,
};

use crate::gui::positioning::{compute_dimensions_with_override, compute_position_with_override};
use crate::gui::{
    BoundingBox, ComputedDimensions, ComputedPosition, Control, Dimension, Dimensions, EventResult,
    Position,
};

pub struct Text {
    text: String,
    font_size: usize,
    position: Position,
    dimensions: Dimensions,
}

impl Text {
    pub fn new(text: String, font_size: usize, position: Position, dimensions: Dimensions) -> Self {
        Self {
            text,
            font_size,
            position,
            dimensions,
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for Text
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions_override: Option<Dimensions>,
        position_override: Option<ComputedPosition>,
        fonts: &[Font],
    ) -> BoundingBox {
        let dimensions = compute_dimensions_with_override(self.dimensions, dimensions_override);
        let position = compute_position_with_override(self.position, position_override);

        let mut layout = Layout::new(fontdue::layout::CoordinateSystem::PositiveYDown);

        layout.append(fonts, &TextStyle::new(&self.text, self.font_size as f32, 0));

        let mut pixels = vec![];
        for glyph in layout.glyphs() {
            let (metrics, data) = fonts[glyph.font_index].rasterize_config(glyph.key);

            for (i, c) in data.iter().enumerate() {
                let pixel_x = (i % metrics.width) + glyph.x as usize;
                let pixel_y = (i / metrics.width) + glyph.y as usize;

                if *c > 0 {
                    pixels.push((pixel_x, pixel_y));
                }
            }
        }

        let rendered_width = pixels.iter().map(|x| x.0).max().unwrap() as u32;
        let rendered_height = pixels.iter().map(|x| x.1).max().unwrap() as u32;

        let dimension_x = match dimensions.width {
            Dimension::Auto => None,
            Dimension::Pixel(px) => Some(px),
        };

        let dimension_y = match dimensions.height {
            Dimension::Auto => None,
            Dimension::Pixel(px) => Some(px),
        };

        let visible_width = dimension_x
            .map(|x| min(x, rendered_width))
            .unwrap_or(rendered_width);
        let visible_height = dimension_y
            .map(|y| min(y, rendered_height))
            .unwrap_or(rendered_height);

        let rounded_width_in_bytes = (visible_width + 7) / 8;

        let mut bytes = vec![0u8; ((1 + rounded_width_in_bytes) * visible_height) as usize];

        for (x, y) in pixels.iter() {
            if *x >= visible_width as usize || *y >= visible_height as usize {
                continue;
            }

            let pixel_index = (y * rounded_width_in_bytes as usize * 8) + x;
            bytes[pixel_index / 8] |= 1 << (7 - (pixel_index % 8));
        }

        let image_raw = ImageRaw::<BinaryColor>::new(&bytes, 8 * rounded_width_in_bytes as u32);

        let centered_position = {
            let centered_x = if let Dimension::Pixel(dimension_x) = dimensions.width {
                (dimension_x - visible_width) / 2
            } else {
                0
            } + position.0;

            let centered_y = if let Dimension::Pixel(dimension_y) = dimensions.height {
                (dimension_y - visible_height) / 2
            } else {
                0
            } + position.1;

            ComputedPosition(centered_x, centered_y)
        };

        let image = Image::new(
            &image_raw,
            Point {
                x: centered_position.0 as i32,
                y: centered_position.1 as i32,
            },
        );

        image.draw(target).unwrap();

        BoundingBox {
            position: centered_position,
            dimensions: ComputedDimensions {
                width: dimension_x.unwrap_or(visible_width),
                height: dimension_y.unwrap_or(visible_height),
            },
        }
    }

    fn on_touch(&mut self, _position: ComputedPosition) -> EventResult {
        EventResult::NoChange
    }
}
