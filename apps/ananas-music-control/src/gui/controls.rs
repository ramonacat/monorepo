use std::fmt::Debug;
use std::{cmp::min, error::Error};

use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{Point, Size},
    image::{Image, ImageRaw},
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
    Drawable,
};
use fontdue::{
    layout::{Layout, TextStyle},
    Font,
};

use super::{BoundingBox, ComputedDimensions, Control, Dimensions, EventResult, Position};

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
    fn render(&self, target: &mut TDrawTarget, fonts: &[Font]) -> BoundingBox {
        let mut layout = Layout::new(fontdue::layout::CoordinateSystem::PositiveYDown);

        layout.append(fonts, &TextStyle::new(&self.text, self.font_size as f32, 0));

        let mut pixels = vec![];
        for glyph in layout.glyphs() {
            let (metrics, data) = fonts[glyph.font_index].rasterize_config(glyph.key);

            for (i, c) in data.iter().enumerate() {
                let pixel_x = (i % metrics.width) + glyph.x as usize;
                let pixel_y = (i / metrics.width) + glyph.y as usize;

                if *c > 63 {
                    pixels.push((pixel_x, pixel_y));
                }
            }
        }

        let max_x = pixels.iter().map(|x| x.0).max().unwrap() as u32;
        let max_y = pixels.iter().map(|x| x.1).max().unwrap() as u32;

        let dimension_x = match self.dimensions.width {
            super::Dimension::Auto => None,
            super::Dimension::Pixel(px) => Some(px),
        };

        let dimension_y = match self.dimensions.height {
            super::Dimension::Auto => None,
            super::Dimension::Pixel(px) => Some(px),
        };

        let max_x = dimension_x.map(|x| min(x, max_x)).unwrap_or(max_x);
        let max_y = dimension_y.map(|y| min(y, max_y)).unwrap_or(max_y);

        let rounded_width_in_bytes = (max_x + 7) / 8;

        let mut bytes = vec![0u8; ((1 + rounded_width_in_bytes) * (max_y)) as usize];

        for (x, y) in pixels.iter() {
            let pixel_index = (y * rounded_width_in_bytes as usize * 8) + x;
            bytes[pixel_index / 8] |= 1 << (7 - (pixel_index % 8));
        }

        let image_raw = ImageRaw::<BinaryColor>::new(&bytes, 8 * rounded_width_in_bytes as u32);
        let image = Image::new(
            &image_raw,
            Point {
                x: self.position.x as i32,
                y: self.position.y as i32,
            },
        );

        image.draw(target).unwrap();

        let pixel_width = 8 * rounded_width_in_bytes;
        BoundingBox {
            position: self.position,
            dimensions: ComputedDimensions {
                width: dimension_x.unwrap_or(pixel_width as u32),
                height: dimension_y
                    .unwrap_or((pixels.len() as u32 / rounded_width_in_bytes) as u32),
            },
        }
    }

    fn on_touch(&mut self, _position: Position) -> EventResult {
        println!("Touch received");

        EventResult::NoChange
    }
}

pub struct Button<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    content: Box<dyn Control<TDrawTarget, TError>>,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(content: Box<dyn Control<TDrawTarget, TError>>) -> Self {
        Self { content }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for Button<TDrawTarget, TError>
{
    fn render(&self, target: &mut TDrawTarget, fonts: &[Font]) -> BoundingBox {
        let inner_bounding_box = self.content.render(target, fonts);
        let new_position = Position {
            x: inner_bounding_box.position.x - 1,
            y: inner_bounding_box.position.y - 1,
        };
        let new_dimensions = ComputedDimensions {
            width: inner_bounding_box.dimensions.width + 2,
            height: inner_bounding_box.dimensions.height + 2,
        };

        println!("::: {:?} {:?}", new_position, new_dimensions);
        let rectangle = Rectangle::new(
            Point {
                x: new_position.x as i32,
                y: new_position.y as i32,
            },
            Size {
                width: new_dimensions.width as u32,
                height: new_dimensions.height as u32,
            },
        );
        let style = PrimitiveStyleBuilder::new()
            .stroke_alignment(embedded_graphics::primitives::StrokeAlignment::Inside)
            .stroke_width(1)
            .stroke_color(BinaryColor::On)
            .build();
        rectangle.draw_styled(&style, target).unwrap();

        BoundingBox {
            position: new_position,
            dimensions: new_dimensions,
        }
    }

    fn on_touch(&mut self, position: Position) -> EventResult {
        todo!()
    }
}
