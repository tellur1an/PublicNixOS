{ config, pkgs, chaotic, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./core
    ./desktop
    ./hardware
    ./modules
    ./system
  ];

  nixpkgs.config.allowUnfree = true;

  # AppImage support (machine runs AppImages, e.g. LM Studio). binfmt lets
  # them run directly: ./foo.appimage
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  system.stateVersion = "25.11";
}
