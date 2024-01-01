use std::{convert::Infallible, thread::sleep, time::Duration};

use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{OriginDimensions, Point, Size},
    pixelcolor::BinaryColor,
    Pixel,
};
use rppal::{
    gpio::{InputPin, Level, OutputPin},
    spi::Spi,
};

use crate::gui::geometry::{Rectangle, Dimensions};

const EPAPER_WIDTH: u32 = 122;
const EPAPER_HEIGHT: u32 = 250;

const LUT_PARTIAL:[u8; 159] = [
        0x0,0x40,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x80,0x80,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x40,0x40,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x80,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x10,0x0,0x0,0x0,0x0,0x0,0x0,  
        0x1,0x0,0x0,0x0,0x0,0x0,0x0,
        0x1,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x22,0x22,0x22,0x22,0x22,0x22,0x0,0x0,0x0,
        0x22,0x17,0x41,0x00,0x32,0x36,
];


const LUT_FULL:[u8; 159] = [
            0x80,0x4A,0x40,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x40,0x4A,0x80,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x80,0x4A,0x40,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x40,0x4A,0x80,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0xF,0x0,0x0,0x0,0x0,0x0,0x0,
        0xF,0x0,0x0,0xF,0x0,0x0,0x2,
        0xF,0x0,0x0,0x0,0x0,0x0,0x0,
        0x1,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x22,0x22,0x22,0x22,0x22,0x22,0x0,0x0,0x0,
        0x22,0x17,0x41,0x0,0x32,0x36,
];

pub struct EPaper {
    reset_pin: OutputPin,
    data_command_pin: OutputPin,
    chip_select_pin: OutputPin,
    busy_pin: InputPin,
    spi: Spi,
}

impl EPaper {
    pub fn new(
        reset_pin: OutputPin,
        data_command_pin: OutputPin,
        chip_select_pin: OutputPin,
        busy_pin: InputPin,
        spi: Spi,
    ) -> Self {
        Self {
            reset_pin,
            data_command_pin,
            chip_select_pin,
            busy_pin,
            spi,
        }
    }

    fn hardware_reset(&mut self) {
        self.reset_pin.set_high();
        std::thread::sleep(Duration::from_millis(20));
        self.reset_pin.set_low();
        sleep(Duration::from_millis(2));
        self.reset_pin.set_high();
        std::thread::sleep(Duration::from_millis(20));
    }

    fn send_command(&mut self, data: &[u8]) {
        self.data_command_pin.set_low();
        self.chip_select_pin.set_low();
        for b in data {
            self.spi.write(&[*b]).unwrap();
        }
        self.chip_select_pin.set_high();
    }

    fn send_data(&mut self, data: &[u8]) {
        self.data_command_pin.set_high();
        self.chip_select_pin.set_low();
        for b in data {
            self.spi.write(&[*b]).unwrap();
        }
        self.chip_select_pin.set_high();
    }

    fn wait_while_busy(&mut self) {
        while self.busy_pin.read() == Level::High {
            sleep(Duration::from_millis(10));
        }
    }

    fn turn_on_for_full_update(&mut self) {
        self.send_command(&[0x22]);
        self.send_data(&[0xc7]);
        self.send_command(&[0x20]);
    }

    fn turn_on_for_partial_update(&mut self) {
        self.send_command(&[0x22]);
        self.send_data(&[0x0c]);
        self.send_command(&[0x20]);
    }

    fn set_display_window(
        &mut self,
        (x_start, y_start): (u32, u32),
        (x_end, y_end): (u32, u32),
    ) {
        self.send_command(&[0x44]); // SET_RAM_X_ADDRESS_START_END_POSITION
        self.send_data(&[(x_start >> 3 & 0xFF) as u8]);
        self.send_data(&[(x_end >> 3 & 0xFF) as u8]);

        self.send_command(&[0x45]);

        self.send_data(&[(y_start & 0xFF) as u8]);
        self.send_data(&[(y_start >> 8 & 0xFF) as u8]);

        self.send_data(&[(y_end & 0xFF) as u8]);
        self.send_data(&[(y_end >> 8 & 0xFF) as u8]);
    }

    fn set_cursor(&mut self, (x, y): (u32, u32)) {
        self.send_command(&[0x4E]); // SET_RAM_X_ADDRESS_COUNTER
        self.send_data(&[(x & 0xFF) as u8]);

        self.send_command(&[0x4F]);
        self.send_data(&[(y & 0xFF) as u8]);
        self.send_data(&[(y >> 8 & 0xFF) as u8]);
    }

    fn initialize_for_full_update(&mut self) {
        self.hardware_reset();

        self.wait_while_busy();
        self.send_command(&[0x12]); // SWRESET
        self.wait_while_busy();

        self.send_command(&[0x01]); // Driver output control
        self.send_data(&[0xf9]);
        self.send_data(&[0x00]);
        self.send_data(&[0x00]);

        self.send_command(&[0x11]); // Data entry mode
        self.send_data(&[0x03]);

        self.set_display_window((0, 0), (EPAPER_WIDTH - 1, EPAPER_HEIGHT - 1));
        self.set_cursor((0, 0));

        self.send_command(&[0x3c]); // Border waveform
        self.send_data(&[0x05]);

        self.send_command(&[0x21]); // display update control
        self.send_data(&[0x00]);
        self.send_data(&[0x80]);

        self.send_command(&[0x18]); // display update control
        self.send_data(&[0x80]);

        self.set_lut(&LUT_FULL);
    }

    fn initialize_for_partial_update(&mut self, location: Rectangle) {
        self.reset_pin.set_low();
        sleep(Duration::from_millis(1));
        self.reset_pin.set_high();

        self.set_lut(&LUT_PARTIAL);

        self.send_command(&[0x37]);
        self.send_data(&[0x00]);
        self.send_data(&[0x00]);
        self.send_data(&[0x00]);
        self.send_data(&[0x00]);
        self.send_data(&[0x00]);
        self.send_data(&[0x40]);
        self.send_data(&[0x00]);
        self.send_data(&[0x00]);
        self.send_data(&[0x00]);  
        self.send_data(&[0x00]);

        self.send_command(&[0x3c]); // Border waveform
        self.send_data(&[0x80]);

        self.send_command(&[0x22]);
        self.send_data(&[0xc0]);
        self.send_command(&[0x20]);

        self.wait_while_busy();
    }

    fn set_lut(&mut self, lut: &[u8]) {
        self.send_command(&[0x32]);
        self.send_data(&lut[0..153]);

        self.send_command(&[0x3f]);
        self.send_data(&[lut[153]]);

        self.send_command(&[0x03]);
        self.send_data(&[lut[154]]);

        self.send_command(&[0x04]);
        self.send_data(&[lut[155]]);
        self.send_data(&[lut[156]]);
        self.send_data(&[lut[157]]);

        self.send_command(&[0x2c]);
        self.send_data(&[lut[158]]);
    }

    fn turn_off(&mut self) {
        self.send_command(&[0x10]); // enter deep sleep
        self.send_data(&[0x01]);

        sleep(Duration::from_millis(2000));

        self.reset_pin.set_low();
        self.data_command_pin.set_low();
        self.chip_select_pin.set_low();
    }

    // FIXME validate dimensions
    // FIXME the partial/full update decision should be made internally here, in the driver
    pub fn write_image(&mut self, image: &[u8], location: Rectangle) {
        // TODO This whole condition is borked, get rid of it and check how many pixels were changed
        // since last update, how many updates were done and how much time has passsed
        let is_full_update = location.dimensions().width() == EPAPER_WIDTH
            && location.dimensions().height() == EPAPER_HEIGHT
            && location.position().0 == 0
            && location.position().1 == 0;

        println!("full update? {:?}", is_full_update);
        if is_full_update {
            self.initialize_for_full_update();
        } 

        self.send_command(&[0x24]);
        self.send_data(image);

        if is_full_update {
            self.send_command(&[0x26]);
            self.send_data(image);
        }

        if is_full_update {
            self.turn_on_for_full_update();
        } else {
            self.turn_on_for_partial_update();
        }
        self.wait_while_busy();

        if is_full_update {
            self.initialize_for_partial_update(location);
        }
        // self.turn_off();
    }
}

pub trait FlushableDrawTarget {
    fn flush(&mut self, location: Rectangle);
}

pub struct BufferedDrawTarget {
    epaper: EPaper,
    buffer: Vec<u8>,
    row_width_bytes: u32,
}

impl BufferedDrawTarget {
    pub fn new(epaper: EPaper) -> Self {
        let row_width_bytes = EPAPER_WIDTH / 8 + if EPAPER_WIDTH % 8 == 0 { 0 } else { 1 };

        Self {
            epaper,
            buffer: vec![0xFF; (row_width_bytes * EPAPER_HEIGHT) as usize],
            row_width_bytes,
        }
    }
}

impl FlushableDrawTarget for BufferedDrawTarget {
    fn flush(&mut self, location: Rectangle) {
        self.epaper.write_image(&self.buffer, location);
    }
}

impl DrawTarget for BufferedDrawTarget {
    type Color = BinaryColor;

    // fixme: make this a real error type, instead of panicking
    type Error = Infallible;

    fn draw_iter<I>(&mut self, pixels: I) -> Result<(), Self::Error>
    where
        I: IntoIterator<Item = embedded_graphics::prelude::Pixel<Self::Color>>,
    {
        let row_width_bytes = EPAPER_WIDTH / 8 + if EPAPER_WIDTH % 8 == 0 { 0 } else { 1 };

        for pixel in pixels.into_iter() {
            let pixel_x_byte_index = pixel.0.x / 8;
            let pixel_x_bit_index = 7 - (pixel.0.x % 8);

            let pixel_index = (pixel_x_byte_index + pixel.0.y * row_width_bytes as i32) as usize;
            if pixel_index >= self.buffer.len() {
                // The documentation for embedded_graphics requires us to ignore requests to draw pixels outside of the screen
                continue;
            }

            if pixel.1 == BinaryColor::Off {
                self.buffer[pixel_index] |= 1 << pixel_x_bit_index;
            } else {
                self.buffer[pixel_index] &= !(1 << pixel_x_bit_index);
            }
        }

        Ok(())
    }
}

impl OriginDimensions for BufferedDrawTarget {
    fn size(&self) -> embedded_graphics::prelude::Size {
        Size::new(EPAPER_WIDTH as u32, EPAPER_HEIGHT as u32)
    }
}

pub struct RotatedDrawTarget<T: DrawTarget + OriginDimensions + FlushableDrawTarget> {
    inner: T,
}

impl<T: DrawTarget + OriginDimensions + FlushableDrawTarget> RotatedDrawTarget<T> {
    pub fn new(inner: T) -> Self {
        Self { inner }
    }
}

impl<T: DrawTarget + OriginDimensions + FlushableDrawTarget> DrawTarget for RotatedDrawTarget<T> {
    type Color = T::Color;

    type Error = T::Error;

    fn draw_iter<I>(&mut self, pixels: I) -> Result<(), Self::Error>
    where
        I: IntoIterator<Item = embedded_graphics::prelude::Pixel<Self::Color>>,
    {
        let inner_size = self.inner.size();

        self.inner.draw_iter(pixels.into_iter().map(|x| {
            Pixel(
                Point {
                    x: (inner_size.width - x.0.y as u32) as i32,
                    y: x.0.x,
                },
                x.1,
            )
        }))
    }
}

impl<T: DrawTarget + OriginDimensions + FlushableDrawTarget> OriginDimensions
    for RotatedDrawTarget<T>
{
    fn size(&self) -> Size {
        let original_size = self.inner.size();

        Size {
            width: original_size.height,
            height: original_size.width,
        }
    }
}

impl<T: DrawTarget + OriginDimensions + FlushableDrawTarget> FlushableDrawTarget
    for RotatedDrawTarget<T>
{
    fn flush(&mut self, location: Rectangle) {
        let flipped_location = Rectangle::new(
            crate::gui::geometry::Point(
            location.position().1,
            location.position().0),
            Dimensions::new(location.dimensions().height(), location.dimensions().width())
        );
        self.inner.flush(flipped_location)
    }
}
