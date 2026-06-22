{ config, pkgs, ... }:

{
  imports = [
    # GNOME kept available (Fedora has the full GNOME stack + GDM installed)
    ./gnome.nix

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

  # Display manager: GDM, matching the Fedora box (GDM default session =
  # hyprland-uwsm). greetd/tuigreet kept below as a commented fallback.
  services.displayManager.gdm.enable = true;

  # --- Fallback: greetd + tuigreet (uncomment to use instead of GDM) ---
  # services.greetd = {
  #   enable = true;
  #   settings.default_session = {
  #     command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
  #     user = "greeter";
  #   };
  # };
}
