pub mod wireguard;

use std::net::Ipv4Addr;

// this is basically a copy of Ipv4Addr::is_global from the standard library (it's unstable, but
// it is correct enough, so it's fine)
pub const fn is_global4(address: &Ipv4Addr) -> bool {
    !(address.octets()[0] == 0 // "This network"
        || address.is_private()
        || address.octets()[0] == 100 && (address.octets()[1] & 0b1100_0000 == 0b0100_0000)
        || address.is_loopback()
        || address.is_link_local()
        // addresses reserved for future protocols (`192.0.0.0/24`)
        // .9 and .10 are documented as globally reachable so they're excluded
        || (
            address.octets()[0] == 192 && address.octets()[1] == 0 && address.octets()[2] == 0
            && address.octets()[3] != 9 && address.octets()[3] != 10
        )
        || address.is_documentation()
        || address.octets()[0] == 198 && (address.octets()[1] & 0xfe) == 18
        || address.octets()[0] & 240 == 240 && !address.is_broadcast()
        || address.is_broadcast())
}
