use std::{error::Error, fmt::Debug};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use fontdue::Font;

use crate::epaper::FlushableDrawTarget;

pub mod controls;
mod layouts;

#[derive(Debug, Clone, Copy)]
pub struct ComputedPosition(pub u32, pub u32);

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
    root_control: Box<dyn Control<TDrawTarget, TError>>,
}

impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + FlushableDrawTarget,
        TError: Error + Debug,
    > Gui<TDrawTarget, TError>
{
    pub fn new(
        fonts: Vec<Font>,
        draw_target: TDrawTarget,
        root_control: Box<dyn Control<TDrawTarget, TError>>,
    ) -> Self {
        Gui {
            fonts,
            draw_target,
            root_control,
        }
    }
    pub fn handle_event(&mut self, event: Event) {
        match event {
            Event::Touch(position) => {
                self.root_control.on_touch(position);
            }
        }

        self.render();
    }

    pub fn render(&mut self) {
        let top_left = self.draw_target.bounding_box().top_left;
        let size = self.draw_target.bounding_box().size;

        self.root_control.render(
            &mut self.draw_target,
            ComputedDimensions {
                width: size.width,
                height: size.height,
            },
            ComputedPosition(top_left.x as u32, top_left.y as u32),
            &self.fonts,
        );

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
    fn compute_dimensions(&mut self, fonts: &[Font]) -> ComputedDimensions;

    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: ComputedDimensions,
        position: ComputedPosition,
        fonts: &[Font],
    ) -> BoundingBox;
    fn on_touch(&mut self, position: ComputedPosition) -> EventResult;
}
