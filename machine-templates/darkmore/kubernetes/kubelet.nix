{ pkgs, config, ... }: {
  systemd =
    let
      kubelet-config = pkgs.writeText "kubelet.conf" ''
        apiVersion: kubelet.config.k8s.io/v1beta1
        authentication:
          anonymous:
            enabled: false
          webhook:
            cacheTTL: 0s
            enabled: true
          x509:
            clientCAFile: /etc/kubernetes/pki/ca.crt
        authorization:
          mode: Webhook
          webhook:
            cacheAuthorizedTTL: 0s
            cacheUnauthorizedTTL: 0s
        cgroupDriver: systemd
        clusterDNS:
        - ${config.ramona.kubernetes.cluster-dns-ip}
        clusterDomain: cluster.local
        containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
        cpuManagerReconcilePeriod: 0s
        crashLoopBackOff: {}
        evictionPressureTransitionPeriod: 0s
        failOnSwap: false
        fileCheckFrequency: 0s
        healthzBindAddress: 127.0.0.1
        healthzPort: 10248
        httpCheckFrequency: 0s
        imageMaximumGCAge: 0s
        imageMinimumGCAge: 0s
        kind: KubeletConfiguration
        logging:
          flushFrequency: 0
          options:
            json:
              infoBufferSize: "0"
            text:
              infoBufferSize: "0"
          verbosity: 0
          format: 'json'
        memorySwap:
          swapBehavior: LimitedSwap
        nodeStatusReportFrequency: 0s
        nodeStatusUpdateFrequency: 0s
        resolvConf: /run/systemd/resolve/resolv.conf
        rotateCertificates: true
        runtimeRequestTimeout: 0s
        shutdownGracePeriod: 0s
        shutdownGracePeriodCriticalPods: 0s
        staticPodPath: /etc/kubernetes/manifests
        streamingConnectionIdleTimeout: 0s
        syncFrequency: 0s
        volumeStatsAggPeriod: 0s
        evictionHard:
            memory.available: "100Mi"
            nodefs.available: "2%"
            nodefs.inodesFree: "20%"
            imagefs.available: "5%"
      '';
      kubelet-kubeconfig = "/etc/kubernetes/kubelet.conf";
    in
    {
      services.kubelet = {
        description = "kubernetes kubelet service";
        wantedBy = [ "kubernetes.target" ];
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
                exec ${pkgs.kubernetes}/bin/kubelet "''${arguments[@]}" \
                    --hostname-override=${config.networking.hostName} \
                    --fail-swap-on=false \
                    --node-ip=${config.ramona.kubernetes.ip} \
                    --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
                    --kubeconfig=${kubelet-kubeconfig} \
                    --cloud-provider=external \
                    --resolv-conf /run/systemd/resolve/resolv.conf \
                    --config=${kubelet-config}
              '';
            in
            "${kubelet-script}/bin/kubelet-wrapper";
        };
      };
    };

}
