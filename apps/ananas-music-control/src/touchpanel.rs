use std::{
    thread::sleep,
    time::{Duration, SystemTime},
};

use rppal::{
    gpio::{InputPin, OutputPin},
    i2c::I2c,
};

pub struct TouchPanel {
    reset_pin: OutputPin,
    interrupt_pin: InputPin,
    i2c: I2c,
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct Touch {
    pub x: u32,
    pub y: u32,
    pub size: u32,
    pub track_id: u8,
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

    fn reset_interrupt(&mut self) {
        self.i2c.smbus_write_word(0x81, 0x004E).unwrap();
    }

    // https://github.com/torvalds/linux/blob/master/drivers/input/touchscreen/goodix.c
    pub fn wait_for_touch(&mut self) -> Option<Vec<Touch>> {
        self.reset_interrupt();

        self.interrupt_pin
            .set_interrupt(rppal::gpio::Trigger::RisingEdge, None)
            .unwrap();

        while self
            .interrupt_pin
            .poll_interrupt(false, None)
            .unwrap()
            .is_none()
        {}

        let mut buffer = [0u8; 1];

        let start = SystemTime::now();

        loop {
            self.i2c.smbus_write_byte(0x81, 0x4E).unwrap();
            self.i2c.read(&mut buffer).unwrap();

            let touchpoint_flag = buffer[0] & 0x80;
            if touchpoint_flag != 0 {
                break;
            }

            if start.elapsed().unwrap().as_millis() > 20 {
                return None;
            }
        }

        let touch_count = buffer[0] & 0x0f;

        if !(1..=5).contains(&touch_count) {
            return Some(vec![]);
        }

        let mut buffer_touches = vec![0u8; touch_count as usize * 8];
        self.i2c.smbus_write_byte(0x81, 0x4F).unwrap();
        self.i2c.read(&mut buffer_touches).unwrap();

        let mut touches = vec![];

        for i in 0..touch_count as usize {
            touches.push(Touch {
                x: ((buffer_touches[2 + 8 * i] as u32) << 8) + buffer_touches[1 + 8 * i] as u32,
                y: ((buffer_touches[4 + 8 * i] as u32) << 8) + buffer_touches[3 + 8 * i] as u32,
                size: ((buffer_touches[6 + 8 * i] as u32) << 8) + buffer_touches[5 + 8 * i] as u32,
                track_id: (buffer_touches[8 * i]),
            });
        }

        Some(touches)
    }
}
