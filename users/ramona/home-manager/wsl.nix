{pkgs, ...}: {
  config = {
    programs.bash = {
      bashrcExtra = ''
        export SSH_AUTH_SOCK=''${HOME}/.ssh/agent.sock
        ss -a | grep -q $SSH_AUTH_SOCK
        if [ $? -ne 0   ]; then
            rm -f ''${SSH_AUTH_SOCK}
            ( ${pkgs.util-linux}/bin/setsid ${pkgs.socat}/bin/socat UNIX-LISTEN:''${SSH_AUTH_SOCK},fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
        fi
      '';
    };

    nix = {
      package = pkgs.nix;
      gc.automatic = true;
      settings = {
        trusted-public-keys = ["nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="];
        substituters = ["http://hallewell:5001/"];
      };
    };
  };
}
