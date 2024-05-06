{pkgs, ...}: {
  config = {
    environment.systemPackages = [pkgs.ramona.rat];
    environment.etc."ramona/rat/config.json".text = builtins.toJSON {server_address = "http://hallewell:8438/";};
  };
}
