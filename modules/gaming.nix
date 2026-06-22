{ config, pkgs, ... }:

# Gaming = unstable channel (see system/default.nix policy).
{
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    # Fedora: gamescope-session-steam (Steam "Gaming Mode" / Big Picture session)
    gamescopeSession.enable = true;
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Wine stack mirrors the Fedora box: wine + winetricks + wineasio + dxvk.
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable      # Fedora: wine (32+64)
    winetricks                  # Fedora: winetricks
    wineasio                    # Fedora: wineasio
  ];
}
