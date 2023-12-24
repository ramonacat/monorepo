use std::cmp::max;
use std::fmt::Debug;
use std::sync::mpsc::Sender;
use std::{collections::HashMap, error::Error};

use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::fonts::Fonts;
use crate::gui::geometry::Rectangle;
use crate::gui::layouts::stack::render_stack;
use crate::gui::{Control, GuiCommand, Orientation, StackUnitDimension};
use crate::gui::{Dimensions, Point};

pub struct StackPanel<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
    bounding_boxes: HashMap<usize, Rectangle>,
    direction: Orientation,
    command_channel: Option<Sender<GuiCommand<TDrawTarget, TError>>>,
    unit_dimensions: Vec<StackUnitDimension>,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    StackPanel<TDrawTarget, TError>
{
    pub fn new(
        children: Vec<Box<dyn Control<TDrawTarget, TError>>>,
        direction: Orientation,
        unit_dimensions: Vec<StackUnitDimension>,
    ) -> Self {
        Self {
            children,
            bounding_boxes: HashMap::new(),
            direction,
            command_channel: None,
            unit_dimensions,
        }
    }
}

impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    > Control<TDrawTarget, TError> for StackPanel<TDrawTarget, TError>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: Dimensions,
        position: Point,
        fonts: &Fonts,
    ) {
        let render_result = render_stack(
            target,
            self.children.iter_mut(),
            dimensions,
            position,
            self.direction,
            &self.unit_dimensions,
            fonts,
        );

        for (child_index, child_bounding_box) in render_result {
            self.bounding_boxes.insert(child_index, child_bounding_box);
        }
    }

    fn on_event(&mut self, event: crate::gui::Event) {
        match event {
            crate::gui::Event::Touch(position) => {
                for (i, bounding_box) in self.bounding_boxes.iter() {
                    if bounding_box.contains(position) {
                        self.children.get_mut(*i).unwrap().on_event(event);
                    }
                }
            }
            crate::gui::Event::Heartbeat => {
                for c in self.children.iter_mut() {
                    c.on_event(event);
                }
            }
        }
    }

    fn compute_natural_dimensions(&mut self, fonts: &Fonts) -> crate::gui::Dimensions {
        let mut width = 0;
        let mut height = 0;
        for child in self.children.iter_mut() {
            let child_dimensions = child.compute_natural_dimensions(fonts);

            width = max(width, child_dimensions.width());
            height += child_dimensions.height();
        }

        Dimensions::new(width, height)
    }

    fn register_command_channel(
        &mut self,
        tx: std::sync::mpsc::Sender<crate::gui::GuiCommand<TDrawTarget, TError>>,
    ) {
        self.command_channel = Some(tx.clone());

        for child in self.children.iter_mut() {
            child.register_command_channel(tx.clone());
        }
    }
}
