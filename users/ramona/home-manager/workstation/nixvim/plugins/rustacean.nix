_: {
  config = {
    programs.nixvim.plugins.rustaceanvim = {
      enable = true;
      settings = {
        default_settings = {
          rust-analyzer = {
            assist.preferSelf = true;
            cargo = {
              buildScripts.enable = true;
            };
            check = {
              command = "clippy";
            };
            inlayHints = {
              lifetimeElisionHints.enable = "always";
              closureCaptureHints.enable = "always";
              closureReturnTypeHints.enable = "always";
            };
            procMacro.enable = true;
          };
        };
      };
    };
  };
}
