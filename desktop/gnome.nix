{ config, pkgs, ... }:

{
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.xserver.xkb.layout = "us";
}
