# ~/myflake/home/tellur1an.nix
{ config, pkgs, ... }:

{
  home.username = "tellur1an";
  home.homeDirectory = "/home/tellur1an";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    vim
    home-manager
  ];

  home.file.".config/test.txt".text = ''
    Test file created by Home Manager
  '';
}
