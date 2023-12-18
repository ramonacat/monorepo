use zbus::dbus_proxy;

#[dbus_proxy(interface = "org.freedesktop.UPower", assume_defaults = true)]
trait UPower {    
    #[dbus_proxy(object = "Device")]
    fn get_display_device(&self);

    #[dbus_proxy(property)]
    fn on_battery(&self) -> zbus::Result<bool>;
}

#[dbus_proxy(
    interface = "org.freedesktop.UPower.Device",
    default_service = "org.freedesktop.UPower",
    assume_defaults = false
)]
trait Device {

    #[dbus_proxy(property)]
    fn energy(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy_full(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy_empty(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy_rate(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn time_to_full(&self) -> zbus::Result<i64>;

    #[dbus_proxy(property)]
    fn time_to_empty(&self) -> zbus::Result<i64>;
}