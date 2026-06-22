# myflake_updated — reconciled against the live Fedora box

Authoritative source: the running Fedora install on this machine
(`dnf repoquery --userinstalled`, live Hyprland binds, and memory notes).
The Fedora box's preferences win. NixOS goes on the SHPP41-2000GM nvme,
replacing the Tumbleweed install (secondary OS).

## Channel split (owner rule)

- **unstable (`pkgs`)** — daily drivers, browsers, gaming, anything with a
  Hyprland keybind.
- **stable (`pkgs-stable`)** — everything else.

Wiring: `flake.nix` adds `nixpkgs-stable` (nixos-25.11), evaluates it once,
and threads it through `specialArgs` / `extraSpecialArgs` as `pkgs-stable`.
NixOS-module `pkgs` stays unstable.

## Flake input changes

- **+ `nixpkgs-stable`** = `nixos-25.11`
- **+ `noctalia`** = `github:noctalia-dev/noctalia` (v5, flake-only; primary bar)
- **+ `inputs`** passed to specialArgs (used for noctalia + hyprland packages)
- `hyprland` package now drives `programs.hyprland` (== Fedora hyprland-git)
- stale `flake.lock` deleted — regenerated on first build

## Added (Fedora has it, flake didn't)

Browsers: `firefox`, `qutebrowser`, `tor-browser`, `zen-browser` (flake input
`github:youwen5/zen-browser-flake`; not in nixpkgs)
Comms: `vesktop`
Shell/dev CLI: `gh`, `lazygit`, `atuin`, `direnv`, `delta`, `difftastic`,
`fastfetch`, `jq`, `yq-go`, `glow`, `lnav`, `duf`, `procs`, `hyperfine`,
`tokei`, `ranger`, `w3m`, `weechat`, `pandoc`, `shellcheck`, `pipx`,
`mediainfo`, `ffmpegthumbnailer`, `chafa`, `ueberzugpp`
Editors: `neovide`, `vscodium`
GUI apps: `calibre`, `audacity`*, `gimp`, `krita`, `qalculate-gtk`,
`keepassxc`, `seahorse`, `transmission_4-gtk`, `feather`
Media/audio: `kew`, `mpd`, `mpc-cli`, `spotify`, `helvum`, `qpwgraph`,
`qjackctl`, `carla`
Dev toolchains: `deno`, `bun`, `go`, `meson`, `ninja`
Virt/containers: `podman`
Sys/net: `borgbackup`, `borgmatic`, `gparted`, `nmap`, `wireshark`, `mtr`
Hardware: `lact`, `amdgpu_top`, `piper`, `keyd`, `ydotool`
Wayland: `wiremix`, `mako`, `wob`, `kanshi`, `gammastep`, `quickshell`,
noctalia v5, `hyprlock`, `hypridle`, `hyprpicker`, `hyprpolkitagent`,
`xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gnome`
Qt theming: `qt5ct`, kvantum (qt6 + qt5)
Gaming: `steamtinkerlaunch`, `protontricks`, `wineasio`
Fonts: `comfortaa`, `source-code-pro`, `noto-fonts`, `font-awesome_4`

Services enabled to match Fedora: `displayManager.gdm` (Wayland),
`services.syncthing`, `programs.coolercontrol`, `services.ratbagd`
(piper), `services.input-remapper`, `programs.steam.gamescopeSession`,
`programs.appimage` (binfmt).

Kernel: `linuxPackages_cachyos` + RDNA4 params (`amdgpu.mes=0`,
`mem_sleep_default=deep`).

## Removed (not on the Fedora box / replaced)

- `discord` → replaced by `vesktop`
- `thunderbird` → Fedora uses aerc + mu4e/mbsync (no GUI mail client pkg)
- `element-desktop`, `simplex-chat-desktop`, `dino`, `fractal`,
  `fluffychat` → not installed
- `obsidian`, `standardnotes`, `onlyoffice-desktopeditors`,
  `pear-desktop`, `upscayl`, `gearlever` → not installed
- `neofetch` → `fastfetch`
- `pwvucontrol` → `wiremix`
- `easyeffects` → not installed (kept `cava` only because home configures it)
- `pcmanfm`, `py7zr`, `hblock`, `rustdesk`, `lmstudio`(kept)
- `vscode` → `vscodium`
- Wayland dupes/non-Fedora: `swayosd`→`wob`, `swww` (uses swaybg),
  `nwg-bar`, `walker`, `rofi`, `wofi`, `dunst`, `wl-clip-persist`,
  `clipman`, `wayfreeze`, `wlrctl`, `wdisplays`→`kanshi`,
  `wlsunset`→`gammastep`, `sway-contrib.grimshot`, `unclutter-xfixes`,
  `xwayland-satellite` (niri-only), `xdotool`, `swaylock-effects`→`swaylock`
- `desktop/niri.nix` deleted (niri not installed)

## Verify on first `nixos-rebuild` (attr names that move around)

- `feather` (Monero wallet) — if eval fails, drop or use overlay
- `kew` — newer attr, confirm present in your pinned unstable
- `mpc-cli` — historically `mpc_cli`; swap if eval errors
- `linuxPackages_cachyos` — provided by chaotic overlay; confirm attr name

## Shell / dotfiles (machine is definitive)

Login shell on the Fedora box is **zsh** (zinit-based), not fish — fish is an
abandoned leftover. Fixed:

- `core/users.nix`: `shell = pkgs.zsh` (was `pkgs.fish`)
- `desktop/default.nix`: `programs.zsh.enable` (was `programs.fish.enable`);
  fish stays installed as a package but is not the login shell
- `home/username.nix`: removed the generated `programs.zsh` +
  `programs.starship` blocks. The real 570-line `.zshrc` (zinit:
  fast-syntax-highlighting, zsh-autosuggestions, fzf-tab, abbr, forgit,
  history-substring-search, …) and the tide-replica `starship.toml` are now
  **symlinked verbatim** from `home/shell/` (same pattern as `home/hypr/`).
- `programs.{zoxide,fzf,yazi}` keep `enable` for the binary but
  `enableZshIntegration = false` — the real `.zshrc` inits them itself.
- Staged `home/shell/zshrc` patched: fzf key-bindings now also source from the
  NixOS path (`/run/current-system/sw/share/fzf`). dnf/AppImage aliases kept
  verbatim (no-ops on NixOS).

zinit bootstraps its plugins to `~/.local/share/zinit` on first interactive
shell — needs network once.

## Live ~/.config symlinked verbatim (staged from the Fedora box)

Real configs are now in the flake and symlinked via `xdg.configFile."<x>".source`
(state/logs/backups stripped). The matching `programs.*` generators were
removed so nothing clobbers them:

| config | staged at | replaced |
|---|---|---|
| `.zshrc` + `starship.toml` | `home/shell/` | `programs.zsh`, `programs.starship` |
| `hypr/` | `home/hypr/` | (was unmanaged) |
| `alacritty/` | `home/config/alacritty` | `programs.alacritty` |
| `kitty/` | `home/config/kitty` | (was unmanaged — primary terminal) |
| `foot/` | `home/config/foot` | (was unmanaged) |
| `mpv/` | `home/config/mpv` | `programs.mpv` (incl. `sponsorblock.so`) |
| `fuzzel/` | `home/config/fuzzel` | `home.file fuzzel.ini` |
| `cava/` | `home/config/cava` | `home.file cava/config` |
| `waybar/` | `home/config/waybar` | `home.file waybar/*` |
| `btop/` | `home/config/btop` | `programs.btop` |
| `MangoHud/` | `home/config/MangoHud` | `programs.mangohud` |
| `yazi/` | `home/config/yazi` | `programs.yazi` |

`zoxide`/`fzf`/`yazi` keep `enable` for the binary but with zsh integration
off (the real `.zshrc` inits them).

## Still home-manager-GENERATED (no live config to preserve)

- `programs.zathura` — kept generated; no live `~/.config/zathura` (Fedora uses
  GNOME papers). Harmless.
- `programs.tmux` — kept generated; no live tmux config on the box.
- `programs.eza` / `programs.bat` — config-only modules (theme/icons); no live
  files clobbered.
- `gtk` / `qt` / `home.pointerCursor` — theming via home-manager (adw-gtk3 /
  Papirus / Bibata). Swap to your live values if they differ.
- The `mango/*` `home.file` blocks — secondary WM, left as-is.

## Personal scripts (vpn-pick, yt-x/yt-xr, rumble-x)

Kept **mutable** in `~/.local/bin` (restored from the Dots repo), deliberately
NOT packaged into the nix store — they're iterated on often and yt-x
self-updates from upstream; baking them in would force a rebuild per edit and
freeze yt-x. Nix only guarantees PATH + runtime deps:

- `home.sessionPath = [ "$HOME/.local/bin" ]` (login/graphical PATH; `.zshrc`
  already prepends it for interactive shells).
- All deps already present: vpn-pick family → nmcli/fuzzel/libnotify/
  wireguard-tools; yt-x/yt-xr → yt-dlp/mpv/fzf/chafa/ueberzugpp; rumble-x →
  python3 (pure-stdlib) + yt-dlp + mpv. `rumble-x`'s `curl_cffi<0.15` pin lives
  in yt-dlp's own pipx venv, not nix.

Post-install: restore `~/Dots` (and re-run your pipx installs: `yt-dlp`, etc.).
Edit scripts freely afterward — no `nixos-rebuild` needed.

## Not ported (intentionally)

- The **mango** home-manager block in `home/username.nix` (waybar, mango
  rules/binds) is left intact — mango is a *secondary* WM (Fedora: mangowm).
  Hyprland is primary but its config is native lua on the Fedora box and is
  **not** managed by home-manager; copy `~/.config/hypr/*` over after install.
- **noctalia v5** is installed as a package (like Fedora's noctalia-git) and
  configured manually under `~/.config/noctalia` — the HM module is *not*
  imported to avoid clobbering the existing config.
- `moonfin` — not in nixpkgs; install separately if needed.
- `brave-origin-nightly` (M+ALT+b bind) has no nixpkgs equivalent; `brave`
  (stable) stands in.
- StreamController stays a Flatpak (`services.flatpak.enable`).
- `keyd` installed as a package; enable `services.keyd` with the
  machine-specific Naga keyboard+hash config after install.
