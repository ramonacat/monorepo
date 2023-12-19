use std::{error::Error, fmt::Debug, sync::mpsc::Sender};

use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{Point, Size},
    pixelcolor::BinaryColor,
    primitives::{PrimitiveStyleBuilder, Rectangle, StyledDrawable},
};

use crate::gui::{geometry::Dimensions, Control, GuiCommand, Padding};

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

    fn compute_dimensions(&mut self, _fonts: &[fontdue::Font]) -> crate::gui::geometry::Dimensions {
        // FIXME: support padding here
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
        _fonts: &[fontdue::Font],
    ) {
        // FIXME: support padding here

        let height = dimensions.height() - self.padding.total_vertical();
        let width = dimensions.width() - self.padding.total_horizontal();

        let progress_width =
            (width as f32 * (self.progress as f32 / self.progress_max as f32)) as u32;
        let position_y = position.1 + self.padding.top;
        let position_x = position.0 + self.padding.left;

        let rectangle_progress = Rectangle::new(
            Point::new(position_x as i32, position_y as i32),
            Size::new(progress_width, height),
        );
        let rectangle_clear = Rectangle::new(
            Point::new((position_x + progress_width) as i32, position_y as i32),
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
