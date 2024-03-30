mod deconz;
mod deconz_frame;
mod slip;

use std::time::Duration;

use deconz::{DeconzStream, NetworkParameter, NetworkParameterId, Request, SequenceNumber, PANID};

use crate::slip::SlipStream;

fn main() {
    let port = serialport::new("/dev/ttyUSB0", 115200)
        .timeout(Duration::from_secs(1))
        .open()
        .unwrap();

    let slip_stream = SlipStream::new(port);
    let mut deconz_stream = DeconzStream::new(slip_stream);

    deconz_stream.send(Request::Version(SequenceNumber::new(0)));

    let mut message_queue = vec![
        Request::ReadNetworkParameter(SequenceNumber::new(1), NetworkParameterId::NetworkPANID),
        Request::WriteNetworkParameter(
            SequenceNumber::new(2),
            NetworkParameter::NetworkPANID(PANID::new(0x1235)),
        ),
        Request::ReadNetworkParameter(SequenceNumber::new(3), NetworkParameterId::NetworkPANID),
        Request::ReadDeviceState(SequenceNumber::new(4)),
    ];

    loop {
        let message = deconz_stream.receive();

        println!("{:?}", message);

        if let Some(request) = message_queue.pop() {
            deconz_stream.send(request);
        }
    }
}
