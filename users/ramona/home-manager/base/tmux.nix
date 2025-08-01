{pkgs, ...}: {
  config = {
    programs.tmux = {
      enable = true;
      clock24 = true;
      newSession = true;
      baseIndex = 1;
      mouse = true;
      keyMode = "vi";
      prefix = "C-space";
      plugins = with pkgs.tmuxPlugins; [
        sensible
        {
          plugin = kanagawa;
          extraConfig = ''
            set -g @kanagawa-theme 'dragon'
            set -g @kanagawa-plugins 'time'
            set -g @kanagawa-show-powerline true
            set -g @kanagawa-ignore-window-colors true
          '';
        }
      ];
      extraConfig = ''
        # setup vim-like navigation/resizing
        bind -N "Select pane to the left of the active pane" h select-pane -L
        bind -N "Select pane below the active pane" j select-pane -D
        bind -N "Select pane above the active pane" k select-pane -U
        bind -N "Select pane to the right of the active pane" l select-pane -R

        bind -r -N "Resize the pane left by 1" \
          C-h resize-pane -L 1
        bind -r -N "Resize the pane down by 1" \
          C-j resize-pane -D 1
        bind -r -N "Resize the pane up by 1" \
          C-k resize-pane -U 1
        bind -r -N "Resize the pane right by 1" \
          C-l resize-pane -R 1
      '';
    };
  };
}
