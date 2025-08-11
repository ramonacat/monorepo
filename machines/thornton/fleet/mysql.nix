_: {
  config = {
    services.mysql = {
      ensureUsers = [
        {
          name = "fleet";
          ensurePermissions = {
            "fleet.*" = "ALL PRIVILEGES";
          };
        }
      ];
      ensureDatabases = ["fleet"];
    };
  };
}
