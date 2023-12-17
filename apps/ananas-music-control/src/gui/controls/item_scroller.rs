use std::error::Error;
use std::fmt::Debug;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::layouts::stack::render_stack;
use crate::gui::{BoundingBox, ComputedDimensions, ComputedPosition, Control};

use super::button::Button;
use super::stack_panel::StackPanel;
use super::text::Text;

pub struct ItemScroller<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
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
        children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
        show_items: usize,
    ) -> Self {
        let scroll_index = Arc::new(AtomicUsize::new(0));
        let children_count = children.len();

        let scroll_index_ = scroll_index.clone();
        let scroll_index__ = scroll_index.clone();
        let buttons_stack_panel: StackPanel<TDrawTarget, TError> = StackPanel::new(
            vec![
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new("⬆".to_string(), 20)),
                    Box::new(move || {
                        match scroll_index_.fetch_update(
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
                            Err(_) => crate::gui::EventResult::NoChange,
                        }
                    }),
                )),
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new("⬇".to_string(), 20)),
                    Box::new(move || {
                        match scroll_index__.fetch_update(
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
                            Err(_) => crate::gui::EventResult::NoChange,
                        }
                    }),
                )),
            ],
            super::stack_panel::Direction::Vertical,
        );

        Self {
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
        dimensions: ComputedDimensions,
        position: ComputedPosition,
        fonts: &[fontdue::Font],
    ) -> BoundingBox {
        self.buttons_stack_panel_bounding_box = Some(self.buttons_stack_panel.render(
            target,
            ComputedDimensions {
                width: 30,
                height: dimensions.height,
            },
            ComputedPosition(position.0 + (dimensions.width - 30), position.1),
            fonts,
        ));

        render_stack(
            target,
            self.children
                .iter_mut()
                .skip(self.scroll_index.load(Ordering::SeqCst))
                .take(self.show_items),
            ComputedDimensions {
                width: dimensions.width - 30,
                height: dimensions.height,
            },
            position,
            super::stack_panel::Direction::Vertical,
            fonts,
        );

        BoundingBox {
            position,
            dimensions,
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

    fn compute_dimensions(&mut self, _fonts: &[fontdue::Font]) -> ComputedDimensions {
        ComputedDimensions {
            width: 30,
            height: 30,
        }
    }
}
