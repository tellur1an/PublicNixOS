# Package Migration Notes: PikaOS → NixOS

## ✅ Added to NixOS Config

### From APT packages:
- brave-browser → `brave`
- discord → `discord`
- telegram-desktop → `telegram-desktop`
- thunderbird → `thunderbird`
- element-desktop → `element-desktop`
- signal-desktop → `signal-desktop`
- simplex-chat → `simplex-chat-desktop`
- btop → `btop`
- cava → `cava`
- yazi → `yazi`
- zoxide → `zoxide`
- tmux → `tmux`
- zsh + zsh-syntax-highlighting → `zsh`, `zsh-syntax-highlighting`
- yt-dlp → `yt-dlp`
- tldr → `tldr`
- bleachbit → `bleachbit`
- timeshift → `timeshift`
- solaar → `solaar`
- virt-manager → `virt-manager`
- chromium → `chromium`
- upscayl → `upscayl`
- shotwell → `shotwell`
- ddcutil → `ddcutil`
- wdisplays → `wdisplays`
- wev → `wev`
- wtype → `wtype`
- wlsunset → `wlsunset`
- tor/torsocks → `tor`, `torsocks`
- age → `age`
- joplin → `joplin-desktop`
- fractal → `fractal`
- fluffychat → `fluffychat`

### From Flatpaks:
- com.core447.StreamController → Need to check nixpkgs or use flatpak
- com.usebottles.bottles → `bottles` (in nixpkgs) or keep flatpak
- im.fluffychat.Fluffychat → `fluffychat`
- io.github.Soundux → `soundux` (check nixpkgs)
- it.mijorus.gearlever → `gearlever`
- org.gnome.Fractal → `fractal`

## ⚠️ AppImages - Need Alternative Solutions

These are AppImages on PikaOS. Options for NixOS:
1. Use NixOS package if available
2. Use `appimage-run` to run AppImages
3. Package them yourself
4. Use Flatpak

| AppImage | NixOS Status |
|----------|-------------|
| amplitude_soundboard.appimage | Not in nixpkgs - use appimage-run |
| betterdiscord.appimage | Use with Discord - might need manual setup |
| helium.appimage | Not in nixpkgs - use appimage-run |
| joplin.appimage | ✅ `joplin-desktop` in nixpkgs |
| lm_studio.appimage | ✅ `lmstudio` in nixpkgs |
| replugged_installer.appimage | Discord mod - manual setup |
| rustdesk.appimage | ✅ `rustdesk` in nixpkgs |
| simplex_chat.appimage | ✅ `simplex-chat-desktop` in nixpkgs |
| standard_notes.appimage | ✅ `standardnotes` in nixpkgs |
| tuta_mail.appimage | Check nixpkgs for `tutanota-desktop` |
| ventoy.appimage | ✅ `ventoy` in nixpkgs |
| vicinae.appimage | Not in nixpkgs - use appimage-run |
| wootility.appimage | Not in nixpkgs - use appimage-run (Wooting keyboard) |
| zen_browser.appimage | Not in nixpkgs yet - use appimage-run |

## 🔧 To Enable AppImage Support

Add to your NixOS config:

```nix
# In configuration.nix or a module
programs.appimage = {
  enable = true;
  binfmt = true;  # Run AppImages directly
};

environment.systemPackages = [ pkgs.appimage-run ];
```

Then you can run AppImages with:
```bash
appimage-run ~/AppImages/zen_browser.appimage
# Or just ./zen_browser.appimage if binfmt is enabled
```

## 📺 Monitor Configuration

Your new ultrawide at 240Hz - update these files:

### In `~/.config/mango/scripts/mango-display.sh`:
```bash
# Adjust resolution/refresh for your specific monitor
wlr-randr --output DP-2 --mode 3440x1440@240
```

### In `~/.config/waybar/config.jsonc`:
```json
"output": ["DP-2"],  // Verify this is correct output name
```

## 🎮 Gaming Notes

Your PikaOS has:
- steam-launcher ✅ (enabled via `programs.steam.enable`)
- gamescope ✅ (enabled via `programs.gamescope.enable`)
- vkbasalt ✅ (added to packages)
- umu-launcher → Check if in nixpkgs

## 📋 Flatpak on NixOS

If you want to keep using Flatpak for some apps:

```nix
# Already in modules/default.nix
services.flatpak.enable = true;
```

Then after rebuild:
```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.core447.StreamController
```

## 🔑 Things That May Need Manual Setup

1. **BetterDiscord/Replugged** - Discord mods need manual installation
2. **Wootility** - Wooting keyboard software (but `hardware.wooting.enable` is set)
3. **StreamController** - Flatpak recommended, or check if in nixpkgs
4. **Soundux** - Audio soundboard, check nixpkgs availability

## ❓ Questions for You

1. What's the exact resolution of your ultrawide? (3440x1440? 3840x1600?)
2. What's the output name? (run `wlr-randr` to check - DP-1, DP-2, HDMI-A-1, etc.)
3. Do you want to keep using Flatpak for StreamController and Bottles?
4. Any other apps you use frequently that I might have missed?
