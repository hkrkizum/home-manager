# WSL2 で Determinate Nix をインストールし、Home Manager を有効化する手順

![Nix](https://img.shields.io/badge/Nix-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Home%20Manager](https://img.shields.io/badge/Home%20Manager-0F4C81?style=for-the-badge&logo=homeadvisor&logoColor=white)
![Flakes](https://img.shields.io/badge/Nix%20Flakes-4C566A?style=for-the-badge&logo=nixos&logoColor=white)
![WSL2](https://img.shields.io/badge/WSL2-4D4D4D?style=for-the-badge&logo=windows11&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

WSL2上にインストールされたUbuntuディストリを前提に，**Determinate Nix** を導入し，**Home Manager を standalone + flakes 構成で有効化する**ための手順書である。

> [!CAUTION]
> 個人的な備忘録のため，本手順書の正確性は担保しない。自己責任での利用をお願い致します。

## 想定環境

- Windows上でWSL2を使用している
- WSLディストリはUbuntu / Debian系
- WSL内で`sudo`が使える
- Home Managerは**standalone**で使う
- Nixは**flakes ベース**で運用する

---

## 0. 事前確認

### Windows側PowerShellで確認

```powershell
wsl --version
wsl -l -v
```

確認事項:

- [ ] 対象ディストリが **Version 2**
- [ ] `wsl --version` が利用できること
- [ ] systemd 対応済みの WSL であること

## 1. WSL2でsystemdを有効化する

WSL側で `/etc/wsl.conf`を作成または更新する。

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

次に、**Windows 側 PowerShell**でWSLを停止する。

```powershell
wsl --shutdown
```

その後，WSLを再度起動して確認する。

```bash
systemctl list-unit-files --type=service >/dev/null && echo "systemd: OK"
```

`systemd: OK` と表示されれば良い。

---

## 2. Determinate Nixをインストールする

WSL内で次を実行する。

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 現在のシェルに Nix 環境を読み込む

インストール直後に `nix` コマンドが見えない場合は、次を実行する。

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 動作確認

```bash
nix --version
nix config show experimental-features
```

## 3. Home Manager 用ディレクトリを作る

```bash
mkdir -p ~/.config/home-manager
cd ~/.config/home-manager
```

## 4. `flake.nix` を作る

`~/.config/home-manager/flake.nix` を次の内容で作成する。

> **注意:** `YOUR_USERNAME` は自分の Linux ユーザー名に置き換えること。  
> 通常は `whoami` の結果である。

```nix
{
  description = "Home Manager on WSL2";

  inputs = {
    # 安定系の例
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # 通常の Intel / AMD PC
      system = "x86_64-linux";

      # ARM Windows / Snapdragon 系ならこちらに変更
      # system = "aarch64-linux";

      username = "YOUR_USERNAME";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            home.stateVersion = "25.11";

            programs.home-manager.enable = true;

            home.packages = with pkgs; [
              git
              curl
              vim
            ];

            programs.bash.enable = true;

            home.sessionVariables = {
              EDITOR = "vim";
            };
          }
        ];
      };
    };
}
```

### Linux ユーザー名を確認する

```bash
whoami
```

### 例: `hikaru` の場合

```nix
username = "hikaru";
```

## 5. 初回セットアップ

WSL 内で次を実行する。

```bash
nix run home-manager/release-25.11 -- switch --flake ~/.config/home-manager#$(whoami)
```

成功後は、通常の `home-manager` コマンドが使えるようになる。

```bash
home-manager generations
home-manager switch --flake ~/.config/home-manager#$(whoami)
```

## 6. 動作確認

```bash
home-manager --version
git --version
echo $EDITOR
```

期待する状態:

- [ ] `home-manager --version` が表示される
- [ ] `git --version` が表示される
- [ ] `echo $EDITOR` が `vim` を返す

## 7. 以後の運用

設定を変更した後，`flake.nix` を保存して次を実行する。

```bash
cd ~/.config/home-manager
home-manager switch --flake .#$(whoami)
```

inputs を更新した後は次を実行する。

```bash
cd ~/.config/home-manager
nix flake update
home-manager switch --flake .#$(whoami)
```

## 8. よくあるトラブル

### `systemd: OK` にならない

次を確認する。

- [ ] `/etc/wsl.conf` の内容が正しいか
- [ ] **Windows 側 PowerShell** で `wsl --shutdown` を実行したか
- [ ] その後に WSL を開き直したか

### `nix: command not found`

次を実行する。

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

その後、もう一度確認する。

```bash
nix --version
```

### Home Manager の branch mismatch が出る

`nixpkgs` と `home-manager` の release 系を揃える。このREADMEでは両方とも **25.11** を使っている。

## 9. 参考

- Microsoft WSL 設定ドキュメント
- Determinate Nix Installer
- Home Manager 公式 README
- Nix flakes documentation

## 10. ライセンス

- MIT License
- 本プロジェクトはClaude Code及びCodexの支援を受けて作成された
