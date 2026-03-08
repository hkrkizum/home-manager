{
  description = "Home Manager on WSL2";

  inputs = {
    # 安定系で揃える
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # Intel/AMD の普通の Windows PC ならこちら
      system = "x86_64-linux";

      # Snapdragon/ARM Windows ならこちらに変更
      # system = "aarch64-linux";

      username = "hikaru";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            home.stateVersion = "25.11";

            # Home Manager 自身の CLI を有効化
            programs.home-manager.enable = true;

            # 最小サンプル
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