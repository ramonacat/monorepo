architecture: {
  inputs,
  packages,
}: (_: prev: {
  agenix = inputs.agenix.packages."${architecture}-linux".default;

  ramona =
    prev.lib.mapAttrs' (name: value: {
      name = "${name}";
      value = value.package;
    })
    packages.apps;
})
