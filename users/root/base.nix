_: {
  config = {
    users.users.root = {
      openssh.authorizedKeys.keys = let
        ssh-keys = import ../../data/ssh-keys.nix;
      in [
        ssh-keys.ramona.default
      ];
    };
  };
}
