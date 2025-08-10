{lib, ...}: {
  options = {
    ramona.roles = lib.mkOption {
      type = with lib.types;
        listOf string;
    };
  };
}
