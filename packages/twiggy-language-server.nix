{pkgs, ...}: rec {
  package = let
    stage1 = pkgs.stdenvNoCC.mkDerivation {
      pname = "twiggy-language-server";
      version = "v26.4.1";
      src = pkgs.fetchFromGitHub {
        owner = "moetelo";
        repo = "twiggy";
        rev = "v26.4.1";
        hash = "sha256-AfJV4r3a6dYSxfMbuheGZfBH+PHUTzS+ExfM4V1W1Sg=";
      };
      nativeBuildInputs = with pkgs; [bun];
      buildPhase = ''
        runHook preBuild

        bun install

        cd packages/language-server/
        bun run build

        mkdir -p $out/bin
        rm -r ../../node_modules/.cache/
        rm ../../node_modules/.bun/vscode-languageclient@9.0.1/node_modules/vscode-languageclient/lib/node/terminateProcess.sh
        cp -r ../../node_modules/ $out/
        cp dist/index.js $out/bin/twiggy-language-server
        sed -i -- "s#\.\./\.\./node_modules#../node_modules#g" $out/bin/twiggy-language-server
        chmod +x $out/bin/twiggy-language-server

        runHook postBuild
      '';
      outputHash = "sha256-upzrrne9lN+XlgQpTepk259ZB7uG2MJJZWUCOntbD8U=";
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };
    hack = pkgs.writeText "hack.js" "global.__DEBUG__ = false;";
  in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "twiggy-language-server";
      version = "v26.4.1";
      src = stage1;
      buildPhase = ''
        mkdir -p $out/bin/
        cp -r ./node_modules/ $out/node_modlues/
        cp ./bin/twiggy-language-server $out/bin/.twiggy-language-server-original.js
        echo "#!/usr/bin/env bash" > $out/bin/twiggy-language-server
        echo "${pkgs.nodejs_24}/bin/node --require ${hack} $out/bin/.twiggy-language-server-original.js -- \"\$@\"" >> $out/bin/twiggy-language-server
        chmod +x $out/bin/twiggy-language-server
      '';
    };
  coverage = pkgs.runCommand "${package.name}-coverage" {} "echo > $out";
  checks = {};
}
