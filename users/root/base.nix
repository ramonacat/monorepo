_: {
  config = {
    users.users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHW4PIqcucwZdFj5u9aMhLj/ernBFV24PyHuspHwh3LT ramona@moonfall"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQpyHTzwWTi5x/532hbbsMLCbRBE+icEf1LHNLOyJKF root@hallewell"
      ];
    };
  };
}
