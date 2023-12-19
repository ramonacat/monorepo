use std::{
    path::PathBuf,
    sync::{mpsc::channel, Arc},
    thread,
};

use fontdue::{Font, FontSettings};
use opentelemetry::KeyValue;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::Resource;
use rppal::{i2c::I2c, spi::Mode};
use tracing::{info, level_filters::LevelFilter};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, Layer, Registry};

use crate::{
    epaper::{BufferedDrawTarget, EPaper, RotatedDrawTarget},
    gui::geometry::Point,
    touch::EventCoalescer,
    touchpanel::TouchPanel,
    views::initial_view,
};

mod epaper;
mod gui;
mod library;
mod touch;
mod touchpanel;
mod views;

const EPAPER_RESET_PIN: u8 = 17;
const EPAPER_DC_PIN: u8 = 25;
const EPAPER_CS_PIN: u8 = 8;
const EPAPER_BUSY_PIN: u8 = 24;

const TOUCHSCREEN_TRST_PIN: u8 = 22;
const TOUCHSCREEN_INT_PIN: u8 = 27;

#[tokio::main]
async fn main() {
    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_endpoint("http://hallewell:4317/"),
        )
        .with_trace_config(
            opentelemetry_sdk::trace::config().with_resource(Resource::new(vec![KeyValue::new(
                "service.name",
                "music-control",
            )])),
        )
        .install_simple()
        .unwrap();

    let tracing_layer = tracing_opentelemetry::layer().with_tracer(tracer);
    Registry::default()
        .with(tracing_layer.with_filter(LevelFilter::INFO))
        .init();

    let span = tracing::info_span!("HELLO");
    span.in_scope(|| {
        info!("I am in span!");
    });

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

    let mut touchpanel = TouchPanel::new(touchscreen_reset_pin, touchscreen_int_pin, i2c);

    touchpanel.reset();
    println!("Touchpanel version: {}", touchpanel.read_version());

    let epaper = EPaper::new(
        epaper_reset_pin,
        epaper_dc_pin,
        epaper_cs_pin,
        epaper_busy_pin,
        spi,
    );

    let draw_target = BufferedDrawTarget::new(epaper);
    let draw_target = RotatedDrawTarget::new(draw_target);

    let font_lato = Font::from_bytes(
        include_bytes!("../resources/Lato-Regular.ttf") as &[u8],
        FontSettings::default(),
    )
    .unwrap();
    let font_noto_emoji = Font::from_bytes(
        include_bytes!("../resources/NotoEmoji-Regular.ttf") as &[u8],
        FontSettings::default(),
    )
    .unwrap();
    let fonts = vec![font_lato, font_noto_emoji];

    let library = Arc::new(library::Library::new(PathBuf::from("/mnt/nas/Music/")));

    let (events_tx, events_rx) = channel();
    let gui = gui::Gui::new(fonts, draw_target, initial_view(library), events_rx);

    let (tx, rx) = channel();
    let coalescer = EventCoalescer::new(touchpanel, tx);
    thread::spawn(|| coalescer.run());

    thread::spawn(move || {
        while let Ok(touch) = rx.recv() {
            match touch {
                touch::Event::Ended(ref pos) => {
                    // The positions are flipped, because the display is!
                    // TODO 250 is the height of the epaper, move it to a constant or something!
                    events_tx
                        .send(gui::Event::Touch(Point(250 - pos.y(), pos.x())))
                        .unwrap();
                }
                touch::Event::Started(_) | touch::Event::Moved(_) => {}
            }
        }
    });

    gui.run();
}
