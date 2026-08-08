{ config, pkgs, userName, userEmail, hostName, ... }:

{
  home.packages = with pkgs; [
    yazi
    neovim
    lazygit
    fastfetch
    btop
    go-musicfox
	codex
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = userName;
      email = userEmail;
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      c = "clear";
	  cx = "codex";
      ll = "ls -l";
      la = "ls -la";
      lg = "lazygit";
      ff = "fastfetch";
      vim = "nvim";
      nrs = "sudo nixos-rebuild switch --flake ~/Documents/nix-dotfiles#${hostName}";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    initContent = ''
      PS1="%F{blue}%~%f"$'\n'"%F{green}➜ %f"

      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';

    profileExtra = ''
      if uwsm check may-start; then
        exec uwsm start default
      fi
    '';
  };
}