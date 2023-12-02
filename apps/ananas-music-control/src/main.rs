use embedded_graphics::{
    geometry::Point,
    image::{Image, ImageRaw},
    pixelcolor::BinaryColor,
    Drawable,
};
use fontdue::{
    layout::{Layout, TextStyle},
    Font, FontSettings,
};
use opentelemetry::{
    trace::{self, Tracer, TracerProvider},
    KeyValue,
};
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::Resource;
use rppal::{i2c::I2c, spi::Mode};
use tracing::{level_filters::LevelFilter, info};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, Registry, Layer};

use crate::{
    epaper::{BufferedDrawTarget, EPaper, FlushableDrawTarget, RotatedDrawTarget},
    touchpanel::TouchPanel,
};

mod epaper;
mod touchpanel;

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
    let mut draw_target = RotatedDrawTarget::new(draw_target);

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
    let fonts = &[font_lato, font_noto_emoji];
    let mut layout = Layout::new(fontdue::layout::CoordinateSystem::PositiveYDown);

    layout.append(fonts, &TextStyle::new("gżegżółką ", 10.0, 0));
    layout.append(fonts, &TextStyle::new("🙀🥺", 50.0, 1));

    let mut pixels = vec![];
    for glyph in layout.glyphs() {
        let (metrics, data) = fonts[glyph.font_index].rasterize_config(glyph.key);

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

    let mut bytes = vec![0u8; (1 + rounded_width_in_bytes) * (max_y)];

    for (x, y) in pixels {
        let pixel_index = (y * rounded_width_in_bytes * 8) + x;
        bytes[pixel_index / 8] |= 1 << (7 - (pixel_index % 8));
    }

    let image_raw = ImageRaw::<BinaryColor>::new(&bytes, 8 * rounded_width_in_bytes as u32);
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
