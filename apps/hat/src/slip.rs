use std::io::{ErrorKind, Write};

use serialport::SerialPort;
use thiserror::Error;

const SLIP_END: u8 = 0o300;
const SLIP_ESC: u8 = 0o333;

const SLIP_ESC_END: u8 = 0o334;
const SLIP_ESC_ESC: u8 = 0o335;

#[derive(Error, Debug)]
pub enum Error {
    #[error("IO Error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Serialport: {0}")]
    Serialport(#[from] serialport::Error),
    #[error("Invalid escape sequence: {0}")]
    InvalidEscapeSequence(u8),
    #[error("Missing escape sequence")]
    MissingEscapeSequence,
}

pub struct SlipStream {
    inner: Box<dyn SerialPort>,
    buffer: Vec<u8>,
}

impl SlipStream {
    pub fn new(inner: Box<dyn SerialPort>) -> Self {
        Self {
            inner,
            buffer: vec![],
        }
    }

    pub fn write_frame(&mut self, frame: &[u8]) -> Result<(), Error> {
        let mut result = vec![SLIP_END];

        for byte in frame {
            if *byte == SLIP_END {
                result.push(SLIP_ESC);
                result.push(SLIP_ESC_END);
            } else if *byte == SLIP_ESC {
                result.push(SLIP_ESC);
                result.push(SLIP_ESC_ESC);
            } else {
                result.push(*byte);
            }
        }

        result.push(SLIP_END);

        self.inner.write_all(&result)?;

        Ok(())
    }

    pub fn read_frame(&mut self) -> Result<Vec<u8>, Error> {
        let mut buf = [0; 1024];

        loop {
            match self.inner.read(&mut buf) {
                Ok(bytes_read) => {
                    self.buffer.extend(&buf[0..bytes_read]);
                }
                Err(e) => {
                    if e.kind() == ErrorKind::TimedOut {
                        continue;
                    }

                    return Err(e.into());
                }
            }

            let mut current_frame = vec![];

            let mut iterator = self.buffer.iter().enumerate();

            while let Some((index, byte)) = iterator.next() {
                if *byte == SLIP_ESC {
                    match iterator.next() {
                        Some((_, b)) if *b == SLIP_ESC_ESC => {
                            current_frame.push(SLIP_ESC);
                        }
                        Some((_, b)) if *b == SLIP_ESC_END => {
                            current_frame.push(SLIP_END);
                        }
                        Some((_, b)) => {
                            return Err(Error::InvalidEscapeSequence(*b));
                        }
                        None => {
                            return Err(Error::MissingEscapeSequence);
                        }
                    }
                } else if *byte == SLIP_END {
                    if current_frame.is_empty() {
                        continue;
                    }

                    self.buffer = self.buffer[index + 1..].to_vec();

                    return Ok(current_frame);
                } else {
                    current_frame.push(*byte);
                }
            }
        }
    }
}
