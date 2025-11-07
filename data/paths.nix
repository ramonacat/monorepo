{
  hallewell = rec {
    nas-root = "/mnt/nas3";
    nas-share = "${nas-root}/data";

    paperless = "${nas-root}/paperless";
    jellyfin = "${nas-root}/jellyfin";
    dls = "${nas-root}/dls";
  };
  shadowsoul = {
    transmission-downloads = "/var/lib/transmission/Downloads";
  };
  common = {
    syncthing-data = "/home/ramona/.syncthing-data";
    syncthing-config = "/home/ramona/.config/syncthing";
    ramona-shared = "/home/ramona/shared";
  };
}
