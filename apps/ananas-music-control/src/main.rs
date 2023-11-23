use std::{time::Duration, thread::sleep};

use rppal::{spi::{Mode, Spi}, gpio::{OutputPin, InputPin, Level}};

const EPAPER_RESET_PIN:u8 = 17;
const EPAPER_DC_PIN:u8 = 25;
const EPAPER_CS_PIN:u8 = 8;
const EPAPER_BUSY_PIN:u8 = 24;

const EPAPER_WIDTH:usize = 122;
const EPAPER_HEIGHT:usize = 250;

const TOUCHSCREEN_TRST_PIN:u8 = 22;
const TOUCHSCREEN_INT_PIN:u8  = 27;

struct EPaper {
    reset_pin: OutputPin,
    data_command_pin: OutputPin,
    chip_select_pin: OutputPin,
    busy_pin: InputPin,
    spi: Spi
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

    fn send_command(&mut self, data:&[u8]) {
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

    fn set_display_window(&mut self, (x_start, y_start):(usize, usize), (x_end, y_end):(usize, usize)) {
        self.send_command(&[0x44]); // SET_RAM_X_ADDRESS_START_END_POSITION
        self.send_data(&[(x_start>>3 & 0xFF) as u8]);
        self.send_data(&[(x_end>>3 & 0xFF) as u8]);

        self.send_command(&[0x45]);
        
        self.send_data(&[(y_start & 0xFF) as u8]);
        self.send_data(&[(y_start>>8 & 0xFF) as u8]);
        
        self.send_data(&[(y_end & 0xFF) as u8]);
        self.send_data(&[(y_end>>8 & 0xFF) as u8]);
    }

    fn set_cursor(&mut self, (x, y):(usize, usize)) {
        self.send_command(&[0x4E]); // SET_RAM_X_ADDRESS_COUNTER
        self.send_data(&[(x & 0xFF) as u8]);

        self.send_command(&[0x4F]);
        self.send_data(&[(y & 0xFF) as u8]);
        self.send_data(&[(y>>8 & 0xFF) as u8]);
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

        self.set_display_window((0, 0), (EPAPER_WIDTH-1, EPAPER_HEIGHT-1));
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

fn main() {
    let spi = rppal::spi::Spi::new(rppal::spi::Bus::Spi0, rppal::spi::SlaveSelect::Ss0, 10000000, Mode::Mode0).unwrap();
    let gpio = rppal::gpio::Gpio::new().unwrap();

    let epaper_reset_pin = gpio.get(EPAPER_RESET_PIN).unwrap().into_output();
    let epaper_dc_pin = gpio.get(EPAPER_DC_PIN).unwrap().into_output();
    let epaper_cs_pin = gpio.get(EPAPER_CS_PIN).unwrap().into_output();
    let epaper_busy_pin = gpio.get(EPAPER_BUSY_PIN).unwrap().into_input();

    let touchscreen_reset_pin = gpio.get(TOUCHSCREEN_TRST_PIN).unwrap().into_output();
    let touchscreen_int_pin = gpio.get(TOUCHSCREEN_INT_PIN).unwrap().into_input();

    let mut epaper = EPaper  {
        reset_pin: epaper_reset_pin,
        data_command_pin: epaper_dc_pin,
        chip_select_pin: epaper_cs_pin,
        busy_pin: epaper_busy_pin,
        spi,
    };

    let mut image:Vec<u8> = vec![];
    for _row in 0..EPAPER_HEIGHT {
        for _column_byte in 0..(EPAPER_WIDTH/8)+1 {
            image.push(0xa5);
        }
    }

    epaper.write_image(&image);
    
    sleep(Duration::from_secs(5));

    let mut image:Vec<u8> = vec![];
    for _row in 0..EPAPER_HEIGHT {
        for _column_byte in 0..(EPAPER_WIDTH/8)+1 {
            image.push(0xFF);
        }
    }

    epaper.write_image(&image);
}
