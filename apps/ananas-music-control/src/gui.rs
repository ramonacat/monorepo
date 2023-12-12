use std::{collections::HashMap, error::Error, fmt::Debug};

use embedded_graphics::{
    draw_target::{self, DrawTarget},
    geometry::{Point, Size},
    image::{Image, ImageRaw},
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyle, PrimitiveStyleBuilder, Rectangle, StyledDrawable},
    Drawable,
};
use fontdue::{
    layout::{Layout, TextStyle},
    Font,
};

use crate::epaper::FlushableDrawTarget;

#[derive(Debug, Clone, Copy)]
pub struct Position {
    x: usize,
    y: usize,
}

impl Position {
    pub fn new(x: usize, y: usize) -> Self {
        Self { x, y }
    }
}

#[derive(Debug, Clone, Copy)]
pub struct Dimensions {
    width: usize,
    height: usize,
}

#[derive(Debug, Clone)]
pub struct BoundingBox {
    position: Position,
    dimensions: Dimensions,
}
impl BoundingBox {
    fn contains(&self, position: Position) -> bool {
        position.x > self.position.x
            && position.x < self.position.x + self.dimensions.width
            && position.y > self.position.y
            && position.y < self.position.y + self.dimensions.height
    }
}

pub struct Gui<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
{
    fonts: Vec<Font>,
    draw_target: TDrawTarget,
    controls: Vec<Box<dyn Control<TDrawTarget, TError>>>,
    bounding_boxes: HashMap<usize, BoundingBox>,
}

impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + FlushableDrawTarget,
        TError: Error + Debug,
    > Gui<TDrawTarget, TError>
{
    pub fn new(fonts: Vec<Font>, draw_target: TDrawTarget) -> Self {
        Gui {
            fonts,
            draw_target,
            controls: vec![],
            bounding_boxes: HashMap::new(),
        }
    }

    pub fn add_control(&mut self, control: impl Control<TDrawTarget, TError> + 'static) {
        self.controls.push(Box::new(control));
    }

    pub fn handle_event(&mut self, event: Event) {
        let mut controls_to_redraw = vec![];

        for (control_index, bounding_box) in self.bounding_boxes.iter() {
            match event {
                Event::Touch(position) => {
                    println!("{:?} {:?}", bounding_box, position);

                    if bounding_box.contains(position) {
                        let result = self.controls[*control_index].on_touch(position);

                        match result {
                            EventResult::NoChange => {}
                            EventResult::MustRedraw => {
                                controls_to_redraw.push(*control_index);
                            }
                        }
                    }
                }
            };
        }

        for control_index in &controls_to_redraw {
            let bounding_box =
                self.controls[*control_index].render(&mut self.draw_target, &self.fonts);
            self.bounding_boxes.insert(*control_index, bounding_box);
        }

        if controls_to_redraw.len() > 0 {
            self.draw_target.flush();
        }
    }

    pub fn render(&mut self) {
        for (control_index, control) in self.controls.iter().enumerate() {
            let bounding_box =
                self.controls[control_index].render(&mut self.draw_target, &self.fonts);
            self.bounding_boxes
                .insert(control_index, bounding_box.clone());

            println!("BBox: {:?}", bounding_box);
        }

        self.draw_target.flush();
    }
}

pub enum Event {
    Touch(Position),
}

pub enum EventResult {
    NoChange,
    MustRedraw,
}

pub trait Control<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
>
{
    fn render(&self, target: &mut TDrawTarget, fonts: &[Font]) -> BoundingBox;
    fn on_touch(&mut self, position: Position) -> EventResult;
}

pub struct TextBox {
    text: String,
    font_size: usize,
    position: Position,
}

impl TextBox {
    pub fn new(text: String, font_size: usize, position: Position) -> Self {
        Self {
            text,
            font_size,
            position,
        }
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for TextBox
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

        let max_x = pixels.iter().map(|x| x.0).max().unwrap();
        let max_y = pixels.iter().map(|x| x.1).max().unwrap();

        let rounded_width_in_bytes = (max_x + 7) / 8;

        let mut bytes = vec![0u8; (1 + rounded_width_in_bytes) * (max_y)];

        for (x, y) in pixels.iter() {
            let pixel_index = (y * rounded_width_in_bytes * 8) + x;
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
            dimensions: Dimensions {
                width: pixel_width,
                height: pixels.len() / rounded_width_in_bytes,
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
        let new_dimensions = Dimensions {
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
