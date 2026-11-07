{ config, ... }:
let
  mutable-npm-path = "~/.mutable_nodejs_modules";
in
{
  age.secrets.cli-tokens.file = ../../../../secrets/cli-tokens.age;

  home = {
    file.".npmrc".text = ''
      prefix = ${mutable-npm-path}
      @ramona:registry=https://code.ramona.fun/api/packages/ramona/npm
      //code.ramona.fun/api/packages/ramona/npm/:_authToken=''${FORGEJO_TOKEN}
    '';
    sessionPath = [ "${mutable-npm-path}/bin/" ];
    sessionVariablesExtra = ''
      set -a
      eval "$(cat ${config.age.secrets.cli-tokens.path})" >/dev/null
      set +a
    '';
  };
}
