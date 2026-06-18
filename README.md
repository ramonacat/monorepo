# ramona's monorepo 

This is where my infrastructure lives. 

All the instructions below assume running in `nix develop` shell from this flake, and that you have an SSH key named `SSH key` from my 1password in `~/.ssh/id_ed25519` (it's not enough to have an SSH Agent with that key, as `age`, and therefore `agenix`, requires access to the actual private key).

## Contents of the repository, by directory
- `.github` - contains CI configurations (note: the secrets are manually set through github's webinterface)
- `apps` - various applications
- `data` 
  - `hosts.nix` - all the hostnames - the nixos ones are added automatically, windows machines must be added manually
  - `packages.nix` - versions of language runtimes used by the rest of the flake
  - `paths.nix` - paths to various things, used throught the flake
  - `ssh-keys.nix` - all the SSH keys
  - `synchting.nix` - syncthing configuration and topology, add new nodes here (`roles/private/syncthing.nix` defines syncthing configurations, if you are creating a new private machine, you can generate the secrets with `generate-syncthing-keys ./secrets/ <HOSTNAME>`)
- `libs` - libraries used throught
- `machine-templates` - configurations for clustered machines
- `machines` - configurations for all the hosts
- `modules` - nix modules to ease configuration of various things
- `outputs` - outputs of the flake, imported in `flake.nix`
- `roles` - shared configuration for various roles that machines can have, these can be imported as modules
- `scripts` - scripts for generating keys, etc. - those are loaded into the devshell in `./outputs/dev-shells.nix`
    - note: when a script is modified you need to run a new shell with `nix develop` (or `direnv reload` if you're using that), so that the shell uses the new version
- `secrets` - agenix secrets and their configuration (in `secrets/secrets.nix`)
- `terraform` - terraform configurations for everything
- `users` - user-specific configurations (home-manager configs can also be used independently)

## Making configuration changes to existing nodes

1. Make changes as appropriate
2. Create a PR and fix any build issues (you can also run `nix flake check` locally)
3. Once green, merge.
4. Once the CI on the `main` branch succeeds, the affected nodes will pull their new closures within about a minute.
5. In case of issues with automatic updates, `ssh root@<HOSTNAME>` and check the logs: `journalctl --unit updater --follow`

## Setting up a new wsl environment

1. Install latest debian stable and ensure it's up to date
2. On the host - enable the SSH Agent in 1password, and install npiperelay (`winget install albertony.npiperelay`)
3. Install lix in multiuser mode (https://lix.systems/install/)
4. Go to the summary of the latest `build-machines` CI job and find the closure for `ramona-wsl`
5. Copy the closure: `nix-copy-closure --from root@hallewell <CLOSURE>`
6. Activate it: `<CLOSURE>/bin/activate` (this will, among other things, install an automatic updater job as a user systemd service called `updater`)
7. Switch your user to bash from the new home-managed profile: `chsh -s /home/ramona:/home/ramona/.nix-profile/bin/bash ramona`
8. Restart the shell and have fun.

## Creating a new node

1. Create a config in `machines/` directory (probably easiest to just copy paste on of the existing machines), where the directory name is the hostname (remember to set it in `networking.hostName` as well)
    - there are some potentially useful modules that can be imported from `modules/` as well as common configs in `roles/`
    - there's also `machine-templates/` directory that can be used for clusters, etc. -- those need to be manually added to `outputs/nixos-configurations-x86_64-linux.nix`
2. Add entries for host keys in `secrets/secrets.nix` (`<HOSTNAME>-ssh-host-key-ed25519.age` and `<HOSTNAME>--ssh-host-key-rsa.age`, with appropriate reciepients, including `ci`, so it can be deployed automatically)
3. Run `generate-host-keys ./secrets/ <HOSTNAME>`
4. Paste the output of previous command into `data/ssh-keys.nix` (under the `machines` key)
5. Add a `<HOSTNAME> = ssh-keys.machines.<HOSTNAME>.rsa` variable to `secrets/secrets.nix`, and add to `publicServers`.
6. Inside the `secrets` directory run `agenix -r` to rekey the secrets to include the new host keys.

### For cloud nodes
1. Create a file that instantiates the `node` module in the terraform directory.
2. Create a PR, wait for it to build (you can also run `nix flake check` locally beforehand) and fix any issues.
3. A terraform plan will be posted as a PR comment, verify that it does what it should and if so, merge the PR. 
4. Ensure the builds on the main branch succeed (sadly some terraform issues only happen during apply), once they do, the machine should be reachable over tailscale and running as configured in the repository.

### For physical nodes
1. Create a PR, and merge once the builds succeed. When the build on the `main` branch finishes, the configuration is ready for deployment.
2. Run `make-preinstall-bundle <HOSTNAME>`
2. Download and boot `https://ramona.fun/public/nixos-latest.iso`. Either `ssh` as `root`, or use the local console for the rest of the setup.
3. Manually partition the disk as appropriate (ensure the configuration is in sync with what's in the repository), and mount in `/mnt/` (if other partitions are present, ensure they are mounted in appropriate locations)
4. Copy the preinstall bundle from your machine (`scp <HOSTNAME>-rootfs.tar root@<IP_OF_THE_NODE>:/root/`) and extract it into `/mnt/` (`cd /mnt && tar zvf /root/<HOSTNAME>-rootfs.tar`)
5. Go to the summary of the `build-machines` CI job, and find the closure for your new machine.
6. On your local machine run `nix-copy-closure --from root@hallewell <CLOSURE>`, and then `nix-copy-closure --to root@<IP_OF_THE_NODE> <CLOSURE>` (if you need a non-standard `ssh` port, prepend `NIX_SSHOPTS='-p <PORT>' ` to the command.
    - if the closure is too big to fit in memory, you can perform a standard nixos installation following the manual, and then copy the closure and switch with `<CLOSURE>/bin/switch-to-configuration switch`
7. Perform the installation using `nix-install --closure <CLOSURE>` and reboot
8. Once the node is up, `ssh root@<IP_OF_THE_NODE>`, and start tailscale (`tailscale up`, and then follow the prompts).
9. Create a PR adding tags to the nodes (you just need to add `data "tailscale_device" "<HOSTNAME>" { hostname = "<HOSTNAME>"; }`, and then a `tailscale_device_tags` resource analogus to current settings for other machines. The tags are automatically generated in `flake.nix`).

## Creating new applications
1. Create a directory in `apps/` containg the app. If it's in rust, add it to the workspace at the root of the repo.
2. Create a new file in `packages/` which exports an attrset with keys `package` (the derivation for the package), `coverage` (a derivation that should produce an lcov coverage file, where paths are relative to `(toString ./.)` in the root of the flake), and `checks`, which is an attrset with arbitrary names as keys, and derivations as values that execute the checks (build should fail if the check fails), such as lints, formatting checks, etc.
    - look through currently existing files, rust is very abstracted for example
    - the coverage will be automagically picked up by the CI
3. Import the file in `packages/default.nix`, with the package name as the key under `apps`
4. The app will be available as `pkgs.ramona.your-key` throught the flake. Can be built standalone with `nix build .#your-key` as well.

## Disaster recovery

Automatic updates can be stopped:

- for home manager: `touch ~/.stop_updates`
- nodes: `touch /var/.stop_updates`

Generally the flake should build anywhere, so the machines can be rebuilt by checking out the repo and doing `nixos-rebuild --flake .#<HOSTNAME>`. Terraform will work with the normal `terraform validate`/`terraform plan`/`terraform apply` worflow as long as you have the SSH key and are in the `nix develop` shell (there's a wrapper defined in `outputs/dev-shells.nix` that decrypts `secrets/terraform-tokens.age` and exports the secrets as environment variables).

# Kubernetes setup
```
# On any of the nodes, afterwards kubeadm will give you a `kubeadm init` command. Modify it to ensure that `--apiserver-advertise-address` is correct (see below)
# Ensure the 10.70.0.0/16 IP matches the one the machine uses, as well as the hostname
kubeadm reset 
kubeadm init --control-plane-endpoint "127.0.0.1:6444" --apiserver-advertise-address=10.0.0.10  --pod-network-cidr=10.2.0.0/16 --service-cidr=10.16.0.0/12 --upload-certs
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl -n kube-system create secret generic hcloud --from-literal=token=...
helm repo add hcloud https://charts.hetzner.cloud
helm install hccm hcloud/hcloud-cloud-controller-manager -n kube-system --set networking.enabled=true --set networking.clusterCIDR=10.2.0.0/16

# joining the cluster
kubeadm reset 
kubeadm join 127.0.0.1:6444 --token ... \
  --discovery-token-ca-cert-hash sha256:... \
  --control-plane --certificate-key ... \
  --apiserver-advertise-address 10.70.0.11

export KUBECONFIG=/etc/kubernetes/admin.conf

# after all nodes are joined
## allow scheduling workloads on the control plane
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-

## restart coredns, so it spreads across nodes (it will initially run only on 0, which is bad from HA perspective)
kubectl rollout -n kube-system restart deployment coredns
```

After the cluster is set up, update the secret in `secrets/darkmore-kubeconfig.age` with the contents of `/etc/kubernetes/admin.conf` from one of the nodes, with the `server` key updated to match the tailscale address of one of them (and port `6443`).
