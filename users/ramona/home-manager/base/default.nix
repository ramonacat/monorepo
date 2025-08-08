{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nixvim.homeModules.nixvim] ++ import ../../../../libs/nix/nix-files-from-dir.nix ./.;
  config = {
    systemd.user.enable = true;
    home = {
      homeDirectory = "/home/ramona";
      username = "ramona";
      stateVersion = "21.05";
      packages = with pkgs; [
        inputs.agenix.packages."${pkgs.system}".default
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
