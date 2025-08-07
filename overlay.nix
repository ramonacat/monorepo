architecture: {
  pkgs,
  crane-lib,
  inputs,
  packages,
}: (_: prev: {
  agenix = inputs.agenix.packages."${architecture}-linux".default;

  ramona =
    prev.lib.mapAttrs' (name: value: {
      name = "${name}";
      value =
        (value {
          inherit pkgs;
          craneLib = crane-lib;
        }).package;
    })
    packages;
})
