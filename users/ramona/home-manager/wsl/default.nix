{ pkgs, ... }: {
  imports = [
    ./updates

    ./nix.nix
    ./ssh-agent-redirection.nix
  ];
  config = {
    home.packages = with pkgs; [ ramona.r ];
  };
}
