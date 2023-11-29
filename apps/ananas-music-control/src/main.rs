use std::{
    convert::Infallible,
    thread::sleep,
    time::Duration,
};

use bitvec::{bitvec, order::Msb0, vec::BitVec};
use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{OriginDimensions, Point, Size},
    image::{Image, ImageRaw, ImageRawLE},
    pixelcolor::BinaryColor,
    Drawable, Pixel, iterator::pixel,
};
use fontdue::{
    layout::{Layout, TextStyle},
    Font, FontSettings,
};
use rppal::{
    gpio::{InputPin, Level, OutputPin},
    i2c::I2c,
    spi::{Mode, Spi},
};

const EPAPER_RESET_PIN: u8 = 17;
const EPAPER_DC_PIN: u8 = 25;
const EPAPER_CS_PIN: u8 = 8;
const EPAPER_BUSY_PIN: u8 = 24;

const EPAPER_WIDTH: usize = 122;
const EPAPER_HEIGHT: usize = 250;

const TOUCHSCREEN_TRST_PIN: u8 = 22;
const TOUCHSCREEN_INT_PIN: u8 = 27;

struct EPaper {
    reset_pin: OutputPin,
    data_command_pin: OutputPin,
    chip_select_pin: OutputPin,
    busy_pin: InputPin,
    spi: Spi,
}

impl EPaper {
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
        self.send_data(&[0xF7]);
        self.send_command(&[0x20]);
    }

    fn turn_on_for_partial_update(&mut self) {
        self.send_command(&[0x22]);
        self.send_data(&[0xFF]);
        self.send_command(&[0x20]);
    }

    fn set_display_window(
        &mut self,
        (x_start, y_start): (usize, usize),
        (x_end, y_end): (usize, usize),
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

    fn set_cursor(&mut self, (x, y): (usize, usize)) {
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

        self.send_command(&[0x3c]);
        self.send_data(&[0x05]);

        self.send_command(&[0x21]); // display update control
        self.send_data(&[0x00]);
        self.send_data(&[0x80]);

        self.send_command(&[0x18]); // display update control
        self.send_data(&[0x80]);
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
    pub fn write_image(&mut self, image: &[u8]) {
        self.initialize_for_full_update();

        self.send_command(&[0x24]);
        self.send_data(image);

        self.turn_on_for_full_update();
        self.wait_while_busy();
        self.turn_off();
    }
}

trait FlushableDrawTarget {
    fn flush(&mut self);
}

struct BufferedDrawTarget {
    epaper: EPaper,
    buffer: Vec<u8>,
}

impl BufferedDrawTarget {
    fn new(epaper: EPaper) -> Self {
        let row_width_bytes = EPAPER_WIDTH / 8 + if EPAPER_WIDTH % 8 == 0 { 0 } else { 1 };

        Self {
            epaper,
            buffer: vec![0xFF; row_width_bytes * EPAPER_HEIGHT],
        }
    }
}

impl FlushableDrawTarget for BufferedDrawTarget {
    fn flush(&mut self) {
        self.epaper.write_image(&self.buffer);
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

            if pixel.1 == BinaryColor::Off {
                self.buffer[(pixel_x_byte_index + pixel.0.y * row_width_bytes as i32) as usize] |=
                    1 << pixel_x_bit_index;
            } else {
                self.buffer[(pixel_x_byte_index + pixel.0.y * row_width_bytes as i32) as usize] &=
                    !(1 << pixel_x_bit_index);
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

struct TouchPanel {
    reset_pin: OutputPin,
    interrupt_pin: InputPin,
    i2c: I2c,
}

#[derive(Debug)]
struct Touch {
    x: usize,
    y: usize,
    strength: usize,
    track_id: u8,
}

impl TouchPanel {
    fn reset(&mut self) {
        self.reset_pin.set_high();
        sleep(Duration::from_millis(100));
        self.reset_pin.set_low();
        sleep(Duration::from_millis(100));
        self.reset_pin.set_high();
        sleep(Duration::from_millis(1000));
    }

    fn read_version(&mut self) -> u32 {
        let mut buffer = [0u8; 4];
        self.i2c.smbus_write_byte(0x81, 0x40).unwrap();
        self.i2c.read(&mut buffer).unwrap();

        u32::from_le_bytes(buffer)
    }

    fn wait_for_touch(&mut self) -> Vec<Touch> {
        while !self.interrupt_pin.is_high() {
            // FIXME use like interrupts or something instead of spinning
        }

        self.i2c.smbus_write_byte(0x81, 0x4E).unwrap();
        let mut buffer = [0u8; 1];
        self.i2c.read(&mut buffer).unwrap();

        if buffer[0] & 0x80 == 0 {
            // TODO WTF does this do?
            self.i2c.smbus_write_word(0x81, 0x004E).unwrap();
            sleep(Duration::from_millis(10));

            vec![]
        } else {
            let touchpoint_flag = buffer[0] & 0x80;
            let touch_count = buffer[0] & 0x0f;

            if touch_count > 5 || touch_count < 1 {
                self.i2c.smbus_write_word(0x81, 0x004E).unwrap();
                return vec![];
            }

            let mut buffer_touches = vec![0u8; touch_count as usize * 8];
            self.i2c.smbus_write_byte(0x81, 0x4F).unwrap();
            self.i2c.read(&mut buffer_touches).unwrap();
            self.i2c.smbus_write_word(0x81, 0x004E).unwrap();

            println!("Touchpoint: {}, count: {}", touchpoint_flag, touch_count);
            println!("Raw touch data: {:?}", buffer_touches);

            let mut touches = vec![];

            for i in 0..touch_count as usize {
                touches.push(Touch {
                    x: ((buffer_touches[2 + 8 * i] as usize) << 8)
                        + buffer_touches[1 + 8 * i] as usize,
                    y: ((buffer_touches[4 + 8 * i] as usize) << 8)
                        + buffer_touches[3 + 8 * i] as usize,
                    strength: ((buffer_touches[6 + 8 * i] as usize) << 8)
                        + buffer_touches[5 + 8 * i] as usize,
                    track_id: (buffer_touches[8 * i]),
                });
            }

            touches
        }
    }
}

struct RotatedDrawTarget<T: DrawTarget> {
    inner: T,
}

impl<T: DrawTarget + OriginDimensions> DrawTarget for RotatedDrawTarget<T> {
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
                    y: x.0.x as i32,
                },
                x.1,
            )
        }))
    }
}

impl<T: DrawTarget + OriginDimensions> OriginDimensions for RotatedDrawTarget<T> {
    fn size(&self) -> Size {
        let original_size = self.inner.size();

        Size {
            width: original_size.height,
            height: original_size.width,
        }
    }
}

impl<T: DrawTarget + FlushableDrawTarget> FlushableDrawTarget for RotatedDrawTarget<T> {
    fn flush(&mut self) {
        self.inner.flush()
    }
}

fn main() {
    let spi = rppal::spi::Spi::new(
        rppal::spi::Bus::Spi0,
        rppal::spi::SlaveSelect::Ss0,
        10000000,
        Mode::Mode0,
    )
    .unwrap();

    let gpio = rppal::gpio::Gpio::new().unwrap();

    let epaper_reset_pin = gpio.get(EPAPER_RESET_PIN).unwrap().into_output();
    let epaper_dc_pin = gpio.get(EPAPER_DC_PIN).unwrap().into_output();
    let epaper_cs_pin = gpio.get(EPAPER_CS_PIN).unwrap().into_output();
    let epaper_busy_pin = gpio.get(EPAPER_BUSY_PIN).unwrap().into_input();

    let touchscreen_reset_pin = gpio.get(TOUCHSCREEN_TRST_PIN).unwrap().into_output();
    let touchscreen_int_pin = gpio.get(TOUCHSCREEN_INT_PIN).unwrap().into_input();
    let mut i2c = I2c::with_bus(3).unwrap();
    i2c.set_slave_address(0x14).unwrap();

    let mut touchpanel = TouchPanel {
        reset_pin: touchscreen_reset_pin,
        interrupt_pin: touchscreen_int_pin,
        i2c,
    };

    touchpanel.reset();
    println!("Touchpanel version: {}", touchpanel.read_version());

    let epaper = EPaper {
        reset_pin: epaper_reset_pin,
        data_command_pin: epaper_dc_pin,
        chip_select_pin: epaper_cs_pin,
        busy_pin: epaper_busy_pin,
        spi,
    };

    let draw_target = BufferedDrawTarget::new(epaper);
    let mut draw_target = RotatedDrawTarget { inner: draw_target };

    let font = Font::from_bytes(
        include_bytes!("../resources/Lato-Regular.ttf") as &[u8],
        FontSettings::default(),
    )
    .unwrap();
    let fonts = &[font];
    let mut layout = Layout::new(fontdue::layout::CoordinateSystem::PositiveYDown);

    layout.append(fonts, &TextStyle::new("gżegżółką 🙀🥺", 30.0, 0));

    let mut pixels = vec![];
    for glyph in layout.glyphs() {
        let (metrics, data) = fonts[glyph.font_index].rasterize_config(glyph.key);

        dbg!(metrics, glyph);
   
        for (i, c) in data.iter().enumerate() {
            let pixel_x = (i % metrics.width) + glyph.x as usize;
            let pixel_y = (i / metrics.width) + glyph.y as usize;

            if *c > 63 {
                pixels.push((pixel_x, pixel_y));
            }
        }
    }

    let max_x = pixels.iter().map(|x| x.0).max().unwrap();
    let max_y = pixels.iter().map(|x| x.1).max().unwrap();

    let rounded_width_in_bytes = (max_x + 7) / 8;

    let mut bytes = vec![0u8; ((1 + rounded_width_in_bytes)) * ((max_y))];

    for (x, y) in pixels {
        let pixel_index = (y*rounded_width_in_bytes*8) + x;
        bytes[pixel_index/8] |= 1 << (7 - (pixel_index%8));
    }

    let image_raw = ImageRaw::<BinaryColor>::new(&bytes, 8*rounded_width_in_bytes as u32);
    let image = Image::new(&image_raw, Point { x: 20, y: 20 });

    image.draw(&mut draw_target).unwrap();

    draw_target.flush();

    loop {
        let touches = touchpanel.wait_for_touch();

        if touches.len() > 0 {
            println!("{:?}", touches);
        }
    }
}
