{ config, pkgs, ... }:

# StreamDeck MK.2 + Scarlett 2i2 soundboard audio routing.
# Userspace pieces (null sinks, routing scripts, systemd --user services,
# StreamController flatpak) live in $HOME and are restored from the Fedora box.
# This module supplies the two SYSTEM-level udev rules that home-manager cannot,
# rewritten from the Fedora /etc/udev/rules.d versions to use nix store paths
# (Fedora referenced /usr/bin/systemd-run + /usr/local/bin/<trigger>).

let
  user = "username";

  # udev RUN cannot call `systemctl --user` directly: it runs synchronously in
  # system context, gets killed on timeout, and no-ops before the user bus is up
  # (the common boot case). `systemd-run --no-block` detaches a transient unit
  # that waits for the user manager bus, then restarts the routing service.
  # Replaces Fedora /usr/local/bin/streamdeck-scarlett-trigger.sh.
  scarlettTrigger = pkgs.writeShellScript "streamdeck-scarlett-trigger" ''
    USER_NAME=${user}
    uid=$(${pkgs.coreutils}/bin/id -u "$USER_NAME") || exit 0
    export XDG_RUNTIME_DIR="/run/user/$uid"
    # wait up to 90s for the user manager bus to answer
    for _ in $(${pkgs.coreutils}/bin/seq 1 90); do
      if [ -S "$XDG_RUNTIME_DIR/bus" ] \
         && ${pkgs.systemd}/bin/systemctl --user --machine="''${USER_NAME}@.host" show-environment >/dev/null 2>&1; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    exec ${pkgs.systemd}/bin/systemctl --user --machine="''${USER_NAME}@.host" restart streamdeck-audio.service
  '';
in
{
  services.udev.extraRules = ''
    # Stream Deck MK.2 (0fd9:0080): raw USB (libusb) access for the logged-in user.
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", TAG+="uaccess"

    # Scarlett 2i2 4th Gen (1235:8219): on enumerate, re-run the audio routing
    # service to fix the boot race (ALSA source appears after the service's wait
    # window, leaving Mic1 unlinked from streamdeck_broadcast_mix).
    ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8219", RUN+="${pkgs.systemd}/bin/systemd-run --no-block --collect ${scarlettTrigger}"
  '';
}
