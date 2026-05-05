_: let
  mutable-npm-path = "~/.mutable_nodejs_modules";
in {
  home.file.".npmrc".text = ''
    prefix = ${mutable-npm-path}
  '';
  home.sessionPath = ["${mutable-npm-path}/bin/"];
}
