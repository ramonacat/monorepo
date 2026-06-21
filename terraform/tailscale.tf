// TODO this should be in the node module
data "external" "tailscale_tags" {
  program = ["bash", abspath("./scripts/external-tailscale-tags.bash")]
}

data "tailscale_device" "pikvm" {
  hostname = "pikvm"
}

data "tailscale_device" "hallewell" {
  hostname = "hallewell"
}

data "tailscale_device" "shadowsoul" {
  hostname = "shadowsoul"
}

moved {
  from = tailscale_device_tags.tags
  to   = tailscale_device_tags.devices
}

resource "tailscale_device_tags" "pikvm" {
  device_id = data.tailscale_device.pikvm.node_id
  tags      = ["tag:server", "tag:server-private", "tag:server-private-home"]
}

resource "tailscale_device_tags" "homeassistant" {
  device_id = data.tailscale_device.pikvm.node_id
  tags      = ["tag:server", "tag:server-private", "tag:server-private-home"]
}

removed {
  from = tailscale_device_tags.devices

  lifecycle {
    destroy = false
  }
}

// TODO create a module for physical machines that sets up dns, tailscale tags, etc.
resource "tailscale_device_tags" "hallewell" {
  device_id = data.tailscale_device.hallewell.node_id
  tags      = split(" ", data.external.tailscale_tags.result["hallewell"])
}

resource "tailscale_device_tags" "shadowsoul" {
  device_id = data.tailscale_device.shadowsoul.node_id
  tags      = split(" ", data.external.tailscale_tags.result["shadowsoul"])
}

resource "tailscale_dns_configuration" "default" {
  override_local_dns = true

  nameservers {
    address            = "8.8.8.8"
    use_with_exit_node = false
  }
}

resource "tailscale_tailnet_settings" "default" {
  acls_externally_managed_on = true
  devices_approval_on        = true
  users_approval_on          = true
}

resource "tailscale_acl" "default" {
  acl = jsonencode(
    {
      grants = [
        { src = ["autogroup:admin"], "dst" : ["*"], "ip" : ["*"] },
        {
          src = ["tag:server"],
          dst = ["tag:service-builds-host"],
          ip  = ["tcp:22", "tcp:443"],
        },
        {
          src = ["tag:service-builds-host"],
          dst = ["tag:server"],
          ip  = ["tcp:22"],
        },
        {
          src = ["tag:server"],
          dst = ["tag:service-monitoring"],
          ip = [
            "tcp:8094", // telegraf
            "tcp:443",  // ras
          ]
        },
        {
          src = ["tag:service-servarr"],
          dst = ["tag:service-transmission"],
          ip = [
            "tcp:9091", // transmission
          ]
        },
        {
          src = ["tag:service-builds-host"],
          dst = ["tag:kubernetes-darkmore-control-plane"],
          ip = [
            "tcp:6443" // kubernetes apiserver (needed for deplyoments)
          ]
        },
        {
          src = ["tag:service-builds-host"],
          dst = ["svc:gateway"],
          ip = [
            "tcp:443",
            "tcp:80"
          ]
        },
        {
          src = ["tag:k8s"],
          dst = ["tag:service-jellyfin"],
          ip = [
            "tcp:8096",
          ]
        },
      ],
      autoApprovers = {
        "services" : {
          "tag:k8s-service" = ["tag:k8s"]
        }
      },
      tagOwners = {
        "tag:server" = [],

        "tag:server-public"         = [],
        "tag:server-public-hetzner" = [],

        "tag:server-private"      = [],
        "tag:server-private-home" = [],
        "tag:server-private-pl1"  = [],

        "tag:service-monitoring"   = [],
        "tag:service-builds-host"  = [],
        "tag:service-servarr"      = [],
        "tag:service-transmission" = [],
        "tag:service-jellyfin"     = [],

        "tag:kubernetes-darkmore"               = [],
        "tag:kubernetes-darkmore-control-plane" = [],

        "tag:k8s-operator" : [],
        "tag:k8s" : ["tag:k8s-operator"],
        "tag:k8s-service" : ["tag:k8s-operator"]
      },
      tests = [
        {
          src   = "ramonacat@github",
          proto = "tcp",
          accept = [
            "tag:service-monitoring:22",
            "tag:server-private:22",
            "tag:server-public:445"
          ]
        },
        {
          src   = "tag:server",
          proto = "tcp",
          deny = [
            "tag:server-private:22",
            "tag:server-public:22",
            "tag:service-monitoring:139",
            "tag:service-monitoring:445",
            "tag:server-private:139",
            "tag:server-public:445",
            "tag:service-monitoring:5432",
            "tag:service-monitoring:9000",
          ],
          accept = [
            "tag:service-builds-host:22",
            "tag:service-builds-host:443",
          ]
        },
        {
          src   = "tag:server",
          proto = "tcp",
          accept = [
            "tag:service-monitoring:8094",
            "tag:service-monitoring:443",
          ]
        },
      ]
    }

  )
}
