use std::time::Duration;

use crate::{
    deconz_frame::{FrameBuilder, FrameReader},
    slip::SlipStream,
};

#[derive(Debug)]
pub struct SequenceNumber(u8);
impl SequenceNumber {
    pub(crate) fn new(arg: u8) -> SequenceNumber {
        SequenceNumber(arg)
    }
}

pub struct Version(u32);

impl std::fmt::Debug for Version {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let major = self.0 >> 24 & 0xFF;
        let minor = self.0 >> 16 & 0xFF;
        let platform = match self.0 >> 8 & 0xFF {
            0x05 => "ConBee/RaspBee".to_string(),
            0x07 => "ConBee II/RaspBee II".to_string(),
            0x09 => "ConBee III/RaspBee III".to_string(),
            other => format!("{other:#04X}"),
        };
        write!(f, "{major}.{minor} on {platform}")
    }
}

#[derive(Debug)]
pub enum Status {
    Success = 0x00,
    Failure = 0x01,
    Busy = 0x02,
    Timeout = 0x03,
    Unsupported = 0x04,
    Eroror = 0x05,
    NoNetwork = 0x06,
    InvalidValue = 0x07,
}

#[derive(Debug)]
pub enum NetworkState {
    Offline,
    Joining,
    Connected,
    Leaving,
}

#[derive(Debug)]
pub enum DeviceState {
    NetworkState,
    APSDEDataConfirm,
    APSDEDataIndication,
    ConfigurationChanged,
    APSDEDataRequest,
}

#[derive(Debug)]
pub enum NetworkParameterId {
    MACAddress,
    NetworkPANID,
    NetworkAddress,
    NetworkExtendedPANID,
    APSDesignatedCoordinator,
    ChannelMask,
    APSExtendedPANID,
    TrustCenterAddress,
    SecurityMode,
    PredefinedNetworkPANID,
    NetworkKey,
    LinkKey,
    CurrentChannel,
    ProtocolVersion,
    NetworkUpdateId,
    WatchdogTTL,
    NetworkFrameCounter,
    AppZDPResponseHandling,
}

pub struct MACAddress(u64);

impl std::fmt::Debug for MACAddress {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:#010X}", self.0)
    }
}

pub struct PANID(u16);

impl PANID {
    pub fn new(value: u16) -> Self {
        Self(value)
    }
}

impl std::fmt::Debug for PANID {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:#04X}", self.0)
    }
}

#[derive(Debug)]
pub struct ExtendedPANID(u64);

#[derive(Debug)]
pub struct NetworkAddress(u16);

#[derive(Debug)]
enum SecurityMode {
    NoSecurity,
    PreconfiguredNetworkKey,
    NetworkKeyFromTrustCenter,
    NoMasterWithTrustCenterLinkKey,
}

#[derive(Debug)]
pub struct EncryptionKey([u8; 16]);

#[derive(Debug)]
pub enum NetworkParameter {
    MACAddress(MACAddress),
    NetworkPANID(PANID),
    NetworkAddress(NetworkAddress),
    NetworkExtendedPANID(ExtendedPANID),
    APSDesignatedCoordinator(bool),
    ChannelMask(u32),
    APSExtendedPANID(ExtendedPANID),
    TrustCenterAddress(u64),
    SecurityMode(SecurityMode),
    PredefinedNetworkPANID(bool),
    NetworkKey(EncryptionKey),
    LinkKey(MACAddress, EncryptionKey),
    CurrentChannel(u8),
    ProtocolVersion(u16),
    NetworkUpdateId(u8),
    WatchdogTTL(Duration),
    NetworkFrameCounter(u32),
    AppZDPResponseHandling(u16),
}

pub enum Request {
    Version(SequenceNumber),
    ReadNetworkParameter(SequenceNumber, NetworkParameterId),
    WriteNetworkParameter(SequenceNumber, NetworkParameter),
    ReadDeviceState(SequenceNumber),
}

#[derive(Debug)]
pub enum Message {
    Version(SequenceNumber, Status, Version),
    DeviceStateChanged(SequenceNumber, Status, Vec<DeviceState>, NetworkState),
    ReadNetworkResponse(SequenceNumber, Status, NetworkParameter),
    WriteParameterResponse(SequenceNumber, Status, NetworkParameterId),
    ReadDeviceStateResponse(SequenceNumber, Status, Vec<DeviceState>, NetworkState),
}

pub struct DeconzStream(SlipStream);

impl DeconzStream {
    pub fn new(inner: SlipStream) -> Self {
        Self(inner)
    }

    pub fn send(&mut self, request: Request) {
        match request {
            Request::Version(sequence) => {
                let mut frame = FrameBuilder::new();
                frame.write_u8(0x0D); // Command - Read Version
                frame.write_u8(sequence.0); // Sequence Number
                frame.write_u8(0x00); // Reserved
                frame.write_u16(0x09); // frame length
                frame.write_u32(0x00); // reserved

                let frame = frame.to_raw_bytes();
                self.0.write_frame(&frame).unwrap();
            }
            Request::ReadNetworkParameter(sequence, p) => {
                let parameter_id = match p {
                    NetworkParameterId::MACAddress => 0x01,
                    NetworkParameterId::NetworkPANID => 0x05,
                    NetworkParameterId::NetworkAddress => 0x07,
                    NetworkParameterId::NetworkExtendedPANID => 0x08,
                    NetworkParameterId::APSDesignatedCoordinator => 0x09,
                    NetworkParameterId::ChannelMask => 0x0A,
                    NetworkParameterId::APSExtendedPANID => 0x0B,
                    NetworkParameterId::TrustCenterAddress => 0x0E,
                    NetworkParameterId::SecurityMode => 0x10,
                    NetworkParameterId::PredefinedNetworkPANID => 0x15,
                    NetworkParameterId::NetworkKey => 0x18,
                    NetworkParameterId::LinkKey => 0x19,
                    NetworkParameterId::CurrentChannel => 0x1C,
                    NetworkParameterId::ProtocolVersion => 0x22,
                    NetworkParameterId::NetworkUpdateId => 0x24,
                    NetworkParameterId::WatchdogTTL => 0x26,
                    NetworkParameterId::NetworkFrameCounter => 0x27,
                    NetworkParameterId::AppZDPResponseHandling => 0x28,
                };

                let mut frame = FrameBuilder::new();
                frame.write_u8(0x0A); // Command
                frame.write_u8(sequence.0); // Sequence Number
                frame.write_u8(0x00); // Reserved
                frame.write_u16(8); // frame length
                frame.write_u16(1); // payload length
                frame.write_u8(parameter_id);

                let frame = frame.to_raw_bytes();
                self.0.write_frame(&frame).unwrap();
            }
            Request::WriteNetworkParameter(sequence, parameter) => {
                let (parameter_length, parameter_id, writer) = match parameter {
                    NetworkParameter::MACAddress(_) => todo!(),
                    NetworkParameter::NetworkPANID(pan_id) => {
                        (2, 0x05, move |frame: &mut FrameBuilder| {
                            frame.write_u16(pan_id.0)
                        })
                    }
                    NetworkParameter::NetworkAddress(_) => todo!(),
                    NetworkParameter::NetworkExtendedPANID(_) => todo!(),
                    NetworkParameter::APSDesignatedCoordinator(_) => todo!(),
                    NetworkParameter::ChannelMask(_) => todo!(),
                    NetworkParameter::APSExtendedPANID(_) => todo!(),
                    NetworkParameter::TrustCenterAddress(_) => todo!(),
                    NetworkParameter::SecurityMode(_) => todo!(),
                    NetworkParameter::PredefinedNetworkPANID(_) => todo!(),
                    NetworkParameter::NetworkKey(_) => todo!(),
                    NetworkParameter::LinkKey(_, _) => todo!(),
                    NetworkParameter::CurrentChannel(_) => todo!(),
                    NetworkParameter::ProtocolVersion(_) => todo!(),
                    NetworkParameter::NetworkUpdateId(_) => todo!(),
                    NetworkParameter::WatchdogTTL(_) => todo!(),
                    NetworkParameter::NetworkFrameCounter(_) => todo!(),
                    NetworkParameter::AppZDPResponseHandling(_) => todo!(),
                };

                let mut frame = FrameBuilder::new();

                frame.write_u8(0x0B); // Command
                frame.write_u8(sequence.0); // Sequence Number
                frame.write_u8(0x00); // Reserved
                frame.write_u16(7 + 1 + parameter_length); // frame length
                frame.write_u16(1 + parameter_length); // payload length
                frame.write_u8(parameter_id);
                writer(&mut frame);

                let frame = frame.to_raw_bytes();
                self.0.write_frame(&frame).unwrap();
            }
            Request::ReadDeviceState(sequence) => {
                let mut frame = FrameBuilder::new();

                frame.write_u8(0x07); // Command
                frame.write_u8(sequence.0); // Sequence Number
                frame.write_u8(0x00); // Reserved
                frame.write_u16(8); // frame length
                frame.write_u8(0); // resverved
                frame.write_u8(0); // resverved
                frame.write_u8(0); // resverved

                let frame = frame.to_raw_bytes();
                self.0.write_frame(&frame).unwrap();
            }
        }
    }

    pub fn receive(&mut self) -> Option<Message> {
        let mut frame = FrameReader::new(&self.0.read_frame().unwrap()).unwrap();

        match frame.read_u8() {
            0x0D => {
                let sequence_number = frame.read_u8();
                let status = Self::read_status(&mut frame);
                let _frame_length = frame.read_u16();
                let version = frame.read_u32();

                Some(Message::Version(
                    SequenceNumber(sequence_number),
                    status,
                    Version(version),
                ))
            }
            0x0E => {
                let sequence_number = frame.read_u8();
                let status = Self::read_status(&mut frame);

                let _frame_length = frame.read_u16();
                let device_states = Self::read_device_states(&mut frame);
                Some(Message::DeviceStateChanged(
                    SequenceNumber(sequence_number),
                    status,
                    device_states.0,
                    device_states.1,
                ))
            }
            0x07 => {
                let sequence_number = frame.read_u8();
                let status = Self::read_status(&mut frame);

                let _frame_length = frame.read_u16();

                let device_states = Self::read_device_states(&mut frame);

                Some(Message::ReadDeviceStateResponse(
                    SequenceNumber(sequence_number),
                    status,
                    device_states.0,
                    device_states.1,
                ))
            }
            0x0A => {
                let sequence_number = frame.read_u8();
                let status = Self::read_status(&mut frame);

                let _frame_length = frame.read_u16();
                let _payload_length = frame.read_u16();
                let parameter_id = frame.read_u8();

                let parameter = match parameter_id {
                    0x01 => NetworkParameter::MACAddress(MACAddress(frame.read_u64())),
                    0x05 => NetworkParameter::NetworkPANID(PANID(frame.read_u16())),
                    p => todo!("Unsupported read response for parameter {p:#04X}"),
                };

                Some(Message::ReadNetworkResponse(
                    SequenceNumber(sequence_number),
                    status,
                    parameter,
                ))
            }
            0x0B => {
                let sequence_number = frame.read_u8();
                let status = Self::read_status(&mut frame);

                let _frame_length = frame.read_u16();
                let _payload_length = frame.read_u16();
                let parameter_id = frame.read_u8();

                let parameter_id = match parameter_id {
                    0x05 => NetworkParameterId::NetworkPANID,
                    p => todo!("Unknown parameter id: {p}"),
                };

                Some(Message::WriteParameterResponse(
                    SequenceNumber(sequence_number),
                    status,
                    parameter_id,
                ))
            }
            0x81 | 0x22 => {
                // FIXME figure out what this type of message means...
                None
            }
            t => {
                todo!("Unknown frame type {t:#04X}");
            }
        }
    }

    fn read_status(frame: &mut FrameReader) -> Status {
        match frame.read_u8() {
            0x00 => Status::Success,
            s => todo!("Unknown status: {s:#04X}"),
        }
    }

    fn read_device_states(frame: &mut FrameReader) -> (Vec<DeviceState>, NetworkState) {
        let raw_device_state = frame.read_u8();
        let mut device_states = vec![];
        let network_state = match raw_device_state & 0b0000_0011 {
            0b00 => NetworkState::Offline,
            0b01 => NetworkState::Joining,
            0b10 => NetworkState::Connected,
            0b11 => NetworkState::Leaving,
            _ => unreachable!(),
        };

        if raw_device_state & 0b0000_0100 != 0 {
            device_states.push(DeviceState::APSDEDataConfirm);
        }
        if raw_device_state & 0b0000_1000 != 0 {
            device_states.push(DeviceState::APSDEDataIndication);
        }
        if raw_device_state & 0b0001_0000 != 0 {
            device_states.push(DeviceState::ConfigurationChanged);
        }
        if raw_device_state & 0b0010_0000 != 0 {
            device_states.push(DeviceState::APSDEDataRequest);
        }

        (device_states, network_state)
    }
}
