{ pkgs, config, ... }: {
  systemd =
    let
      kubelet-config = "/var/lib/kubelet/config.yaml";
      kubelet-kubeconfig = "/etc/kubernetes/kubelet.conf";
    in
    {
      services.kubelet = {
        description = "kubernetes kubelet service";
        wantedBy = [ "default.target" ];
        after = [
          "containerd.service"
          "network.target"
        ];
        # these are various binaries needed by the kubelet when it runs, the list is stolen from: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/cluster/kubernetes/kubelet.nix#L332
        # be careful removing things, as they are not needed for startup, but cause things to fail later if missing
        path = with pkgs; [
          gitMinimal
          openssh
          util-linuxMinimal
          iproute2
          ethtool
          thin-provisioning-tools
          iptables
          socat
          nftables
        ];
        preStart =
          let
            bin-path = config.ramona.kubernetes.cni.bin;
          in
          ''
            shopt -s nullglob

            mkdir -p "${bin-path}"

            for f in ${pkgs.cni-plugins}/bin/*; do
              plugin_name=$(basename $f)

              [ -f "${bin-path}/$plugin_name" ] && rm "${bin-path}/$plugin_name"
                
              ln -s "$f" "${bin-path}/$plugin_name"
            done
          '';
        serviceConfig = {
          MemoryAccounting = true;
          Restart = "on-failure";
          RestartSec = "1000ms";
          ExecStart =
            let
              kubelet-script = pkgs.writeShellScriptBin "kubelet-wrapper" ''
                declare -a arguments=()
                if [[ -f "${kubelet-config}" ]]; then
                  arguments+=("--config=${kubelet-config}")
                fi

                exec ${pkgs.kubernetes}/bin/kubelet "''${arguments[@]}" \
                    --hostname-override=${config.networking.hostName} \
                    --fail-swap-on=false \
                    --node-ip=${config.ramona.darkmore-control-plane.ip} \
                    --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
                    --kubeconfig=${kubelet-kubeconfig} \
                    --cloud-provider=external \
                    --resolv-conf /run/systemd/resolve/resolv.conf
              '';
            in
            "${kubelet-script}/bin/kubelet-wrapper";
        };
      };
    };

}
