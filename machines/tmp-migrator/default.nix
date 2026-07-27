{ pkgs, ... }: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public
  ];
  config = {
    networking.hostName = "tmp-migrator";
    environment.systemPackages = with pkgs; [
      rclone
      tmux
    ];
  };
}
