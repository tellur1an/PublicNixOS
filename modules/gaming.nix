{ config, lib, pkgs, ... }:

# Gaming = unstable channel (see system/default.nix policy).
let
  # Best-for-gaming defaults applied on top of falcond's bundled desktop
  # profiles (which ship scx_sched = none). scx_lavd in `gaming` mode is the
  # latency-optimised sched-ext scheduler; performance_mode flips PPD to
  # performance on launch (restored on exit). Override matches by `name`.
  gamingProfile = name: ''
    name = "${name}"
    scx_sched = lavd
    scx_sched_props = gaming
    performance_mode = true
  '';
  # filename -> bundled profile `name` (see share/falcond/profiles/*.conf)
  games = {
    "proton.conf" = "Proton";
    "cs2.conf" = "cs2";
    "factorio.conf" = "factorio";
    "x4.conf" = "X4";
    "civ7.conf" = "Civ7_linux_Vulkan_FinalRelease";
    "cyberpunk2077.conf" = "Cyberpunk2077.exe";
    "ffxiv.conf" = "ffxiv_dx11.exe";
    "hades2.conf" = "Hades2.exe";
    "obliv.conf" = "OblivionRemastered-Win64-Shipping.exe";
  };
in
{
  # gamemode is scoped to what falcond does NOT do: process priority (renice),
  # ioprio, and softrealtime. Power profile / scx scheduler / V-Cache stay
  # falcond's job, and the GPU stays LACT's job (gamemode's amd_performance_level
  # control is left disabled by not setting apply_gpu_optimisations, so it never
  # fights LACT's "manual" perf level). desiredgov is left at its default
  # (performance) on purpose: harmless overlap with falcond on amd_pstate=active,
  # and a useful fallback for native games falcond has no profile for.
  programs.gamemode = {
    enable = true;
    settings.general = {
      renice = 10;                 # nice -10 for the game (needs gamemode group)
      softrealtime = "auto";       # SCHED_ISO on >=4 cores where supported
      inhibit_screensaver = 1;
    };
  };

  # falcond: auto-detects running games and applies CPU/GPU/power profiles.
  services.falcond.enable = true;

  # Give every detected game the best gaming scheduler + performance power
  # profile (desktop profiles default to scx_sched = none).
  services.falcond.userProfiles = lib.mapAttrs (_: gamingProfile) games;
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
