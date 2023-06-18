{ config, pkgs, lib, ... }:
{
  config = {
    users.users.ramona = {
      extraGroups = [ "libvirtd" ];
    };

    home-manager.users.ramona = {
      wayland.windowManager.sway = {
	extraConfigEarly = ''
	'';
        config = {
          output = {
            "Dell Inc. DELL U2415 7MT0186418CU" = {
              pos = "0 0";
              bg = "/dev/null fill #E40303";
            };
            "LG Electronics LG ULTRAFINE 302MAUAEEJ14" = {
              scale = "1.5";
              pos = "1920 0";
              bg = "/dev/null fill #FF8C00";
            };
            "Dell Inc. DELL U2415 XKV0P9C334FS" = {
              pos = "4480 0";
              bg = "/dev/null fill #FFED00";
            };

            "Dell Inc. DELL U2723QE HRJH2P3" = {
              scale = "1.5";
              pos = "0 1440";
              bg = "/dev/null fill #008026";
            };
            "Dell Inc. DELL U2720Q JKPQT83" = {
              scale = "1.5";
              pos = "2560 1440";
              bg = "/dev/null fill #24408E";
            };
            "Dell Inc. DELL U2723QE 6MMF1P3" = {
              scale = "1.5";
              pos = "5120 1440";
              bg = "/dev/null fill #732982";
            };
          };
        };
      };
    };
  };
}
