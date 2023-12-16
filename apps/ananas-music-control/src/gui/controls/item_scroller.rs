use std::{error::Error, collections::HashMap};
use std::fmt::Debug;

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::{Position, Dimensions, Control, BoundingBox};

use super::stack_panel::StackPanel;

pub struct ItemScroller<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    position: Position,
    dimensions: Dimensions,
    children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
    show_items: usize
}
impl<
TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
TError: Error + Debug,
> ItemScroller<TDrawTarget, TError> {
    pub(crate) fn new(
        position: Position,
        dimensions: Dimensions,
        children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
        show_items: usize
    ) -> Self {
        Self {
            position,
            dimensions,
            children,
            show_items
        }
    }
}

impl<
TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
TError: Error + Debug,
> Control<TDrawTarget, TError> for ItemScroller<TDrawTarget, TError> {
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimension_override: Option<Dimensions>,
        position_override: Option<crate::gui::ComputedPosition>,
        fonts: &[fontdue::Font],
    ) -> BoundingBox {
        let mut stack_panel = StackPanel::new(
            self.position,
            self.dimensions,
            self.children.drain(0..self.show_items).collect(), // FIXME: take the children back while destroying the parent, once rendering is complete
            super::stack_panel::Direction::Vertical
        );

        stack_panel.render(target, dimension_override, position_override, fonts)
    }

    fn on_touch(&mut self, position: crate::gui::ComputedPosition) -> crate::gui::EventResult {
        todo!()
    }
}