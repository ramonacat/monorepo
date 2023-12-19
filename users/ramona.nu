$env.GPG_TTY = (tty)
gpg-connect-agent updatestartuptty /bye | ignore

$env.SSH_AUTH_SOCK = (gpgconf --list-dirs agent-ssh-socket)
$env.EDITOR = "vim";

$env.config = {
    show_banner: false
}