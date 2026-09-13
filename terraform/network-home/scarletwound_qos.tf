resource "routeros_queue_type" "scarletwound-cake" {
  provider = routeros.router-scarletwound

  name     = "cake"
  kind     = "cake"
  cake_nat = true
}

resource "routeros_queue_simple" "scarletwound-high-priority" {
  provider = routeros.router-scarletwound

  name         = "high-priority"
  target       = ["0.0.0.0/0"]
  limit_at     = "20M/70M"
  max_limit    = "1G/1G"
  priority     = "8/8"
  packet_marks = ["high-priority"]
  queue        = "pcq-upload-default/pcq-download-default"
}

resource "routeros_queue_simple" "scarletwound-local" {
  provider = routeros.router-scarletwound

  name         = "local"
  target       = ["10.32.0.0/14"]
  limit_at     = "900M/900M"
  max_limit    = "1G/1G"
  queue        = "pcq-upload-default/pcq-download-default"
  packet_marks = ["no-mark"]
}

resource "routeros_queue_simple" "scarletwound-vlan4" {
  provider = routeros.router-scarletwound

  name      = "vlan4"
  target    = [module.scarletwound-vlan4.cidr]
  limit_at  = "6M/40M"
  max_limit = "10M/60M"
  priority  = "4/4"
  queue     = "${routeros_queue_type.scarletwound-cake.name}/${routeros_queue_type.scarletwound-cake.name}"
}

resource "routeros_queue_simple" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound

  name      = "vlan2"
  limit_at  = "10M/40M"
  max_limit = "15M/60M"
  priority  = "6/6"
  target    = [module.scarletwound-vlan2.cidr]
  queue     = "${routeros_queue_type.scarletwound-cake.name}/${routeros_queue_type.scarletwound-cake.name}"
}

resource "routeros_queue_simple" "scarletwound-vlan5" {
  provider = routeros.router-scarletwound

  name      = "vlan5"
  limit_at  = "10M/40M"
  max_limit = "15M/60M"
  priority  = "6/6"
  target    = [module.scarletwound-vlan5.cidr]
  queue     = "${routeros_queue_type.scarletwound-cake.name}/${routeros_queue_type.scarletwound-cake.name}"
}

resource "routeros_move_items" "scarletwound-queue-simple" {
  provider      = routeros.router-scarletwound
  resource_path = "/queue/simple"

  sequence = [
    routeros_queue_simple.scarletwound-high-priority.id,
    routeros_queue_simple.scarletwound-local.id,
    routeros_queue_simple.scarletwound-vlan2.id,
    routeros_queue_simple.scarletwound-vlan5.id,
    routeros_queue_simple.scarletwound-vlan4.id,
  ]
}

resource "routeros_queue_tree" "scarletwound-internet-out" {
  provider    = routeros.router-scarletwound
  name        = "internet-out"
  parent      = routeros_interface_vlan.scarletwound-vlan7.name
  queue       = routeros_queue_type.scarletwound-cake.name
  packet_mark = ["internet-out"]
  limit_at    = "6M"
  max_limit   = "8M"
}

resource "routeros_queue_tree" "scarletwound-internet-in" {
  provider    = routeros.router-scarletwound
  name        = "internet-in"
  parent      = "global"
  queue       = routeros_queue_type.scarletwound-cake.name
  packet_mark = ["internet-in"]
  limit_at    = "50M"
  max_limit   = "60M"
}
