{lib, ...}: {
  options = {
    ramona.machine = lib.mkOption {
      type = with lib.types;
        submodule {
          options = {
            type = lib.mkOption {type = enum ["server" "workstation"];};
            hasPublicIP = lib.mkOption {type = bool;};
          };
        };
    };
  };
}
