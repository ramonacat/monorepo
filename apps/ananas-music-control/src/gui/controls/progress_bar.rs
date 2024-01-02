use std::{
    error::Error,
    fmt::Debug,
    sync::{mpsc::Sender, Arc},
};

use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{Point, Size},
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};

use crate::gui::{
    fonts::Fonts,
    geometry::Dimensions,
    reactivity::property::{ReactiveProperty, ReactivePropertyReceiver},
    Control, Event, GuiCommand, Padding,
};

pub struct ProgressBar<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    command_channel: Option<Sender<GuiCommand<TDrawTarget, TError>>>,
    padding: Padding,
    progress: u32,
    progress_max: u32,
    height: u32,

    dimensions: Option<Dimensions>,
    position: Option<crate::gui::geometry::Point>,

    progress_property: Arc<ReactiveProperty<u32>>,
    progress_max_property: Arc<ReactiveProperty<u32>>,

    progress_property_receiver: ReactivePropertyReceiver<u32>,
    progress_max_property_receiver: ReactivePropertyReceiver<u32>,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    ProgressBar<TDrawTarget, TError>
{
    pub fn new(progress: u32, progress_max: u32, height: u32, padding: Padding) -> Self {
        let (progress_property, progress_property_receiver) = ReactiveProperty::new();
        let (progress_max_property, progress_max_property_receiver) = ReactiveProperty::new();
        Self {
            progress,
            progress_max,
            padding,
            command_channel: None,
            height,
            dimensions: None,
            position: None,
            progress_property_receiver,
            progress_max_property_receiver,
            progress_property: Arc::new(progress_property),
            progress_max_property: Arc::new(progress_max_property),
        }
    }

    pub fn progress(&self) -> Arc<ReactiveProperty<u32>> {
        self.progress_property.clone()
    }

    pub fn progress_max(&self) -> Arc<ReactiveProperty<u32>> {
        self.progress_max_property.clone()
    }
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    Control<TDrawTarget, TError> for ProgressBar<TDrawTarget, TError>
{
    fn register_command_channel(&mut self, tx: Sender<GuiCommand<TDrawTarget, TError>>) {
        self.command_channel = Some(tx);
    }

    fn compute_natural_dimensions(&mut self, _fonts: &Fonts) -> crate::gui::geometry::Dimensions {
        Dimensions::new(
            50 + self.padding.total_horizontal(),
            self.height + self.padding.total_vertical(),
        )
    }

    fn render(
        &mut self,
        target: &mut TDrawTarget,
        dimensions: crate::gui::geometry::Dimensions,
        position: crate::gui::geometry::Point,
        _fonts: &Fonts,
    ) {
        let dimensions = self.padding.adjust_dimensions(dimensions);
        let position = self.padding.adjust_position(position);

        self.dimensions = Some(dimensions);
        self.position = Some(position);

        let progress_width =
            (dimensions.width() as f32 * (self.progress as f32 / self.progress_max as f32)) as u32;

        let rectangle_progress = Rectangle::new(
            Point::new(position.0 as i32, position.1 as i32),
            Size::new(progress_width, dimensions.height()),
        );
        let rectangle_clear = Rectangle::new(
            Point::new((position.0 + progress_width) as i32, position.1 as i32),
            Size::new(dimensions.width() - progress_width, dimensions.height()),
        );

        rectangle_progress
            .draw_styled(
                &PrimitiveStyleBuilder::new()
                    .fill_color(BinaryColor::On)
                    .build(),
                target,
            )
            .unwrap();
        rectangle_clear
            .draw_styled(
                &PrimitiveStyleBuilder::new()
                    .fill_color(BinaryColor::Off)
                    .build(),
                target,
            )
            .unwrap();
    }

    fn on_event(&mut self, event: Event) {
        match event {
            Event::Touch(_) => {}
            Event::Heartbeat => {
                let mut redraw = false;

                if let Some(progress) = self.progress_property_receiver.latest_value() {
                    if progress != self.progress {
                        self.progress = progress;
                        redraw = true;
                    }
                }

                if let Some(progress_max) = self.progress_max_property_receiver.latest_value() {
                    if self.progress_max != progress_max {
                        self.progress_max = progress_max;
                        redraw = true;
                    }
                }

                if let (true, Some(tx)) = (redraw, &self.command_channel) {
                    tx.send(GuiCommand::Redraw).unwrap();
                }
            }
        }
    }
}
