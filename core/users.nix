{ config, pkgs, ... }:

{
  users.users.username = {
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "networkmanager" "wheel" "video" "input" "dialout" ];
    shell = pkgs.zsh;   # login shell on the Fedora box is zsh (zinit-based)
  };
}
