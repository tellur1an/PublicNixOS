{
  description = "My NixOS configuration";

  inputs = {
    # Unstable is the primary channel: daily-driver apps, gaming, and
    # anything with a keybind track unstable (see system/default.nix).
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable channel: everything that is NOT a daily driver / gaming / bound
    # (office, occasional GUI apps, system utilities, dev toolchains, libs).
    # Exposed to modules as `pkgs-stable` via specialArgs.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # MangoWC - the flake is at github:DreamMaoMao/mango
    # Kept as a secondary WM (installed on the Fedora box as `mangowm`).
    mango-flake = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Noctalia v5 (Quickshell desktop shell) - primary bar on the Fedora box.
    # Only available via flake. Requires nixpkgs unstable (latest Quickshell).
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser - not in nixpkgs; flake per NixOS wiki.
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Brave Origin - the `brave-origin` channel has no nixpkgs equivalent
    # (replaces the Fedora `brave-origin-nightly` bind). Provides the
    # `brave-origin` package + a `programs.brave-browser` home-manager module.
    brave-origin = {
      url = "github:Daniel-42-z/brave-origin-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, mango-flake, hyprland, hyprland-contrib, hyprland-plugins, noctalia, chaotic, ... }@inputs:
    let
      system = "x86_64-linux";
      # Stable package set, evaluated once and threaded through specialArgs.
      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs chaotic mango-flake noctalia pkgs-stable; };
        modules = [
          ./configuration.nix  # YOUR ORIGINAL configuration.nix - don't replace this
          chaotic.nixosModules.default

          # 1. Enable the system-level module (registers programs.mango)
          mango-flake.nixosModules.mango
          {
            programs.mango.enable = true;
          }

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              backupFileExtension = "backup";
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs hyprland hyprland-contrib hyprland-plugins mango-flake noctalia pkgs-stable;
              };
              users.username = { ... }: {
                imports = [
                  ./home/username.nix
                  # CHANGED: Import the mango home-manager module
                  mango-flake.hmModules.mango
                  # programs.brave-browser (Brave Origin) module
                  inputs.brave-origin.homeManagerModules.default
                ];
              };
            };
          }
        ];
      };
    };
}
