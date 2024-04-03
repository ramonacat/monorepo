{
  config,
  pkgs,
  ...
}: {
  config = {
    programs.regreet.enable = true;
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.cage}/bin/cage ${config.programs.regreet.package}/bin/regreet";
        };
      };
    };

    environment.etc."greetd/environments".text = ''
      sway
      nu
      bash
    '';
  };
}
