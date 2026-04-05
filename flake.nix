{
  description = "Home Manager on WSL2 with git/zsh/volta/pixi/rig/podman/modern CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      # Intel / AMD PC の一般的な WSL2
      system = "x86_64-linux";

      # ARM Windows の場合はこちら
      # system = "aarch64-linux";

      username = "hikaru";
      homeDirectory = "/home/${username}";

      windowsUsername = "aoxor";
      windowsHome = "/mnt/c/Users/${windowsUsername}";

      toolBin = "${homeDirectory}/.local/bin";
      zedBin = "${windowsHome}/AppData/Local/Programs/Zed/bin";
      vscodeBin = "${windowsHome}/AppData/Local/Programs/Microsoft VS Code/bin";
      gcmPath = "${windowsHome}/scoop/apps/git/current/mingw64/bin/git-credential-manager.exe";

      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          {
            home.username = username;
            home.homeDirectory = "${homeDirectory}";
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

              # prompt / shell extras
              zsh-powerlevel10k

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
            # zsh + Oh My Zsh + Powerlevel10k
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

              oh-my-zsh = {
                enable = true;
                plugins = [
                  "git"
                  "fzf"
                  "sudo"
                ];
                theme = "powerlevel10k/powerlevel10k";
                custom = "$HOME/.oh-my-zsh/custom";
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
                # powerlevel10k
                [[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh

                # Volta
                export VOLTA_HOME="$HOME/.volta"
                export PATH="$VOLTA_HOME/bin:$PATH"

                # Pixi global bin
                export PATH="$HOME/.pixi/bin:$PATH"

                # Podman alias compatibility
                alias docker=podman
              '';
            };

            # Oh My Zsh から powerlevel10k を見える場所へ配置
            home.file.".oh-my-zsh/custom/themes/powerlevel10k".source =
              "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";

            # 最小の powerlevel10k 設定
            home.file.".p10k.zsh".text = ''
              typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
              typeset -g POWERLEVEL9K_MODE=nerdfont-complete
              typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
              typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
              typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="❯ "
              typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
              typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)
              typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
              typeset -g POWERLEVEL9K_TIME_FORMAT="%H:%M:%S"
            '';

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
              DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
            };

            home.sessionPath = [
              "$HOME/.volta/bin"
              "$HOME/.pixi/bin"
              "$HOME/.local/bin"
              toolBin
              zedBin
              vscodeBin
            ];
          }
        ];
      };
    };
}
