use std::{collections::HashMap, error::Error, fmt::Debug};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use fontdue::Font;

use crate::epaper::FlushableDrawTarget;

pub mod controls;
mod layouts;
mod positioning;

#[derive(Debug, Clone, Copy)]
pub enum Position {
    Specified(u32, u32),
    FromParent,
}

#[derive(Debug, Clone, Copy)]
pub struct ComputedPosition(pub u32, pub u32);

#[derive(Debug, Clone, Copy)]
pub enum Dimension {
    Auto,
    Pixel(u32),
}

#[derive(Debug, Clone, Copy)]
pub struct Dimensions {
    width: Dimension,
    height: Dimension,
}

impl Dimensions {
    pub fn new(width: Dimension, height: Dimension) -> Self {
        Self { width, height }
    }

    pub fn auto() -> Self {
        Self {
            width: Dimension::Auto,
            height: Dimension::Auto,
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub struct ComputedDimensions {
    width: u32,
    height: u32,
}

#[derive(Debug, Clone)]
pub struct BoundingBox {
    position: ComputedPosition,
    dimensions: ComputedDimensions,
}

impl BoundingBox {
    fn contains(&self, position: ComputedPosition) -> bool {
        position.0 > self.position.0
            && position.0 < self.position.0 + self.dimensions.width
            && position.1 > self.position.1
            && position.1 < self.position.1 + self.dimensions.height
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
            let bounding_box = self.controls[*control_index].render(
                &mut self.draw_target,
                None,
                None,
                &self.fonts,
            );
            self.bounding_boxes.insert(*control_index, bounding_box);
        }

        if !controls_to_redraw.is_empty() {
            self.draw_target.flush();
        }
    }

    pub fn render(&mut self) {
        for (control_index, control) in self.controls.iter_mut().enumerate() {
            let bounding_box = control.render(&mut self.draw_target, None, None, &self.fonts);
            self.bounding_boxes
                .insert(control_index, bounding_box.clone());
        }

        self.draw_target.flush();
    }
}

pub enum Event {
    Touch(ComputedPosition),
}

#[allow(unused)]
pub enum EventResult {
    NoChange,
    MustRedraw,
}

pub trait Control<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimension_override: Option<Dimensions>,
        position_override: Option<ComputedPosition>,
        fonts: &[Font],
    ) -> BoundingBox;
    fn on_touch(&mut self, position: ComputedPosition) -> EventResult;
}
