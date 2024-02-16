{ config, pkgs, lib, ... }:
{
  config = {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "sway";
        };
      };
    };
  };
}
