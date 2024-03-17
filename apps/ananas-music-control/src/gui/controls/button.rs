use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::Size,
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyle, PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};
use std::sync::mpsc::Sender;

use crate::gui::{fonts::Fonts, Control, Dimensions, Event, GuiCommand, GuiError, Padding, Point};

type Callback<TDrawTarget> = Box<dyn FnMut(Sender<GuiCommand<TDrawTarget>>)>;

pub struct Button<TDrawTarget: DrawTarget<Color = BinaryColor, Error = GuiError>> {
    content: Box<dyn Control<TDrawTarget>>,
    action: Callback<TDrawTarget>,
    command_channel: Option<Sender<GuiCommand<TDrawTarget>>>,
    padding: Padding,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = GuiError>> Button<TDrawTarget> {
    pub fn new(
        content: Box<dyn Control<TDrawTarget>>,
        padding: Padding,
        action: Callback<TDrawTarget>,
    ) -> Self {
        Self {
            content,
            action,
            padding,
            command_channel: None,
        }
    }
}

const BUTTON_STYLE: PrimitiveStyle<BinaryColor> = PrimitiveStyleBuilder::new()
    .stroke_alignment(embedded_graphics::primitives::StrokeAlignment::Inside)
    .stroke_width(1)
    .stroke_color(BinaryColor::On)
    .fill_color(BinaryColor::Off)
    .build();

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = GuiError>> Control<TDrawTarget>
    for Button<TDrawTarget>
{
    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: Dimensions,
        position: Point,
        fonts: &Fonts,
    ) {
        let rectangle = Rectangle::new(
            embedded_graphics::geometry::Point {
                x: position.0 as i32,
                y: position.1 as i32,
            },
            Size {
                width: dimensions.width(),
                height: dimensions.height(),
            },
        );
        rectangle.draw_styled(&BUTTON_STYLE, target).unwrap();

        let dimensions = self.padding.adjust_dimensions(dimensions);
        let position = self.padding.adjust_position(position);

        self.content.render(
            target,
            Dimensions::new(dimensions.width() - 2, dimensions.height() - 2),
            Point(position.0 + 1, position.1 + 1),
            fonts,
        );
    }

    fn on_event(&mut self, event: Event) {
        match event {
            Event::Touch(_) => {
                if let Some(command_channel) = self.command_channel.as_ref() {
                    (self.action)(command_channel.clone());
                }
            }
            Event::Heartbeat => {
                self.content.on_event(event);
            }
        };
    }

    fn compute_natural_dimensions(&mut self, fonts: &Fonts) -> crate::gui::Dimensions {
        let child_dimensions = self.content.compute_natural_dimensions(fonts);

        Dimensions::new(
            child_dimensions.width() + 2 + self.padding.total_horizontal(),
            child_dimensions.height() + 2 + self.padding.total_vertical(),
        )
    }

    fn register_command_channel(
        &mut self,
        tx: std::sync::mpsc::Sender<crate::gui::GuiCommand<TDrawTarget>>,
    ) {
        self.command_channel = Some(tx.clone());
        self.content.register_command_channel(tx);
    }
}
