rec {
  devices = {
    angelsin = "YI4CWVN-XMQR6B7-EZE5SP5-OBLNFOF-Q7HJ46X-XXGSYSB-DMJ64RB-UGGBCQP";
    angelsin-linux = "4XIQFIS-GOASMNU-ER2477E-3APVOHX-JMQPXKE-FPBAFOP-3H4HEK3-SY3KLAG";
    evillian = "TWYTK4N-3MWWULX-I5CG3BL-ICAOT4E-T34YDFW-F2QTLDV-YLYJR6N-VLC4KAD";
    graves = "GC5LOKH-YAYT5HD-FAW64XV-KQAGSWD-I7UOL2Q-2AWKLVC-MXHQD5X-SRZ7ZAN";
    hallewell = "WUOOFWA-FG7VWPF-HSCI7OP-ZBQSWCC-6OTD7FA-7CBP463-F7RI4KU-U57ZDAT";
    moonfall = "RNSUEIE-ZBLKXNS-HWIQ55X-IS4CELE-NA6UFXO-VBWN64L-PBIPSVE-R7FQYQL";
    shadowsoul = "7NXR3IB-O4X73UQ-YVL6C5D-WEVRNVZ-5R6MIZH-P73UNPX-LRNJV6K-UEJNUQS";
  };
  settings = let
    paths = import ./paths.nix;
  in {
    hallewell = {
      user = "nas";
      folders = {
        trnsmsn-dls = {
          path = "${paths.hallewell.nas-root}/dls/";
          type = "receiveonly";
        };
        shared = {
          path = "${paths.hallewell.nas-share}/ramona/shared";
        };
      };
      dataDir = "${paths.hallewell.nas-root}/syncthing/data/";
      configDir = "${paths.hallewell.nas-root}/syncthing/config/";
    };
    shadowsoul = {
      user = "transmission";
      folders = {
        trnsmsn-dls = {
          path = paths.shadowsoul.transmission-downloads;
          type = "sendonly";
        };
      };
    };
    default = {
      user = "ramona";
      folders = {
        shared = {
          path = paths.common.ramona-shared;
        };
      };
    };
  };
  topology = with devices; {
    "trnsmsn-dls" = {inherit hallewell shadowsoul;};
    "shared" = {inherit graves angelsin evillian hallewell moonfall angelsin-linux;};
  };
}
