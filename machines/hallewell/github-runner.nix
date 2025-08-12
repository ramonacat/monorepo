_: {
  imports = [
    ../../modules/github-runner.nix
  ];
  config = {
    services.ramona.monorepo-github-runner = {
      enable = true;
      count = 4;
    };
  };
}
