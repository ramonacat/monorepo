{pkgs, ...}: rec {
  package = pkgs.buildNpmPackage {
    pname = "twiggy-language-server";
    version = "v26.4.1";
    src = pkgs.fetchFromGitHub {
      owner = "moetelo";
      repo = "twiggy";
      rev = "v26.4.1";
      hash = "";
    };
  };
  coverage = pkgs.runCommand "${package.name}-coverage" {} "echo > $out";
  checks = {};
}
