{ config, pkgs, lib, ... }:
{
  config = {
    sound.enable = true;
    sound.extraConfig = ''
      defaults.pcm.card 3
      defaults.ctl.card 3
    '';
  };
}
