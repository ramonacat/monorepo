use std::fmt::Debug;
use std::{collections::HashMap, error::Error};

use bitvec::access::BitAccess;
use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::{BoundingBox, Control, Dimension, Dimensions, Position};

use super::button::{self, Button};
use super::stack_panel::StackPanel;
use super::text::Text;

pub struct ItemScroller<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    position: Position,
    dimensions: Dimensions,
    children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
    show_items: usize,
}
impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    ItemScroller<TDrawTarget, TError>
{
    pub(crate) fn new(
        position: Position,
        dimensions: Dimensions,
        children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
        show_items: usize,
    ) -> Self {
        Self {
            position,
            dimensions,
            children,
            show_items,
        }
    }
}

impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    > Control<TDrawTarget, TError> for ItemScroller<TDrawTarget, TError>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimension_override: Option<Dimensions>,
        position_override: Option<crate::gui::ComputedPosition>,
        fonts: &[fontdue::Font],
    ) -> BoundingBox {
        let items_stack_panel = StackPanel::new(
            Position::FromParent,
            // TODO: This can be replaced with width: Dimension::Stretch, once it exists
            Dimensions::new(
                match self.dimensions.width {
                    Dimension::Auto => Dimension::Auto,
                    Dimension::Pixel(px) => Dimension::Pixel(px - 30),
                },
                self.dimensions.height,
            ),
            self.children.drain(0..self.show_items).collect(), // FIXME: take the children back while destroying the parent, once rendering is complete
            super::stack_panel::Direction::Vertical,
        );

        let buttons_stack_panel = StackPanel::new(
            Position::FromParent,
            Dimensions::new(Dimension::Pixel(30), Dimension::Auto),
            vec![
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new(
                        "UP".to_string(),
                        20,
                        Position::FromParent,
                        Dimensions::new(Dimension::Pixel(30), Dimension::Pixel(30)),
                    )),
                    Dimensions::auto(),
                    Position::FromParent,
                )),
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new(
                        "DN".to_string(),
                        20,
                        Position::FromParent,
                        Dimensions::new(Dimension::Pixel(30), Dimension::Pixel(30)),
                    )),
                    Dimensions::auto(),
                    Position::FromParent,
                )),
            ],
            super::stack_panel::Direction::Vertical,
        );

        let mut combined_stack_panel = StackPanel::new(
            self.position,
            self.dimensions,
            vec![Box::new(items_stack_panel), Box::new(buttons_stack_panel)],
            super::stack_panel::Direction::Horizontal,
        );

        combined_stack_panel.render(target, dimension_override, position_override, fonts)
    }

    fn on_touch(&mut self, position: crate::gui::ComputedPosition) -> crate::gui::EventResult {
        todo!()
    }
}
