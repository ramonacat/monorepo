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

use super::{
    BoundingBox, ComputedDimensions, Control, Dimension, Dimensions, EventResult, Position, ComputedPosition,
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
        &self,
        target: &mut TDrawTarget,
        dimensions_override: Option<Dimensions>,
        position_override: Option<ComputedPosition>,
        fonts: &[Font],
    ) -> BoundingBox {
        let dimensions = dimensions_override.unwrap_or(self.dimensions);

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

        let rendered_width = pixels.iter().map(|x| x.0).max().unwrap() as u32;
        let rendered_height = pixels.iter().map(|x| x.1).max().unwrap() as u32;

        let dimension_x = match dimensions.width {
            super::Dimension::Auto => None,
            super::Dimension::Pixel(px) => Some(px),
        };

        let dimension_y = match dimensions.height {
            super::Dimension::Auto => None,
            super::Dimension::Pixel(px) => Some(px),
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
            if *x > visible_width as usize || *y > visible_height as usize {
                continue;
            }

            let pixel_index = (y * rounded_width_in_bytes as usize * 8) + x;
            bytes[pixel_index / 8] |= 1 << (7 - (pixel_index % 8));
        }

        let image_raw = ImageRaw::<BinaryColor>::new(&bytes, 8 * rounded_width_in_bytes as u32);

        let centered_position = {
            let centered_x = if let Dimension::Pixel(dimension_x) = dimensions.width {
                println!("{:?} {:?}", dimension_x, visible_width);
                (dimension_x - visible_width) / 2
            } else {
                0
            } + position_x;

            let centered_y = if let Dimension::Pixel(dimension_y) = dimensions.height {
                (dimension_y - visible_height) / 2
            } else {
                0
            } + position_y;

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
        println!("Touch received");

        EventResult::NoChange
    }
}

pub struct Button<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    content: Box<dyn Control<TDrawTarget, TError>>,
    dimensions: Dimensions,
    position: Position,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Button<TDrawTarget, TError>
{
    pub fn new(content: Box<dyn Control<TDrawTarget, TError>>, dimensions: Dimensions, position: Position) -> Self {
        Self {
            content,
            dimensions,
            position,
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for Button<TDrawTarget, TError>
{
    fn render(
        &self,
        target: &mut TDrawTarget,
        dimension_override: Option<Dimensions>,
        position_override: Option<ComputedPosition>,
        fonts: &[Font],
    ) -> BoundingBox {
        let forced_width = match self.dimensions.width {
            super::Dimension::Auto => Dimension::Auto,
            super::Dimension::Pixel(px) => Dimension::Pixel(px + 2),
        };

        let forced_height = match self.dimensions.height {
            Dimension::Auto => Dimension::Auto,
            Dimension::Pixel(px) => Dimension::Pixel(px),
        };

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

        let inner_position = ComputedPosition(position_x + 1, position_y + 1);

        let inner_bounding_box = self.content.render(
            target,
            Some(Dimensions {
                width: forced_width,
                height: forced_height,
            }),
            Some(inner_position),
            fonts,
        );
        let new_dimensions = ComputedDimensions {
            width: inner_bounding_box.dimensions.width + 2,
            height: inner_bounding_box.dimensions.height + 2,
        };

        let rectangle = Rectangle::new(
            Point {
                x: inner_position.0 as i32 - 1,
                y: inner_position.1 as i32 - 1,
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
            position: ComputedPosition(position_x, position_y),
            dimensions: new_dimensions,
        }
    }

    fn on_touch(&mut self, _position: ComputedPosition) -> EventResult {
        todo!()
    }
}
