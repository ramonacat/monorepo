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

resource "routeros_queue_simple" "scarletwound-vlan4" {
  provider = routeros.router-scarletwound

  name      = "vlan4"
  target    = [module.scarletwound-vlan4.cidr]
  limit_at  = "3M/40M"
  max_limit = "4M/55M"
  priority  = "4/4"
  queue     = "pcq-upload-default/pcq-download-default"
}

resource "routeros_queue_simple" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound

  name      = "vlan2"
  limit_at  = "8M/60M"
  max_limit = "15M/70M"
  priority  = "6/6"
  target    = [module.scarletwound-vlan2.cidr]
  queue     = "pcq-upload-default/pcq-download-default"
}

resource "routeros_queue_simple" "scarletwound-vlan5" {
  provider = routeros.router-scarletwound

  name      = "vlan5"
  limit_at  = "8M/60M"
  max_limit = "15M/70M"
  priority  = "6/6"
  target    = [module.scarletwound-vlan5.cidr]
  queue     = "pcq-upload-default/pcq-download-default"
}

resource "routeros_move_items" "scarletwound-queue-simple" {
  provider      = routeros.router-scarletwound
  resource_path = "/queue/simple"

  sequence = [
    routeros_queue_simple.scarletwound-high-priority.id,
    routeros_queue_simple.scarletwound-vlan4.id,
    routeros_queue_simple.scarletwound-vlan2.id,
    routeros_queue_simple.scarletwound-vlan5.id,
  ]
}
