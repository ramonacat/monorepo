{
  flake,
  config,
  ...
}: {
  config = {
    age.secrets.nix-serve-ssh-key.file =
      ../../secrets/nix-serve-ssh-key.age;
    nix = {
      optimise.automatic = true;
      gc.automatic = true;
      settings = {
        trusted-public-keys = ["nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="];
        substituters = let
          hosts = flake.hosts.builds-hosts;
          ssh-keys = import ../../data/ssh-keys.nix;
        in
          builtins.map (x: "ssh://nix-ssh@${x}?ssh-key=${config.age.secrets.nix-serve-ssh-key.path}&base64-public-host-key=${ssh-keys.machines."${x}-rsa"}") hosts;
        fallback = true;
      };
    };
  };
}
