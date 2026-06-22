{ config, pkgs, lib, ... }:

{
  # Enable MangoWC at system level
  programs.mango.enable = true;

  # XWayland for legacy X11 apps
  programs.xwayland.enable = true;

  # Essential packages for MangoWC setup
  environment.systemPackages = with pkgs; [
    # Terminal
    foot
    
    # Launchers
    fuzzel
    rofi
    wofi
    
    # Wallpaper
    swaybg
    
    # Screenshots
    grim
    slurp
    wayfreeze
    
    # Clipboard
    wl-clipboard
    wl-clip-persist
    cliphist
    
    # Notifications
    swaynotificationcenter
    libnotify
    
    # Display/monitor control
    wlr-randr
    wlrctl  # For waybar active window script
    
    # Idle/lock
    swayidle
    swaylock-effects
    
    # Bar (waybar since otter-bar isn't available)
    waybar
    
    # Misc wayland utilities
    wlogout
    nwg-bar
    
    # Emoji picker
    rofimoji
    
    # For waybar scripts
    lm_sensors
  ];
  
  # Session variables for MangoWC (wlroots-based); mkDefault so Hyprland wins
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = lib.mkDefault "wlroots";
    XDG_SESSION_DESKTOP = lib.mkDefault "wlroots";
  };
}
