use std::error::Error;
use std::fmt::Debug;
use std::sync::mpsc::{channel, Receiver, Sender};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::layouts::stack::render_stack;
use crate::gui::{BoundingBox, ComputedDimensions, ComputedPosition, Control, GuiCommand};

use super::button::Button;
use super::stack_panel::StackPanel;
use super::text::Text;

enum ScrollRequest {
    Up,
    Down,
}

pub struct ItemScroller<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
    show_items: usize,
    buttons_stack_panel: StackPanel<TDrawTarget, TError>,
    buttons_stack_panel_bounding_box: Option<BoundingBox>,
    scroll_index: usize,
    scroll_rx: Receiver<ScrollRequest>,
    command_channel: Option<Sender<GuiCommand>>,
    bounding_box: Option<BoundingBox>,
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
        let (scroll_tx, scroll_rx) = channel();

        let scroll_tx_ = scroll_tx.clone();

        let buttons_stack_panel: StackPanel<TDrawTarget, TError> = StackPanel::new(
            vec![
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new("⬆".to_string(), 20)),
                    Box::new(move || {
                        scroll_tx.send(ScrollRequest::Up).unwrap();
                    }),
                )),
                Box::new(Button::<TDrawTarget, TError>::new(
                    Box::new(Text::new("⬇".to_string(), 20)),
                    Box::new(move || {
                        scroll_tx_.send(ScrollRequest::Down).unwrap();
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
            scroll_index: 0,
            command_channel: None,
            scroll_rx,
            bounding_box: None,
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
                .skip(self.scroll_index)
                .take(self.show_items),
            ComputedDimensions {
                width: dimensions.width - 30,
                height: dimensions.height,
            },
            position,
            super::stack_panel::Direction::Vertical,
            fonts,
        );

        let bounding_box = BoundingBox {
            position,
            dimensions,
        };

        self.bounding_box = Some(bounding_box.clone());

        bounding_box
    }

    fn on_touch(&mut self, position: crate::gui::ComputedPosition) {
        if let Some(buttons_bounding_box) = &self.buttons_stack_panel_bounding_box {
            if buttons_bounding_box.contains(position) {
                self.buttons_stack_panel.on_touch(position);
            }
        }

        let mut needs_contents_redraw = false;

        if let Some(bounding_box) = &self.bounding_box {
            while let Ok(request) = self.scroll_rx.try_recv() {
                match request {
                    ScrollRequest::Up => {
                        if self.scroll_index > 0 {
                            self.scroll_index -= 1;
                            needs_contents_redraw = true;
                        }
                    }
                    ScrollRequest::Down => {
                        if self.scroll_index < self.children.len() {
                            self.scroll_index += 1;
                            needs_contents_redraw = true;
                        }
                    }
                }
            }

            if needs_contents_redraw {
                if let Some(tx) = &self.command_channel {
                    tx.send(GuiCommand::Redraw(
                        bounding_box.position,
                        bounding_box.dimensions,
                    ))
                    .unwrap();
                }
            }
        }
    }

    fn compute_dimensions(&mut self, _fonts: &[fontdue::Font]) -> ComputedDimensions {
        ComputedDimensions {
            width: 30,
            height: 30,
        }
    }

    fn register_command_channel(&mut self, tx: std::sync::mpsc::Sender<crate::gui::GuiCommand>) {
        self.command_channel = Some(tx.clone());
        self.buttons_stack_panel
            .register_command_channel(tx.clone());
        for child in self.children.iter_mut() {
            child.register_command_channel(tx.clone());
        }
    }
}
