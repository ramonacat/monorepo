{ pkgs, ... }: {
  config = {
    environment.systemPackages = with pkgs; [ openiscsi ];
  };
}
