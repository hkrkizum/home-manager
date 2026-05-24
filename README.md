# Home Manager configuration for WSL2

![Nix](https://img.shields.io/badge/Nix-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Home Manager](https://img.shields.io/badge/Home%20Manager-0F4C81?style=for-the-badge&logo=homeadvisor&logoColor=white)
![Flakes](https://img.shields.io/badge/Nix%20Flakes-4C566A?style=for-the-badge&logo=nixos&logoColor=white)
![WSL2](https://img.shields.io/badge/WSL2-4D4D4D?style=for-the-badge&logo=windows11&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

WSL2 上の Ubuntu/Debian 系ディストリで使う個人用 Home Manager 設定です。Nix flakes と standalone Home Manager を前提に、zsh、Starship、Git、Podman、開発ツール、modern CLI を宣言的に管理します。

> [!CAUTION]
> 個人環境向けの設定です。`username`、Windows ユーザー名、Git Credential Manager のパスなどは利用環境に合わせて変更してください。

## 構成

```text
.
├── flake.nix      # nixpkgs/home-manager input と Home Manager entrypoint
├── flake.lock     # lock file
├── home.nix       # 実際の Home Manager module
├── README.md
└── .gitignore
```

`flake.nix` は `home.nix` を読み込む薄い入口です。実際のパッケージ、shell、Git、Starship、Podman、各 CLI の設定は `home.nix` に分離しています。

## 想定環境

- Windows 上の WSL2
- Ubuntu / Debian 系 Linux
- systemd 有効化済み WSL
- Determinate Nix または flakes 対応 Nix
- Home Manager standalone
- Nerd Font 対応ターミナル

## 環境固有の設定

利用前に [flake.nix](./flake.nix) の以下を自分の環境に合わせます。

```nix
username = "hikaru";
homeDirectory = "/home/${username}";

windowsUsername = "aoxor";
windowsHome = "/mnt/c/Users/${windowsUsername}";

zedBin = "${windowsHome}/AppData/Local/Programs/Zed/bin";
vscodeBin = "${windowsHome}/AppData/Local/Programs/Microsoft VS Code/bin";
gcmPath = "${windowsHome}/scoop/apps/git/current/mingw64/bin/git-credential-manager.exe";
```

ARM Windows / Snapdragon 系の WSL では `system = "aarch64-linux";` に変更します。

## 初回セットアップ

WSL 側で systemd が有効になっていることを確認します。

```bash
systemctl list-unit-files --type=service >/dev/null && echo "systemd: OK"
```

Determinate Nix を使う場合のインストール例です。

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

インストール直後に `nix` が見えない場合は、現在の shell に Nix 環境を読み込みます。

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

このリポジトリを `~/.config/home-manager` に配置し、初回だけ `nix run` 経由で Home Manager を適用します。

```bash
cd ~/.config/home-manager
nix run home-manager/release-25.11 -- switch --flake .#hikaru
```

以後は `home-manager` コマンドで更新できます。

```bash
home-manager switch --flake ~/.config/home-manager#hikaru
```

## 管理している主なもの

- Shell: zsh
- Prompt: Starship
- Git: delta integration、credential helper、alias
- Editor: vim / Neovim
- Version/environment managers: Volta、Pixi、rig
- Containers: Podman、podman-compose、lazydocker
- Modern CLI: eza、bat、fd、ripgrep、zoxide、fzf、yazi、btop、tealdeer
- Nix tooling: nil、nixd、nixfmt
- tmux
- Podman Docker 互換 alias / wrapper
- Nix substituter: `rstats-on-nix.cachix.org`

## Shell とプロンプト

zsh は Home Manager の `programs.zsh` で管理しています。Oh My Zsh / Powerlevel10k は使わず、Starship を `programs.starship` で有効化しています。

Starship の表示内容:

- 左側: OS アイコン、ユーザー名、カレントディレクトリ、Git branch/status、言語・環境情報
- 環境情報: Python/venv、Pixi、R、Nix shell、Node.js、Bun、Rust、Go、PHP
- 右端: exit status、実行時間、jobs、時刻
- 2 行目: 入力用 character

Nix shell は短く表示します。

```text
 !   # impure
 ✓   # pure
 ?   # unknown
```

アイコン表示には Nerd Font が必要です。

## Git

Git 設定は [home.nix](./home.nix) の `programs.git` で管理しています。Windows 側の Git Credential Manager を WSL から利用するため、`gcmPath` が正しいことを確認してください。

主な alias:

```text
st = status -sb
co = checkout
cb = checkout -b
br = branch
cm = commit -m
lg = log --oneline --graph --decorate --all
```

## Podman

Podman は rootless 前提です。Docker 互換用に以下を設定しています。

- `alias docker=podman`
- `~/.local/bin/docker` wrapper
- user systemd の `podman.socket` / `podman.service`
- `DOCKER_HOST=unix:///run/user/1000/podman/podman.sock`

必要に応じて user id が `1000` であることを確認してください。

```bash
id -u
```

## 日常運用

設定を変更したら適用します。

```bash
cd ~/.config/home-manager
home-manager switch --flake .#hikaru
```

flake input を更新する場合:

```bash
cd ~/.config/home-manager
nix flake update
home-manager switch --flake .#hikaru
```

評価だけ確認する場合:

```bash
nix flake check
```

activation package を build して確認する場合:

```bash
nix build .#homeConfigurations.hikaru.activationPackage --no-link
```

## よくあるトラブル

### `nix: command not found`

Nix daemon の profile を読み込みます。

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Home Manager の branch mismatch

`nixpkgs` と `home-manager` の release 系を揃えます。この設定では両方とも `25.11` を使っています。

### アイコンが文字化けする

ターミナルのフォントを Nerd Font 対応フォントに変更してください。

### Git credential helper が動かない

[flake.nix](./flake.nix) の `windowsUsername` と `gcmPath` が実際の Windows 側パスと一致しているか確認してください。

```bash
ls -l /mnt/c/Users/<WindowsUser>/scoop/apps/git/current/mingw64/bin/git-credential-manager.exe
```

## ライセンス

MIT License

本プロジェクトは Claude Code および Codex の支援を受けて作成されています。
