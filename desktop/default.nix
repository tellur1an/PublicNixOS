{ config, pkgs, ... }:

{
  imports = [
    # Hyprland = PRIMARY WM on the Fedora box (hyprland-git, native lua config)
    ./hyprland.nix

    # MangoWC kept as a secondary WM (Fedora: mangowm)
    ./mangowc.nix

    # niri removed: not installed on the Fedora box.
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr        # MangoWC (wlroots) fallback
    ];
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [ "hyprland" "gtk" ];
    };
  };

  programs.dconf.enable = true;
  programs.zsh.enable = true;   # login shell (fish is installed but abandoned)
  security.polkit.enable = true;
  security.soteria.enable = true;

  # Keyboard layout (was in the now-removed gnome.nix; consumed by any X
  # fallback / XWayland greeter bits).
  services.xserver.xkb.layout = "us";

  # Display manager: ly (lightweight TTY greeter). It enumerates the
  # wayland-sessions registered by programs.hyprland / programs.mango, so
  # Hyprland and MangoWC both show up in the session picker.
  services.displayManager.ly.enable = true;
}
