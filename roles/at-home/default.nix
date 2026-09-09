{
  ...
}:
{
  imports = [
    ./nix.nix
  ];
  config = {
    ramona.machine.roles = [ "at-home" ];
  };
}
