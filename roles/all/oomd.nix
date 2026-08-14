_: {
  config = {
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = false;
      enableUserSlices = true;
    };
  };
}
