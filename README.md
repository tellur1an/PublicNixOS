# NixOS Configuration - MangoWC Migration

## Summary of Changes

This configuration migrates from GNOME to MangoWC as the primary window manager/compositor.

### Key Changes

1. **flake.nix**
   - Added `mango` flake input from `github:DreamMaoMao/mango`
   - Added `mango.nixosModules.mango` to system modules
   - Passed `mango` to Home Manager's `extraSpecialArgs`

2. **desktop/default.nix**
   - Commented out GNOME import (can re-enable if needed)
   - Added MangoWC import
   - Switched from GDM to `greetd` with `tuigreet` (lightweight, works well with tiling WMs)
   - Updated xdg-portal config for wlroots

3. **desktop/mangowc.nix** (NEW)
   - System-level MangoWC enable (`programs.mango.enable = true`)
   - Essential packages for MangoWC (foot, fuzzel, swaybg, etc.)

4. **home/username.nix**
   - Added `wayland.windowManager.mango` config using Home Manager module
   - Your config.conf content is in `settings`
   - Your autostart commands are in `autostart_sh`
   - Additional config files (env.conf, appearance.conf, binds.conf, rules.conf) via `home.file`
   - Scripts in `~/.config/mango/scripts/` (executable)
   - Hyprland disabled by default (set `enable = true` to use alongside MangoWC)

5. **system/default.nix**
   - Removed GNOME extensions from packages
   - Updated XDG_CURRENT_DESKTOP to `wlroots`
   - Added MangoWC-friendly packages

### File Structure

```
nixos-config/
├── flake.nix                    # Updated with mango input
├── configuration.nix            # Unchanged
├── core/
│   ├── default.nix              # Unchanged
│   └── users.nix                # Unchanged
├── desktop/
│   ├── default.nix              # Updated - no GNOME, greetd instead of GDM
│   ├── gnome.nix                # Kept for reference (not imported)
│   ├── hyprland.nix             # Kept (still available)
│   ├── mangowc.nix              # NEW - MangoWC system config
│   └── niri.nix                 # Unchanged
├── hardware/
│   └── default.nix              # Unchanged
├── home/
│   └── username.nix            # Updated with MangoWC Home Manager config
├── modules/
│   ├── default.nix              # Unchanged
│   ├── gaming.nix               # Unchanged
│   ├── mullvad.nix              # Unchanged
│   └── obs.nix                  # Unchanged
└── system/
    └── default.nix              # Updated - removed GNOME stuff
```

### Usage

1. Copy these files to your NixOS config directory
2. Make sure you have your `hardware-configuration.nix` in place
3. Run:
   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

4. After reboot, you'll get `tuigreet` - select MangoWC to launch

### Switching Between Compositors

With greetd/tuigreet, you can choose which compositor to launch at login:
- `mango` - MangoWC
- `Hyprland` - Hyprland (if enabled)
- `niri` - Niri

### Notes

- **Waybar**: Configured with your MangoWC-specific setup including:
  - Custom tags module (`custom/mango_tags`)
  - Active window title via `wlrctl`
  - VPN status (Mullvad/WireGuard)
  - All your scripts in `~/.config/waybar/scripts/`
- **Scripts**: Moved from `~/.config/mango/keybindscripts/` to `~/.config/mango/scripts/`
- **Autostart**: Some PikaOS-specific things removed (pikman, appimages). Adjust as needed.
- **foot**: Set as default terminal in MangoWC config (was in your env.conf)
- **wlrctl**: Added for waybar active window detection on wlroots compositors

### If Something Breaks

1. Boot to TTY (Ctrl+Alt+F2)
2. Login as your user
3. Edit `/etc/nixos/desktop/default.nix` to uncomment GNOME
4. `sudo nixos-rebuild switch --flake /etc/nixos#nixos`
5. Reboot and use GDM/GNOME to debug
