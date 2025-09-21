{
  pkgs,
  inputs,
  ...
}: {
  config = {
    home-manager = {
      users.ramona = import ../home-manager/workstation {inherit pkgs inputs;};
    };
  };
}
