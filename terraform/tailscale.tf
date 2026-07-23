// TODO this should be in the node module
data "external" "tailscale_tags" {
  program = ["bash", abspath("./scripts/external-tailscale-tags.bash")]
}

data "tailscale_device" "pikvm" {
  hostname = "pikvm"
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

moved {
  from = tailscale_device_tags.hallewell
  to   = module.external-node-hallewell.tailscale_device_tags.node[0]
}

moved {
  from = tailscale_device_tags.shadowsoul
  to   = module.external-node-shadowsoul.tailscale_device_tags.node[0]
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
        { src = ["tag:ci"], "dst" : ["tag:k8s"], "ip" : ["*"] },
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
        {
          src = ["tag:k8s"]
          dst = ["tag:server"]
          ip = [
            "tcp:9100", // prometheus node exporter 
            "tcp:9633", // prometheus smart exporter
            "tcp:9558", // prometheus systemd exporter
          ]
        },
        {
          src = ["tag:server"],
          dst = ["tag:k8s"],
          ip = [
            "tcp:6514", // syslog
            "tcp:443",
          ]
        }
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

        "tag:service-builds-host"  = [],
        "tag:service-servarr"      = [],
        "tag:service-transmission" = [],
        "tag:service-jellyfin"     = [],

        "tag:kubernetes-darkmore"               = [],
        "tag:kubernetes-darkmore-control-plane" = [],
        "tag:ci"                                = [],

        "tag:k8s-operator" = [],
        "tag:k8s"          = ["tag:k8s-operator"],
        "tag:k8s-service"  = ["tag:k8s-operator"],
      },
      tests = [
        {
          src   = "ramonacat@github",
          proto = "tcp",
          accept = [
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
            "tag:server-private:139",
            "tag:server-public:445",
          ],
          accept = [
            "tag:service-builds-host:22",
            "tag:service-builds-host:443",
          ]
        },
      ]
    }

  )
}
