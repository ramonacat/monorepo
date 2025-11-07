{pkgs, ...}: {
  config = {
    systemd.services.autounrar-dls = let
      paths = import ../../data/paths.nix;
    in {
      script = "
        find ${paths.hallewell.dls} -name '*.rar' -execdir ${pkgs.unrar}/bin/unrar -u x {} \\;
      ";
    };

    systemd.timers.autounrar-dls = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* *:*:*";
        Unit = "autounrar-dls.service";
      };
    };
  };
}
