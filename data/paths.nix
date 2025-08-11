{
  hallewell = rec {
    nas-root = "/mnt/nas3";
    nas-share = "${nas-root}/data";
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
