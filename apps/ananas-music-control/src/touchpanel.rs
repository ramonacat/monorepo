use std::{thread::sleep, time::Duration};

use rppal::{
    gpio::{InputPin, OutputPin},
    i2c::I2c,
};

pub struct TouchPanel {
    reset_pin: OutputPin,
    interrupt_pin: InputPin,
    i2c: I2c,
}

#[derive(Debug)]
pub struct Touch {
    x: usize,
    y: usize,
    strength: usize,
    track_id: u8,
}

impl TouchPanel {
    pub fn new(reset_pin: OutputPin, interrupt_pin: InputPin, i2c: I2c) -> Self {
        Self {
            reset_pin,
            interrupt_pin,
            i2c,
        }
    }

    pub fn reset(&mut self) {
        self.reset_pin.set_high();
        sleep(Duration::from_millis(100));
        self.reset_pin.set_low();
        sleep(Duration::from_millis(100));
        self.reset_pin.set_high();
        sleep(Duration::from_millis(1000));
    }

    pub fn read_version(&mut self) -> u32 {
        let mut buffer = [0u8; 4];
        self.i2c.smbus_write_byte(0x81, 0x40).unwrap();
        self.i2c.read(&mut buffer).unwrap();

        u32::from_le_bytes(buffer)
    }

    pub fn wait_for_touch(&mut self) -> Vec<Touch> {
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
