_: {
  config = {
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserServices = true;
      enableUserSlices = true;
    };
  };
}
