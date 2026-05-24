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

        extraSpecialArgs = {
          inherit
            username
            homeDirectory
            toolBin
            zedBin
            vscodeBin
            gcmPath
            ;
        };

        modules = [
          ./home.nix
        ];
      };
    };
}
