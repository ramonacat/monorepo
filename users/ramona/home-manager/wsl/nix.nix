{
  pkgs,
  flake,
  ...
}: {
  config = {
    nix = {
      package = pkgs.nix;
      gc.automatic = true;
      settings = {
        trusted-public-keys = ["nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="];
        substituters = let
          hosts = flake.hosts.builds-hosts;
          ssh-keys = import ../../../../data/ssh-keys.nix;
        in
          builtins.map (x: "ssh://nix-ssh@${x}?base64-public-host-key=${ssh-keys.machines."${x}-rsa"}") hosts;
      };
    };
  };
}
