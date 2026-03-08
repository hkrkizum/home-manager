# WSL2 で Determinate Nix をインストールし、Home Manager を有効化する手順

この README は、**WSL2 上の Ubuntu / Debian 系ディストリ**を前提に、**Determinate Nix** を導入し、**Home Manager を standalone + flakes 構成で有効化する**ための、コピペしやすい Step-by-Step 手順書です。

## 想定環境

- Windows 上で WSL2 を使用している
- WSL ディストリは Ubuntu / Debian 系
- WSL 内で `sudo` が使える
- Home Manager は **standalone** で使う
- Nix は **flakes ベース**で運用する

---

## 0. 事前確認

### Windows 側 PowerShell で確認

```powershell
wsl --version
wsl -l -v
```

確認したい点:

- 対象ディストリが **Version 2**
- `wsl --version` が利用できること
- systemd 対応済みの WSL であること

---

## 1. WSL2 で systemd を有効化する

WSL 側で `/etc/wsl.conf` を作成または更新します。

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

次に、**Windows 側 PowerShell** で WSL を停止します。

```powershell
wsl --shutdown
```

その後、WSL を再度起動して確認します。

```bash
systemctl list-unit-files --type=service >/dev/null && echo "systemd: OK"
```

`systemd: OK` と表示されれば先へ進めます。

---

## 2. Determinate Nix をインストールする

WSL 内で次を実行します。

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 現在のシェルに Nix 環境を読み込む

インストール直後に `nix` コマンドが見えない場合は、次を実行します。

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 動作確認

```bash
nix --version
nix config show experimental-features
```

---

## 3. Home Manager 用ディレクトリを作る

```bash
mkdir -p ~/.config/home-manager
cd ~/.config/home-manager
```

---

## 4. `flake.nix` を作る

`~/.config/home-manager/flake.nix` を次の内容で作成してください。

> **注意:** `YOUR_USERNAME` は自分の Linux ユーザー名に置き換えてください。  
> 通常は `whoami` の結果です。

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

---

## 5. 初回適用する

WSL 内で次を実行します。

```bash
nix run home-manager/release-25.11 -- switch --flake ~/.config/home-manager#$(whoami)
```

成功後は、通常の `home-manager` コマンドが使えるようになります。

```bash
home-manager generations
home-manager switch --flake ~/.config/home-manager#$(whoami)
```

---

## 6. 動作確認

```bash
home-manager --version
git --version
echo $EDITOR
```

期待する状態:

- `home-manager --version` が表示される
- `git --version` が表示される
- `echo $EDITOR` が `vim` を返す

---

## 7. 以後の運用

設定を変更したら、`flake.nix` を保存して次を実行します。

```bash
cd ~/.config/home-manager
home-manager switch --flake .#$(whoami)
```

inputs を更新したいときは次です。

```bash
cd ~/.config/home-manager
nix flake update
home-manager switch --flake .#$(whoami)
```

---

## 8. よくあるトラブル

### `systemd: OK` にならない

次を確認してください。

- `/etc/wsl.conf` の内容が正しいか
- **Windows 側 PowerShell** で `wsl --shutdown` を実行したか
- その後に WSL を開き直したか

### `nix: command not found`

次を実行してください。

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

その後、もう一度確認します。

```bash
nix --version
```

### Home Manager の branch mismatch が出る

`nixpkgs` と `home-manager` の release 系を揃えてください。  
この README では両方とも **25.11** を使っています。

---

## 9. 最短手順だけ抜き出す

### 1. systemd を有効化

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

```powershell
wsl --shutdown
```

### 2. Determinate Nix をインストール

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 3. Home Manager 設定を作成

```bash
mkdir -p ~/.config/home-manager
cd ~/.config/home-manager
```

`flake.nix` を配置する。

### 4. 初回適用

```bash
nix run home-manager/release-25.11 -- switch --flake ~/.config/home-manager#$(whoami)
```

---

## 10. 参考

- Microsoft WSL 設定ドキュメント
- Determinate Nix Installer
- Home Manager 公式 README
- Nix flakes documentation

必要なら次に、以下のどちらかに続けられます。

1. **zsh / git / neovim / starship を最初から入れた実用版 `flake.nix`**
2. **WSL2 + Home Manager + direnv + devenv まで含めた開発環境テンプレート**
