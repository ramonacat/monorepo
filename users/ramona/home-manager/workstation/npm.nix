{ config, ... }:
let
  mutable-npm-path = "~/.mutable_nodejs_modules";
in
{
  age.secrets.github-pat-npm-registry.file = ../../../../secrets/github-pat-npm-registry.age;

  home = {
    file.".npmrc".text = ''
      prefix = ${mutable-npm-path}
      @ramonacat:registry=https://npm.pkg.github.com
    '';
    sessionPath = [ "${mutable-npm-path}/bin/" ];
    sessionVariablesExtra = ''
      export GITHUB_TOKEN=$(cat ${config.age.secrets.github-pat-npm-registry.path})
    '';
  };
}
