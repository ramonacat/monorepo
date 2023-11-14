$env.GPG_TTY = (tty)
gpg-connect-agent updatestartuptty /bye > /dev/null

$env.SSH_AUTH_SOCK = (gpgconf --list-dirs agent-ssh-socket)