_: {
  config = {
    nix = {
      optimise.automatic = true;
      gc.automatic = true;
      settings = {
        trusted-public-keys = ["nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="];
        substituters = ["https://hallewell.ibis-draconis.ts.net/nix-serve/"];
      };
    };
  };
}
