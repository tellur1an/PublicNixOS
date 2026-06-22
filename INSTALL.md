# First boot: enable flakes, rebuild, update

Secondary NixOS on the `SHPP41-2000GM` nvme (replaces Tumbleweed). Do these
steps after the base NixOS graphical/minimal installer finishes and you've
booted into the new system.

---

## 0. CRITICAL: regenerate hardware-configuration.nix

The `hardware-configuration.nix` in this repo is from the **old** disk. It
will point at the wrong UUIDs / filesystems and can fail to boot. Regenerate
it on the new install:

```bash
sudo nixos-generate-config --root /        # writes /etc/nixos/hardware-configuration.nix
```

Then copy that fresh file over the one in the flake (see step 2). Do **not**
reuse the bundled one.

---

## 1. Temporarily enable flakes

Fresh NixOS has flakes off. Enable them for the current shell only (no rebuild
needed yet) by passing the experimental flags on each command:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

(This repo turns flakes on permanently via `nix.settings.experimental-features`
in `core/default.nix`, so after the first rebuild the env var is unnecessary.)

---

## 2. Place the flake + hardware file

```bash
# put the flake somewhere persistent
mkdir -p ~/nixos
cp -r /path/to/myflake_updated/* ~/nixos/
cd ~/nixos

# overwrite the stale hardware file with the freshly generated one
cp /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix
```

The flake builds `nixosConfigurations.nixos`. Confirm your hostname matches:
`core/default.nix` sets `networking.hostName = "nixos"`. If you want a
different host name, change it there and rename the attr in `flake.nix`.

---

## 3. First rebuild

Generates `flake.lock` (it was intentionally removed so it pins fresh) and
builds the system. First build is large (chaotic CachyOS kernel, Hyprland,
browsers, gaming stack) — expect a long download/compile.

```bash
cd ~/nixos
sudo nixos-rebuild switch --flake .#nixos
```

If you skipped the env var in step 1, run instead:

```bash
sudo nixos-rebuild switch --flake .#nixos \
  --option experimental-features "nix-command flakes"
```

Notes:
- Unfree allowed (`nixpkgs.config.allowUnfree = true`) — Steam, Vivaldi,
  Spotify, etc. build fine.
- Display manager is **GDM**; pick the Hyprland session at the login screen.
- On first switch, home-manager backs up any colliding dotfiles to
  `*.backup` (set by `backupFileExtension`).

After it completes, reboot to land on the CachyOS kernel:

```bash
sudo reboot
```

### If the rebuild fails — pull up Claude Code temporarily

Run Claude Code straight from nixpkgs without installing it (flakes must be
enabled — env var from step 1, or add `--option` flags). Drops you in an
ephemeral shell with `claude` on PATH:

```bash
nix shell nixpkgs#claude-code    # then: claude
# or one-shot:  nix run nixpkgs#claude-code
```

The temp shell vanishes on exit; nothing persists until you add `claude-code`
to a package list and rebuild.

---

## 4. Updating later

Bump all flake inputs (nixpkgs, stable, hyprland, noctalia, chaotic, …) then
rebuild:

```bash
cd ~/nixos
nix flake update                       # updates flake.lock (all inputs)
sudo nixos-rebuild switch --flake .#nixos
```

Update a single input only:

```bash
nix flake update noctalia              # or: nixpkgs / hyprland / chaotic ...
sudo nixos-rebuild switch --flake .#nixos
```

Test without making it the boot default:

```bash
sudo nixos-rebuild test --flake .#nixos    # active now, NOT after reboot
sudo nixos-rebuild boot --flake .#nixos    # next boot, not now
```

Roll back a bad generation:

```bash
sudo nixos-rebuild switch --rollback
# or pick one:  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

Garbage-collect old generations:

```bash
sudo nix-collect-garbage -d
```

---

## 5. Post-install manual bits (not in the flake)

- **Hyprland config**: managed via `home/hypr` (home-manager). If
  `~/.config/hypr` already has files, they get `*.backup`'d on first switch.
- **noctalia v5**: installed as a package; drop your `~/.config/noctalia`
  config in manually (HM module deliberately not imported).
- **rofimoji bind**: `binds.lua` calls `~/.local/bin/rofimoji`; rofimoji is in
  PATH from nixpkgs — `ln -s $(which rofimoji) ~/.local/bin/rofimoji` if empty.
- **StreamController**: Flatpak — `flatpak install flathub com.core447.StreamController`.
- **keyd (Naga remap)**: pkg installed; add the machine-specific
  keyboard+hash config and enable `services.keyd`.
- **lact daemon**: pkg installed; enable its systemd service for GPU settings
  at boot.
- See `CHANGES-vs-fedora.md` for attr names to verify on first build
  (`feather`, `kew`, `mpc-cli`, `linuxPackages_cachyos`).

---

## 6. Restore personal scripts, secrets, SSH, GPG, YubiKey

These live outside the flake on purpose (mutable scripts, and secrets must
never be committed to a git repo or the nix store). Restore them by hand after
the first rebuild. Order matters: GPG first (it unlocks authinfo), then SSH,
then the YubiKey.

### 6a. Dots repo (personal scripts: vpn-pick, yt-x/yt-xr, rumble-x)

The Dots repo is on the LAN Gitea (`<SERVER-IP>:3000`, authentik blocks it
from outside — you must be on the home network).

```bash
# do NOT bake a token into the remote URL. Use a credential helper / SSH or
# enter it interactively. The old embedded token was exposed in plaintext —
# rotate it in Gitea first.
git clone http://<SERVER-IP>:3000/username/dots-fedora.git ~/Dots
```

Then put the scripts on PATH (`~/.local/bin` is already on PATH via
`home.sessionPath`). Copy or symlink from the repo, keep them executable:

```bash
install -Dm755 ~/Dots/scripts/{vpn-pick,vpn-up,vpn-pick-launcher,yt-xr,yt-x,rumble-x} -t ~/.local/bin/
```

Re-create the pipx tools the scripts call (NixOS has `pipx`):

```bash
pipx install yt-dlp
# rumble-x: if it needs curl_cffi<0.15 in its own venv, pin it there (not nix):
#   pipx runpip <its-venv> install 'curl_cffi<0.15'
```

### 6b. GPG key (signs/decrypts; unlocks the authinfo file)

The GPG key is **on-disk**, not on the YubiKey. Restore it from your backup
(borgmatic — see `~/Documents/borgmatic_fedora_restore_disk.md`), never from a
git repo:

```bash
gpg --import /path/to/backup/secret-key.asc      # private key
gpg --import-ownertrust /path/to/backup/ownertrust.txt
# or set trust manually:
gpg --edit-key your-email@example.com   # > trust > 5 > save
gpgconf --kill gpg-agent             # restart agent
echo test | gpg -e -r your-email@example.com | gpg -d   # verify encrypt+decrypt
```

### 6c. The auth file (authinfo) + mail

aerc / mu4e read a **GPG-encrypted authinfo** (the `cred-cmd` pipes it through
`gpg -d`; Proton Bridge on port 1143). Restore the encrypted file from backup —
it stays encrypted at rest, so it's safe to keep in Dots/backup:

```bash
# wherever your config points cred-cmd at, e.g.:
cp /path/to/backup/.authinfo.gpg ~/.authinfo.gpg
gpg -d ~/.authinfo.gpg >/dev/null && echo "decrypts OK"   # needs 6b done first
```

Start Proton Bridge (it's in the package set) and confirm aerc/mu4e connect.

### 6d. SSH keys

Private keys are **not** in the Dots git repo — restore `~/.ssh` from your
encrypted backup and fix permissions (sshd/ssh refuse loose perms):

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /path/to/backup/.ssh/{id_ed25519_github,id_ed25519_sk_rk_dotfiles,config} ~/.ssh/
chmod 600 ~/.ssh/id_ed25519_github ~/.ssh/id_ed25519_sk_rk_dotfiles
chmod 644 ~/.ssh/config
ssh -T git@github.com    # uses id_ed25519_github
```

`id_ed25519_sk_rk_dotfiles` is a FIDO2 **resident** key — it only works with
the YubiKey plugged in (see 6e). If you only have the public key, you don't
need the backup at all: regenerate the private handle straight off the key with
`ssh-keygen -K` (6e).

### 6e. YubiKey on NixOS

`modules/yubikey.nix` (imported) already enables `pcscd`, the udev rules, and
installs `ykman` + `libfido2`. After the rebuild, plug the key in and verify:

```bash
ykman info                     # confirms the key + enabled apps (FIDO2/PIV/OTP)
fido2-token -L                 # lists the device (from libfido2)
```

FIDO2 resident SSH key — pull the private handle(s) off the key into `~/.ssh`
(no backup needed, the key material lives on the YubiKey):

```bash
cd ~/.ssh && ssh-keygen -K     # writes id_ed25519_sk_rk_* + .pub for resident keys
```

Then SSH/git that uses it will prompt for a **touch** on each auth. OpenSSH in
nixpkgs is built with FIDO2 support, so `sk-ed25519` keys work out of the box.

Notes:
- GPG-on-card: not used today (key is on-disk). To migrate later: `keytocard`
  in `gpg --edit-key`, then set `enableSSHSupport = true` in
  `modules/yubikey.nix` if you also want SSH-via-GPG.
- Login/sudo touch (`pam_u2f`) is **off** by default — enroll and uncomment the
  `security.pam.u2f` block in `modules/yubikey.nix` if you want it. Keep a
  second enrolled key or a fallback, or you can lock yourself out.
- Your memory notes the key once caused a boot hang on a specific USB hub —
  plug it into a directly-attached port if the old symptom returns.
