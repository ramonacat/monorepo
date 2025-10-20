_: {
  config = {
    programs.git = {
      enable = true;
      maintenance = {
        enable = true;
        repositories = ["/home/ramona/Projects/monorepo/"];
      };
      settings = {
        alias = {
          st = "status -sb";
          cleanbr = "! git branch -d `git branch --merged | grep -v '^*\\|main\\|master\\|staging\\|devel'`";
        };
        push = {
          autoSetupRemote = true;
        };
        init = {
          defaultBranch = "main";
        };
        user = {
          name = "Ramona Łuczkiewicz";
          email = "ramona@luczkiewi.cz";
        };
      };
    };
  };
}
