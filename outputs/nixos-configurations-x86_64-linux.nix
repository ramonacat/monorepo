{
  pkgs,
  inputs,
  flake,
  ...
}:
let
  machines = pkgs.lib.mapAttrsToList (hostname: _: hostname) (builtins.readDir ../machines);
in
pkgs.lib.genAttrs machines (
  hostname:
  inputs.nixpkgs.lib.nixosSystem {
    inherit pkgs;
    system = "x86_64";
    specialArgs = {
      inherit inputs flake;
    };
    modules = [
      (../machines + "/${hostname}")
    ];
  }
)
// pkgs.lib.mergeAttrsList (
  let
    k8s-config = (builtins.fromJSON (builtins.readFile ../terraform/k8s-nodes.json)).darkmore;
  in
  map (
    node:
    let
      set-name = "darkmore";
    in
    {
      "${node.hostname}" = inputs.nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64";
        specialArgs = {
          inherit inputs flake;
        };
        modules = [
          (../machine-templates + "/${set-name}")
          {
            config = {
              ramona = {
                kubernetes = {
                  inherit (node) ip hostname;

                  is-control-plane = node.isControlPlane;
                  pod-cidr = k8s-config.podCidr;
                  host-pod-cidr = node.podCidr;
                  all-nodes = map (node: {
                    inherit (node) ip hostname;
                    is-control-plane = node.isControlPlane;
                  }) k8s-config.nodes;
                };
              };
            };
          }
        ];
      };
    }
  ) k8s-config.nodes
)
