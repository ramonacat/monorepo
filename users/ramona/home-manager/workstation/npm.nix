{ config, ... }:
let
  mutable-npm-path = "~/.mutable_nodejs_modules";
in
{
  age.secrets.cli-tokens.file = ../../../../secrets/cli-tokens.age;

  home = {
    file.".npmrc".text = ''
      prefix = ${mutable-npm-path}
      @ramonacat:registry=https://npm.pkg.github.com
      @ramona:registry=https://code.ramona.fun/api/packages/ramona/npm
      //code.ramona.fun/api/packages/ramona/npm/:_authToken=''${FORGEJO_TOKEN}
      //npm.pkg.github.com/:_authToken=''${GITHUB_TOKEN}
    '';
    sessionPath = [ "${mutable-npm-path}/bin/" ];
    sessionVariablesExtra = ''
      set -a
      eval "$(cat ${config.age.secrets.cli-tokens.path})" >/dev/null
      set +a
    '';
  };
}
