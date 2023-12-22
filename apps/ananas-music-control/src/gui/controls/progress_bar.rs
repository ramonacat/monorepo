use std::{error::Error, fmt::Debug, sync::mpsc::Sender};

use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{Point, Size},
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};

use crate::gui::{fonts::Fonts, geometry::Dimensions, Control, GuiCommand, Padding};

pub struct ProgressBar<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>,
    TError: Error + Debug,
> {
    command_channel: Option<Sender<GuiCommand<TDrawTarget, TError>>>,
    padding: Padding,
    progress: u32,
    progress_max: u32,
    height: u32,
}

impl<TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError>, TError: Error + Debug>
    ProgressBar<TDrawTarget, TError>
{
    pub fn new(progress: u32, progress_max: u32, height: u32, padding: Padding) -> Self {
        Self {
            progress,
            progress_max,
            padding,
            command_channel: None,
            height,
        }
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

        let height = dimensions.height();
        let width = dimensions.width();

        let progress_width =
            (width as f32 * (self.progress as f32 / self.progress_max as f32)) as u32;

        let rectangle_progress = Rectangle::new(
            Point::new(position.0 as i32, position.1 as i32),
            Size::new(progress_width, height),
        );
        let rectangle_clear = Rectangle::new(
            Point::new((position.0 + progress_width) as i32, position.1 as i32),
            Size::new(width - progress_width, height),
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

    fn on_touch(&mut self, _position: crate::gui::geometry::Point) {
        // progress bar is not interactive
    }
}
