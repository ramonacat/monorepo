{pkgs, ...}: {
  imports = import ../../../libs/nix/nix-files-from-dir.nix ./base;
  config = {
    systemd.user.enable = true;
    home = {
      homeDirectory = "/home/ramona";
      username = "ramona";
      stateVersion = "21.05";
      packages = with pkgs; [
        agenix
        atop
        jq
        ripgrep
        unzip
        _1password-cli
        rustup
        irssi
        github-cli
        htop
        iftop
        strace
      ];
    };

    programs = {
      home-manager = {
        enable = true;
      };

      gh = {
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
