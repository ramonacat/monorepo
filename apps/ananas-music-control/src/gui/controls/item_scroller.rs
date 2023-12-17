use std::error::Error;
use std::fmt::Debug;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::layouts::stack::render_stack;
use crate::gui::positioning::{compute_dimensions_with_override, compute_position_with_override};
use crate::gui::{BoundingBox, ComputedDimensions, Control, Dimension, Dimensions, Position};

use super::button::Button;
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
    buttons_stack_panel: StackPanel<TDrawTarget, TError>,
    buttons_stack_panel_bounding_box: Option<BoundingBox>,
    scroll_index: Arc<AtomicUsize>,
}
impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    > ItemScroller<TDrawTarget, TError>
{
    pub(crate) fn new(
        position: Position,
        dimensions: Dimensions,
        children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
        show_items: usize,
    ) -> Self {
        let scroll_index = Arc::new(AtomicUsize::new(0));
        let children_count = children.len();

        // FIXME: this will break if the scroller is inside a control which overrides positioning
        let copmputed_position = compute_position_with_override(position, None);
        let width = match dimensions.width {
            Dimension::Auto => 200, // FIXME: This should not be hardcoded!
            Dimension::Pixel(px) => px,
        };
        let scroll_index_ = scroll_index.clone();
        let scroll_index__ = scroll_index.clone();
        let buttons_stack_panel: StackPanel<TDrawTarget, TError> = StackPanel::new(
            Position::Specified(copmputed_position.0 + (width - 30), copmputed_position.1),
            Dimensions::new(Dimension::Pixel(30), Dimension::Auto),
            vec![
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new(
                        "⬆".to_string(),
                        20,
                        Position::FromParent,
                        Dimensions::new(Dimension::Pixel(30), Dimension::Pixel(30)),
                    )),
                    Dimensions::auto(),
                    Position::FromParent,
                    Box::new(move || {
                        match scroll_index_
                            .fetch_update(
                                std::sync::atomic::Ordering::SeqCst,
                                std::sync::atomic::Ordering::SeqCst,
                                |x| {
                                    if x == 0 {
                                        None
                                    } else {
                                        Some(x - 1)
                                    }
                                },
                            ) {
                                Ok(_) => crate::gui::EventResult::MustRedraw,
                                Err(_) => crate::gui::EventResult::NoChange
                            }
                    }),
                )),
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new(
                        "⬇".to_string(),
                        20,
                        Position::FromParent,
                        Dimensions::new(Dimension::Pixel(30), Dimension::Pixel(30)),
                    )),
                    Dimensions::auto(),
                    Position::FromParent,
                    Box::new(move || {
                        match scroll_index__
                            .fetch_update(
                                std::sync::atomic::Ordering::SeqCst,
                                std::sync::atomic::Ordering::SeqCst,
                                |x| {
                                    if x >= children_count - 1 {
                                        None
                                    } else {
                                        Some(x + 1)
                                    }
                                },
                            ) {
                                Ok(_) => crate::gui::EventResult::MustRedraw,
                                Err(_) => crate::gui::EventResult::NoChange
                            }
                    }),
                )),
            ],
            super::stack_panel::Direction::Vertical,
        );

        Self {
            position,
            dimensions,
            children,
            show_items,
            buttons_stack_panel,
            buttons_stack_panel_bounding_box: None,
            scroll_index,
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
        dimensions_override: Option<Dimensions>,
        position_override: Option<crate::gui::ComputedPosition>,
        fonts: &[fontdue::Font],
    ) -> BoundingBox {
        let position = compute_position_with_override(self.position, position_override);
        let dimensions = compute_dimensions_with_override(self.dimensions, dimensions_override);
        let width = match dimensions.width {
            Dimension::Auto => 200, // FIXME: This should not be hardcoded!
            Dimension::Pixel(px) => px,
        };

        let height = match dimensions.height {
            Dimension::Auto => 100, // FIXME: This should not be hardcoded
            Dimension::Pixel(px) => px,
        };

        self.buttons_stack_panel_bounding_box =
            Some(self.buttons_stack_panel.render(target, None, None, fonts));

        render_stack(
            target,
            self.children
                .iter_mut()
                .skip(self.scroll_index.load(Ordering::SeqCst))
                .take(self.show_items),
            Dimensions::new(Dimension::Pixel(width - 30), Dimension::Auto),
            position,
            super::stack_panel::Direction::Vertical,
            fonts,
        );

        BoundingBox {
            position,
            dimensions: ComputedDimensions { width, height },
        }
    }

    fn on_touch(&mut self, position: crate::gui::ComputedPosition) -> crate::gui::EventResult {
        if let Some(buttons_bounding_box) = &self.buttons_stack_panel_bounding_box {
            if buttons_bounding_box.contains(position) {
                return self.buttons_stack_panel.on_touch(position);
            }
        }

        return crate::gui::EventResult::NoChange;
    }

    fn compute_dimensions(&mut self, fonts: &[fontdue::Font]) -> ComputedDimensions {
        let width = match self.dimensions.width {
            Dimension::Auto => 200,
            Dimension::Pixel(px) => px,
        };

        let height = match self.dimensions.height {
            Dimension::Auto => 100,
            Dimension::Pixel(px) => px,
        };

        ComputedDimensions { width, height }
    }
}
