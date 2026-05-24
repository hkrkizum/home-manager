{
  pkgs,
  username,
  homeDirectory,
  toolBin,
  zedBin,
  vscodeBin,
  gcmPath,
  ...
}:

{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # ----------------------------
  # 基本パッケージ
  # ----------------------------
  home.packages = with pkgs; [
    vim
    curl
    wget
    unzip
    zip
    jq
    tree
    dust
    procs
    btop

    # nix
    nil
    nixd
    nixfmt

    # version / environment managers
    volta
    pixi
    rig

    # containers
    podman
    podman-compose
    lazydocker

    # GitHub CLI
    gh
    lazygit

    # Network tools
    bind

    # build tools
    gnumake
    gnutar
  ];

  # ----------------------------
  # Git
  # ----------------------------
  programs.git = {
    enable = true;

    settings = {
      user.name = "Hikaru Koizumi";
      user.email = "20899973+hkrkizum@users.noreply.github.com";

      credential.helper = gcmPath;

      init.defaultBranch = "main";
      pull.rebase = false;
      pull.ff = true;
      merge.ff = false;
      push.autoSetupRemote = true;
      core.editor = "vim";
      color.ui = true;

      alias = {
        st = "status -sb";
        co = "checkout";
        cb = "checkout -b";
        br = "branch";
        cm = "commit -m";
        lg = "log --oneline --graph --decorate --all";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  # ----------------------------
  # zsh
  # ----------------------------
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      extended = true;
      share = true;
    };

    shellAliases = {
      ll = "eza -al --group-directories-first --icons=auto";
      la = "eza -a --group-directories-first --icons=auto";
      lt = "eza --tree --level=2 --icons=auto";
      ls = "eza --group-directories-first --icons=auto";

      cat = "bat";
      batcat = "bat";
      find = "fd";

      grep = "rg";
      v = "vim";

      dc = "podman compose";
      d = "podman";
    };

    initContent = ''
      # Volta
      export VOLTA_HOME="$HOME/.volta"
      export PATH="$VOLTA_HOME/bin:$PATH"

      # Pixi global bin
      export PATH="$HOME/.pixi/bin:$PATH"

      # Podman alias compatibility
      alias docker=podman

      # Bat config
      export BAT_PAGER="less -RF"

      # function y() {
      #   local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
      #   command yazi "$@" --cwd-file="$tmp"
      #   IFS= read -r -d "" cwd < "$tmp"
      #   [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
      #   command rm -f -- "$tmp"
      # }
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = pkgs.lib.concatStrings [
        "[░▒▓](#a3aed2)"
        "$os"
        "$username"
        "[](bg:#769ff0 fg:#a3aed2)"
        "$directory"
        "[](fg:#769ff0 bg:#394260)"
        "$git_branch"
        "$git_status"
        "[](fg:#394260 bg:#212736)"
        "$python"
        "$pixi"
        "$rlang"
        "$nix_shell"
        "$nodejs"
        "$bun"
        "$rust"
        "$golang"
        "$php"
        "[ ](fg:#212736)"
        "$fill"
        "$status"
        "$cmd_duration"
        "$jobs"
        "$time"
        "\n$character"
      ];

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      fill = {
        symbol = " ";
      };

      os = {
        disabled = false;
        format = "[ $symbol]($style)";
        style = "bg:#a3aed2 fg:#090c0c";
        symbols = {
          Windows = "";
          Linux = "󰌽";
          Ubuntu = "󰕈";
          Debian = "󰣚";
          NixOS = "󱄅";
          Macos = "󰀵";
          Unknown = "󰈔";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:#a3aed2 fg:#090c0c";
        style_root = "bg:#a3aed2 fg:#ff5555";
        format = "[ $user ]($style)";
      };

      directory = {
        format = "[ $path ]($style)";
        style = "bg:#769ff0 fg:#e3e5e5";
        truncation_length = 3;
        truncate_to_repo = false;
      };

      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };

      git_status = {
        style = "bg:#394260 fg:#769ff0";
        format = "[$all_status$ahead_behind ]($style)";
      };

      python = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol $version( ($virtualenv)) ](fg:#769ff0 bg:#212736)]($style)";
      };

      pixi = {
        symbol = "󰏗";
        style = "bg:#212736";
        format = "[[ $symbol $version( ($environment)) ](fg:#769ff0 bg:#212736)]($style)";
      };

      rlang = {
        symbol = "󰟔";
        style = "bg:#212736";
        format = "[[ $symbol $version ](fg:#769ff0 bg:#212736)]($style)";
      };

      nix_shell = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol $state ](fg:#769ff0 bg:#212736)]($style)";
        heuristic = true;
        impure_msg = "!";
        pure_msg = "✓";
        unknown_msg = "?";
      };

      nodejs = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      bun = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      status = {
        disabled = false;
        symbol = "x";
        format = "[$symbol$status]($style) ";
      };

      cmd_duration = {
        min_time = 1000;
        format = "[$duration]($style) ";
      };

      jobs = {
        symbol = "jobs:";
        format = "[$symbol$number]($style) ";
      };

      time = {
        disabled = false;
        style = "bg:#1d2230";
        format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
        time_format = "%H:%M:%S";
      };
    };
  };

  # ----------------------------
  # Podman (rootless) config files
  # ----------------------------
  xdg.configFile."containers/registries.conf".text = ''
    [registries.search]
    registries = ['docker.io']
  '';

  xdg.configFile."containers/policy.json".text = builtins.toJSON {
    default = [ { type = "insecureAcceptAnything"; } ];
  };

  xdg.configFile."containers/storage.conf".text = ''
    [storage]
    driver = "overlay"
  '';

  # ----------------------------
  # Modern CLI tools
  # ----------------------------
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat = {
    enable = true;
  };

  programs.fd = {
    enable = true;
  };

  programs.ripgrep = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 10000;
    keyMode = "vi";
    baseIndex = 0;
    escapeTime = 0;
    extraConfig = ''
      # ペイン番号も1から
      set -g pane-base-index 0

      # ステータスバー
      set -g status-position bottom
      set -g status-style "bg=colour235,fg=colour246"

      # マウスでペインサイズ変更・選択を有効化
      set -g mouse on
    '';
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
    settings = {
      mgr = {
        show_hidden = true;
      };
    };
    # You can omit this if you use overlays
    # package = yazi.packages.${system}.default.override {
    #   _7zz = pkgs._7zz-rar; # Support for RAR extraction
    # };
  };

  programs.btop.enable = true;
  programs.tealdeer.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.neovim = {
    enable = true;
    # defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    # extraPackages = with pkgs; [
    #   lua-language-server
    #   nodePackages.typescript-language-server
    #   bash-language-server
    #   vim-language-server
    #   emmet-language-server
    #   gopls
    #   nil
    #   pyright
    #   stylua
    #   nixfmt-rfc-style
    #   skkDictionaries.l
    # ];
    plugins = with pkgs.vimPlugins; [ lazy-nvim ];
  };

  # ----------------------------
  # LazyGit のカスタムコマンドで Claude Code を呼び出すための設定
  # ----------------------------
  # ラッパースクリプトを配置
  # home.file.".local/bin/claude-commit" = {
  #   executable = true;
  #   text = ''
  #     #!/bin/bash
  #     set -euo pipefail

  #     # Nix環境のPATHを読み込む
  #     if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  #       . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  #     fi
  #     export PATH="$HOME/.nix-profile/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"

  #     if git diff --cached --quiet; then
  #       echo "ステージされた変更がありません"
  #       sleep 1
  #       exit 1
  #     fi

  #     DIFF_FILE=$(mktemp /tmp/claude-commit-diff.XXXXXX)
  #     git diff --cached > "$DIFF_FILE"
  #     STAT=$(git diff --cached --stat)

  #     claude \
  #       --system-prompt "あなたはGitコミットメッセージの作成を支援するアシスタントです。
  #     ユーザーとの対話を通じて適切なコミットメッセージを作成してください。
  #     Conventional Commits形式を使い、ユーザーが承認したら最終メッセージを /tmp/claude-commit-msg.txt に書き出してください。" \
  #       -p "以下のGit差分に対するコミットメッセージを一緒に考えましょう。

  #     ### 変更の統計:
  #     $STAT

  #     ### 差分の内容:
  #     $(cat "$DIFF_FILE")

  #     まず差分を分析して、コミットメッセージの候補を提案してください。"

  #     rm -f "$DIFF_FILE"

  #     if [ -f /tmp/claude-commit-msg.txt ]; then
  #       MSG=$(cat /tmp/claude-commit-msg.txt)
  #       rm -f /tmp/claude-commit-msg.txt
  #       if [ -n "$MSG" ]; then
  #         echo ""
  #         echo "━━━ 以下のメッセージでコミットします ━━━"
  #         echo "$MSG"
  #         echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  #         read -rp "実行しますか? [Y/n] " confirm
  #         confirm=''${confirm:-Y}
  #         if [[ "$confirm" =~ ^[Yy]$ ]]; then
  #           git commit -m "$MSG"
  #           echo "コミット完了!"
  #         else
  #           echo "キャンセルしました"
  #         fi
  #       fi
  #     else
  #       echo "コミットメッセージが生成されませんでした"
  #     fi
  #     sleep 1
  #   '';
  # };

  # # lazygit設定
  # xdg.configFile."lazygit/config.yml".text = ''
  #   customCommands:
  #     - description: "commit with Claude"
  #       key: "C"
  #       command: "claude-commit"
  #       context: "files"
  #       output: terminal
  # '';

  # ----------------------------
  # Podman → Docker 互換設定
  # ----------------------------
  # ソケットアクティベーション: 接続時に自動で Podman API 起動
  systemd.user.sockets.podman = {
    Unit = {
      Description = "Podman API Socket";
    };
    Socket = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = "0660";
    };
    Install = {
      WantedBy = [ "sockets.target" ];
    };
  };

  systemd.user.services.podman = {
    Unit = {
      Description = "Podman API Service";
      Requires = "podman.socket";
      After = "podman.socket";
    };
    Service = {
      Type = "exec";
      ExecStart = "${pkgs.podman}/bin/podman system service";
    };
  };

  # エイリアスが効かない環境用の docker ラッパー
  home.file.".local/bin/docker" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec podman "$@"
    '';
  };

  # ----------------------------
  # Nix substituters
  # ----------------------------
  xdg.configFile."nix/nix.conf".text = ''
    extra-substituters = https://rstats-on-nix.cachix.org
    extra-trusted-public-keys = rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0=
  '';

  # ----------------------------
  # Environment variables
  # ----------------------------
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "bat";
    VOLTA_HOME = "${homeDirectory}/.volta";
    PNPM_HOME = "${homeDirectory}/.local/share/pnpm";
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
  };

  home.sessionPath = [
    "$HOME/.volta/bin"
    "$HOME/.pixi/bin"
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm"
    toolBin
    zedBin
    vscodeBin
  ];
}
