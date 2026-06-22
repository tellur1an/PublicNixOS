{ config, pkgs, lib, ... }:

{
  hardware.wooting.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.xone.enable = true;
  hardware.opentabletdriver.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86) true;
    package = pkgs.mesa;
  };

  services.lact.enable = true;
}
