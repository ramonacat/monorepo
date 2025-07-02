_: {
  config = {
    programs.nixvim.config = {
      globals = {
        mapleader = " ";
      };
      opts = {
        tabstop = 4;
        expandtab = true;
        softtabstop = 4;
        shiftwidth = 4;
        relativenumber = true;
        autoread = true;
      };
    };
  };
}
