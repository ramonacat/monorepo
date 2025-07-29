_: {
  config = {
    services.telegraf.extraConfig.inputs.file = let
      paths = import ../../data/paths.nix;
    in {
      files = ["${paths.hallewell.tailscale-www-root}/builds/*-closure"];
      data_format = "value";
      data_type = "string";
      name_override = "latest_closure";
      file_tag = "filename";
    };
  };
}
