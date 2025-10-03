# ~/myflake/home/tellur1an.nix
{ config, pkgs, inputs, ... }:

{
  home.username = "tellur1an";
  home.homeDirectory = "/home/tellur1an";
  home.stateVersion = "25.05";

  # Import Noctalia's Home Manager module
  imports = [
    ./noctalia-shell.nix
  ];

  # Noctalia configuration
  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.system}.default;
    settings = {
      bar = {
        density = "compact";
        position = "top";
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "SidePanelToggle";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
            {
              id = "Weather";
              city = "Bentonville";
              isAmerican = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Monochrome";
      general = {
        avatarImage = "/home/tellur1an/.face";
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = false;
        name = "Bentonville, AR, USA";
      };
    };
  };

  # GNOME extension settings
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        blur-my-shell.extensionUuid
        dash-to-panel.extensionUuid
        compiz-windows-effect.extensionUuid
        coverflow-alt-tab.extensionUuid
        tray-icons-reloaded.extensionUuid
        just-perfection.extensionUuid
        arcmenu.extensionUuid
        appindicator.extensionUuid
        clipboard-indicator.extensionUuid
        custom-osd.extensionUuid
        pop-shell.extensionUuid
        tiling-shell.extensionUuid
        paperwm.extensionUuid
      ];
    };
  };

  # User-specific environment variables
  home.sessionVariables = {
    TERM = "foot";
    TERMINAL = "foot";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    MOZ_DBUS_REMOTE = "1";
    GDK_BACKEND = "wayland";
    EGL_PLATFORM = "wayland";
    QT_QPA_PLATFORM = "wayland";
  };

  # User-specific systemd services
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "Polkit GNOME Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Fallback systemd service for Noctalia
  systemd.user.services.noctalia = {
    Unit = {
      Description = "Noctalia Shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${inputs.noctalia.packages.${pkgs.system}.default}/bin/noctalia";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Disable conflicting xdg.configFile for polkit service
  xdg.configFile."systemd/user/polkit-gnome-authentication-agent-1.service".enable = false;

  # User-specific packages
  home.packages = with pkgs; [
    kitty
    foot
    obsidian
    mpv
    home-manager
    pwvucontrol
    nemo
  ];
}
