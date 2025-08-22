_: {
  config = {
    nix.sshServe = {
      enable = true;
      keys = let ssh-keys = import ../../data/ssh-keys.nix; in ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILecswZslobQWCXfE7cR7yfb7WS23ItNji68ucS7HJ91" ssh-keys.ramona.default];
    };
  };
}
