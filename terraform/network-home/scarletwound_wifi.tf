resource "routeros_interface_wireless" "scarletwound-wlan1" {
  provider               = routeros.router-scarletwound
  name                   = "wlan1"
  disabled               = false
  default_authentication = false
  hide_ssid              = true
  mode                   = "ap-bridge"
  channel_width = "20/40mhz-XX"
  country = "germany"
  band = "2ghz-b/g/n"
  frequency = "auto"
}

resource "routeros_interface_wireless" "scarletwound-wlan2" {
  provider               = routeros.router-scarletwound
  name                   = "wlan2"
  disabled               = false
  default_authentication = false
  hide_ssid              = true
  mode                   = "ap-bridge"
  channel_width = "20/40/80mhz-XXXX"
  country = "germany"
  band = "5ghz-a/n/ac"
  frequency = "auto"
}

resource "routeros_interface_wireless_security_profiles" "scarletwound-low-privilege" {
  provider             = routeros.router-scarletwound
  name                 = "low-privilege"
  mode                 = "dynamic-keys"
  authentication_types = ["wpa-psk", "wpa2-psk"]
  wpa_pre_shared_key   = var.wifi_psk_low_privilege
  wpa2_pre_shared_key  = var.wifi_psk_low_privilege
}

resource "routeros_interface_wireless_security_profiles" "scarletwound-iot" {
  provider             = routeros.router-scarletwound
  name                 = "iot"
  mode                 = "dynamic-keys"
  authentication_types = ["wpa-psk", "wpa2-psk"]
  wpa_pre_shared_key   = var.wifi_psk_iot
  wpa2_pre_shared_key  = var.wifi_psk_iot
}

resource "routeros_interface_wireless" "scarletwound-wlan1-low-privilege" {
  provider         = routeros.router-scarletwound
  security_profile = routeros_interface_wireless_security_profiles.scarletwound-low-privilege.name
  mode             = "ap-bridge"
  master_interface = routeros_interface_wireless.scarletwound-wlan1.name
  name             = "wlan1-low-privilege"
  ssid             = "ramona/lp"
  vlan_id          = routeros_interface_vlan.scarletwound-vlan5.vlan_id
  disabled         = false
}

resource "routeros_interface_wireless" "scarletwound-wlan2-low-privilege" {
  provider         = routeros.router-scarletwound
  security_profile = routeros_interface_wireless_security_profiles.scarletwound-low-privilege.name
  mode             = "ap-bridge"
  master_interface = routeros_interface_wireless.scarletwound-wlan2.name
  name             = "wlan2-low-privilege"
  ssid             = "ramona/lp"
  vlan_id          = routeros_interface_vlan.scarletwound-vlan5.vlan_id
  disabled         = false
}

resource "routeros_interface_wireless" "scarletwound-wlan1-iot" {
  provider         = routeros.router-scarletwound
  security_profile = routeros_interface_wireless_security_profiles.scarletwound-iot.name
  mode             = "ap-bridge"
  master_interface = routeros_interface_wireless.scarletwound-wlan1.name
  name             = "wlan1-iot"
  ssid             = "ramona/iot"
  vlan_id          = routeros_interface_vlan.scarletwound-vlan6.vlan_id
  disabled         = false
}

resource "routeros_interface_wireless" "scarletwound-wlan2-iot" {
  provider         = routeros.router-scarletwound
  security_profile = routeros_interface_wireless_security_profiles.scarletwound-iot.name
  mode             = "ap-bridge"
  master_interface = routeros_interface_wireless.scarletwound-wlan2.name
  name             = "wlan2-iot"
  ssid             = "ramona/iot"
  vlan_id          = routeros_interface_vlan.scarletwound-vlan6.vlan_id
  disabled         = false
}
