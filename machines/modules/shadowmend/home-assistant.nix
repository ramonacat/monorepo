{ config, pkgs, lib, ... }:
{
  config = {

    services.home-assistant = {
      enable = true;
      extraComponents = [
        "default_config"
        "met"
        "radio_browser"
        "deconz"
        "zha"
        "backup"
        "automation"
        "device_automation"
      ];
      config = {
        default_config = { };
        automation = { };
      };
    };
  };
}
