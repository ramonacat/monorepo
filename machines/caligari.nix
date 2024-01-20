{ config, pkgs, lib, ... }:
{
  config = { 
    services.fail2ban.enable = true;
  };
}
