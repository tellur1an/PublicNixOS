{ config, pkgs, ... }:

{
  users.users.username = {
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "networkmanager" "wheel" "video" "input" "dialout" "gamemode" ];
    shell = pkgs.zsh;   # login shell on the Fedora box is zsh (zinit-based)
  };
}
