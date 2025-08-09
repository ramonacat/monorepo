_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ../../users/ramona/installed
    ../../users/root/installed

    ./nginx

    ./github-runner.nix
    ./networking.nix
    ./nix-serve.nix
  ];
  config = {
    swapDevices.file = {
      size = 8192;
      device = "/swapfile";
    };
  };
}
