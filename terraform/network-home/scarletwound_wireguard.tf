resource "routeros_interface_wireguard" "scarletwound-wg-mesh" {
  provider    = routeros.router-scarletwound
  name        = "global mesh"
  listen_port = 51820
  comment     = "peers are managed automatically by rad"
}
