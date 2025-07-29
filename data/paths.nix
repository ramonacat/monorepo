{
  hallewell = rec {
    nas-root = "/mnt/nas3";
    nas-share = "${nas-root}/data";
    tailscale-www-root = "/var/www/hallewell.ibis-draconis.ts.net/";
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
