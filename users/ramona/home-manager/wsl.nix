_: {
  config = {
    programs.git = {
      extraConfig = {
        core = {
          sshCommand = "ssh.exe";
        };
      };
    };
    programs.bash = {
      shellAliases = {
        ssh = "ssh.exe";
      };
    };
  };
}
