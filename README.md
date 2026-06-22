# NixOS Config (flake)

My personal NixOS configuration, published as a reference. It is a Nix **flake**
with **Home Manager**, two Wayland window managers (**MangoWC** primary,
**Hyprland** secondary), the `ly` display manager, **agenix** for secrets, and a
handful of out-of-tree packages built from source.

> ⚠️ This is **not** a turnkey config. It is pinned to my hardware, my username,
> and my network. Clone it as a starting point and work through the
> [Make it yours](#make-it-yours) checklist below before building anything.

## Layout

```
.
├── flake.nix                 # inputs + the `nixosConfigurations.nixos` output
├── configuration.nix         # top-level glue
├── hardware-configuration.nix # MACHINE-SPECIFIC — regenerate on your hardware
├── core/
│   ├── default.nix           # hostname, timezone, locale, base system
│   ├── users.nix             # the user account (name + groups)
│   └── nfs-mounts.nix        # NFS media mounts (LAN NAS — optional)
├── desktop/
│   ├── default.nix           # ly display manager + xdg portals
│   ├── mangowc.nix           # MangoWC (primary WM) system bits
│   └── hyprland.nix          # Hyprland (secondary WM) system bits
├── home/
│   ├── username.nix          # Home Manager config (rename to your user)
│   ├── config/               # app dotfiles (kitty, foot, waybar, mpv, yazi, …)
│   ├── hypr/                 # Hyprland config (Lua)
│   ├── scripts/              # session/autostart helper scripts
│   └── shell/                # zsh + starship
├── modules/
│   ├── agenix.nix            # age-encrypted secrets wiring
│   ├── yubikey.nix           # pcscd + age-plugin-yubikey
│   ├── gaming.nix            # Steam, gamemode, gamescope, etc.
│   ├── falcond.nix           # PikaOS gaming daemon (built from pkgs/falcond)
│   ├── mullvad.nix, obs.nix, streamdeck.nix, default.nix
├── pkgs/
│   ├── falcond/              # built-from-source (Zig)
│   └── scx-loader/           # built-from-source (Rust)
├── secrets/                  # agenix: secrets.nix (recipients) + *.age blobs
└── system/                   # system-wide package set
```

## Make it yours

Everything that is specific to me has been replaced with an obvious placeholder.
Search the tree for these and edit them. `grep -rn '<PLACEHOLDER>' .` finds each.

### 1. User account  (required)

| Placeholder | Where | Change to |
|---|---|---|
| `username` | `core/users.nix`, `modules/default.nix` (syncthing), `home/username.nix` (`home.username`, `home.homeDirectory`), `flake.nix` (`users.username`, `./home/username.nix`), various `/home/username/...` paths | your login name |
| `home/username.nix` (filename) | `git mv home/username.nix home/<you>.nix` and update the import in `flake.nix` | your login name |
| `Your Name` | `core/users.nix` (`description`) | your full name (or anything) |

A repo-wide rename is the fastest path:

```bash
grep -rIl --exclude-dir=.git username . | xargs sed -i 's/username/<YOUR_USER>/g'
git mv home/username.nix home/<YOUR_USER>.nix   # then fix the import in flake.nix
```

### 2. Machine + hardware  (required)

- **`hardware-configuration.nix`** — DO NOT use mine. Generate your own on the
  target machine: `sudo nixos-generate-config` and copy in the result (it has
  your disk UUIDs, filesystems, and kernel modules). `hardware-configuration.nix.bak`
  is just my old copy — delete it.
- `core/default.nix`: `networking.hostName = "nixos"` → your hostname.
- `core/default.nix`: `time.timeZone = "America/Chicago"` and
  `i18n.defaultLocale` → your region.

### 3. Network / NAS  (optional)

| Placeholder | Where | Notes |
|---|---|---|
| `<NAS-IP>` | `core/nfs-mounts.nix` | NFS server IP. The share paths (`/tank/...`) are mine — rewrite or **remove the import** from `core/default.nix` if you have no NAS. |
| `<SERVER-IP>` | `INSTALL.md` | a LAN Gitea I pull dotfiles from — informational only |
| `<HOST-IP>` | `home/shell/zshrc` | an `ssh` alias — edit or delete |

### 4. Mail (Proton Bridge)  (optional)

`home/username.nix` and `home/scripts/flake-pin-check.sh` configure mbsync/msmtp
against a local **Proton Bridge** (`127.0.0.1`), reading the password from
`~/.authinfo.gpg`. Replace `your-email@example.com` with your address, or delete
the `programs.mbsync` / `programs.msmtp` blocks if you don't use this.

### 5. Secrets (agenix)  (optional — only if you use it)

`secrets/secrets.nix` lists the **public** recipients every secret is encrypted
to. Mine are stripped to placeholders, so the encrypted blobs are **not**
included — you must create your own:

1. Replace `age1yubikey1REPLACE_WITH_YOUR_OWN_RECIPIENT` with your own
   age/YubiKey recipient(s) — `age-plugin-yubikey --list`, or use a plain
   `age` keypair (`age-keygen`).
2. Replace `AAAA_REPLACE_WITH_YOUR_HOST_PUBKEY` with your machine's host key:
   `cat /etc/ssh/ssh_host_ed25519_key.pub` (this is the raw ssh key — agenix uses
   age's native ssh support, **not** an `ssh-to-age` `age1…` value).
3. Create a secret: `cd secrets && agenix -e example.age`, then uncomment the
   `age.secrets.example` block in `modules/agenix.nix`.

If you don't want secrets at all, remove `./agenix.nix` from `modules/default.nix`,
drop the `agenix` input from `flake.nix`, and delete `secrets/`.

### 6. Trim what you don't want

The package sets and modules are tuned for my use (gaming, OBS, Stream Deck,
Mullvad, falcond, scx-loader). Drop modules from `modules/default.nix` and
packages from `system/default.nix` as needed — `falcond`/`scx-loader` in `pkgs/`
build from source and can be removed with their modules.

## Build

Once the checklist is done and `hardware-configuration.nix` is yours:

```bash
sudo nixos-rebuild switch --flake .#nixos   # rename the output in flake.nix if you changed the hostname
```

At the `ly` login screen pick **mango** (or **Hyprland**) from the session list.
See `INSTALL.md` for the full from-scratch install walkthrough.
