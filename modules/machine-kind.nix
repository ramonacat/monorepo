{lib, ...}: {
  options = {
    ramona.machine = lib.mkOption {
      type = with lib.types;
        submodule {
          options = {
            type = lib.mkOption {type = enum ["server" "workstation"];};
            visibility = lib.mkOption {type = enum ["public" "private"];};
          };
        };
    };
  };
}
