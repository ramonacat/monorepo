_: {
  # This hack is recommended by 1password. By using `ssh.exe` we're able to use host's ssh agent (which is 1password).
  programs.git.extraConfig.core.sshCommand = "ssh.exe";

  # These options allow to use the ssh key stored in 1password for signing commits
  programs.git.extraConfig = {
    user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwvvTZjbvSDU7oK4B5VfsEBann7ktIVj5ShTWoFaGwH";
    gpg.format = "ssh";
    "gpg \"ssh\"".program = "/mnt/c/Users/ja/AppData/Local/1Password/app/8/op-ssh-sign.exe";
    commit.gpgsign = true;
  };
}
