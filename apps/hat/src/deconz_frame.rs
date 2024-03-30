use thiserror::Error;

fn calculate_crc(input: &[u8]) -> [u8; 2] {
    let mut crc: u16 = 0;

    for byte in input {
        crc += (*byte) as u16;
    }

    let crc0: u8 = ((!crc + 1) & 0xFF) as u8;
    let crc1: u8 = (((!crc + 1) >> 8) & 0xFF) as u8;

    [crc0, crc1]
}

pub struct FrameBuilder(Vec<u8>);

impl FrameBuilder {
    pub fn new() -> Self {
        Self(vec![])
    }

    pub fn write_u8(&mut self, byte: u8) {
        self.0.push(byte);
    }

    pub fn write_u16(&mut self, value: u16) {
        self.0.extend_from_slice(&value.to_le_bytes());
    }

    pub fn write_u32(&mut self, value: u32) {
        self.0.extend_from_slice(&value.to_le_bytes());
    }

    pub fn to_raw_bytes(self) -> Vec<u8> {
        let mut bytes = self.0;
        bytes.extend(calculate_crc(&bytes));

        bytes
    }
}

#[derive(Error, Debug)]
pub enum FrameError {
    #[error("Frame too short, actual length: {0}")]
    TooShort(usize),
    #[error("Invalid frame CRC, actual: {0:?}, expected: {1:?}")]
    InvalidCrc(Vec<u8>, Vec<u8>),
}

pub struct FrameReader {
    data: Vec<u8>,
    cursor: usize,
}

impl FrameReader {
    pub fn new(raw_data: &[u8]) -> Result<Self, FrameError> {
        if raw_data.len() < 3 {
            return Err(FrameError::TooShort(raw_data.len()));
        }

        let data = &raw_data[0..raw_data.len() - 2];
        let crc = &raw_data[raw_data.len() - 2..];

        let actual_crc = calculate_crc(&data);

        if actual_crc != crc {
            return Err(FrameError::InvalidCrc(actual_crc.to_vec(), crc.to_vec()));
        }

        Ok(Self {
            data: data.to_vec(),
            cursor: 0,
        })
    }

    pub fn read_u8(&mut self) -> u8 {
        let result = self.data[self.cursor];

        self.cursor += 1;

        result
    }

    pub fn read_u16(&mut self) -> u16 {
        let result =
            u16::from_le_bytes(self.data[self.cursor..self.cursor + 2].try_into().unwrap());

        self.cursor += 2;

        result
    }

    pub fn read_u32(&mut self) -> u32 {
        let result =
            u32::from_le_bytes(self.data[self.cursor..self.cursor + 4].try_into().unwrap());

        self.cursor += 4;

        result
    }

    pub fn read_u64(&mut self) -> u64 {
        let result =
            u64::from_le_bytes(self.data[self.cursor..self.cursor + 8].try_into().unwrap());

        self.cursor += 8;

        result
    }
}
