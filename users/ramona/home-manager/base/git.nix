_: {
  config = {
    programs.git = {
      enable = true;
      userName = "Ramona Łuczkiewicz";
      userEmail = "ja@agares.info";
      maintenance = {
        enable = true;
        repositories = ["/home/ramona/Projects/monorepo/" "/home/ramona/Projects/ligeia"];
      };
      aliases = {
        st = "status -sb";
        cleanbr = "! git branch -d `git branch --merged | grep -v '^*\\|main\\|master\\|staging\\|devel'`";
      };
      extraConfig = {
        push = {
          autoSetupRemote = true;
        };
        init = {
          defaultBranch = "main";
        };
      };
    };
  };
}
