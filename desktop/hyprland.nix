{ config, pkgs, inputs, ... }:

# PRIMARY WM. Tracks the hyprland flake (== Fedora's hyprland-git), so the
# native lua config from the Fedora box can be dropped into ~/.config/hypr.
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
}
