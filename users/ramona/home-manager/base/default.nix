{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./git.nix
    ./ssh.nix
    ./tmux.nix
  ];
  config = {
    systemd.user.enable = true;
    home = {
      homeDirectory = "/home/ramona";
      username = "ramona";
      stateVersion = "21.05";
      # this check can fail sometimes on unstable, as home-manager and nixpkgs don't upgrade in perfect sync
      enableNixpkgsReleaseCheck = false;
      packages = with pkgs; [
        inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default

        atop
        htop
        iftop
        irssi
        jq
        ripgrep
        rustup
        strace
        unzip
      ];
    };

    programs = {
      home-manager = {
        enable = true;
      };

      bash = {
        enable = true;
      };

      direnv.enable = true;

      starship = {
        enable = true;
        enableBashIntegration = true;
      };
    };
  };
}
