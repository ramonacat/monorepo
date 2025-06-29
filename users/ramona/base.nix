{
  lib,
  pkgs,
  ...
}: {
  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.users.ramona = import ./home-manager.nix {inherit pkgs lib;};

    users.users.ramona = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "docker" "cdrom" "audio" "adbusers"];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCatH7XWmY6oZPSe3woP2swvJ4/stZrpaVWNg6FMcs87xEtCr/sIkj/rm41gD6F3k3Z6jhxqBKgZcr45aW07xlB//KfYs3kb0PYDsn3KrwCPBjHwRypuPvyagCUDAbD9wnhpEr9iHEbhW2yNEDC5E1c3ak/fNjewCZMpqo645gQ6siFAnwEnqTQR0lF3B/hdmAA/j+efQ3ghjiI6+O3uQ0o5coCNa4tCrq3yqsyA7eI0jhT1Ij8SE54ren3dwndq1JoGNg7DCtozl3fCgHVUrdWeW2kcB1A/Ta+jcmcB10Rv9ZevU2wYvZIEYXG1hSjM8Zrr7JwAcXkG/mb3lGnYnU49YxNqT4vwD0ZyY8d5M9Hvw065+y7Y45+/ScevmIGn/fn/9TbZHdPdSKM1UFMICUctT6VH6ShhEkbiQ38E3GnA1n3mnsOnxaBT5hVJxr13yLV8ULU/8not6SMU/3xP2rZj6JP7xtHJP/29Nd4N7gm6adz3wbS1aRJosVr3ZbA1qTaB/m4EBRTfNYtifUbdQkFbrnlNmVNb5ixhS1ZLZq4aRPmp6MH034sQ9HZSrtMMSO5B9TXHCb3zxexR6BBtIjZHBqwuu3krMWh9kOW3wNFWmEWdy5vLUcVVoXSaGqICQwG/HOKGNdzGumFDnPfvayVVCxu67s2b82oTtkbd+mjMQ== openpgp:0xCF7158EB" # nitrokey
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKK5e1b1wQLyZ0RByYmhlKj4Kksv4dvnwTowDPaGsq4D openpgp:0x7688871E" # nitrokey 3
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFwrLwnv2MBsa3Isr54AyFBBeFxMRF3U+lkdU5+ECv9 ramona@caligari" # caligari
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwvvTZjbvSDU7oK4B5VfsEBann7ktIVj5ShTWoFaGwH ramona@moonfall" # WSL machines
      ];
      shell = pkgs.bash;
    };
  };
}
