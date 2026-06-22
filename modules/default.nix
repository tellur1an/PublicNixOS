{ config, pkgs, ... }:

{
  imports = [
    ./gaming.nix
    ./mullvad.nix
    ./yubikey.nix      # YubiKey 5: pcscd, udev, ykman, FIDO2 sk-ssh support
    ./obs.nix          # NOTE: OBS is not installed on the Fedora box, but the
                       # streaming gear (Scarlett 2i2 / StreamDeck) and the
                       # v4l2loopback "OBS Cam" in core/ justify keeping it.
    ./streamdeck.nix   # System udev rules: StreamDeck uaccess + Scarlett audio-route trigger
  ];

  # StreamController is a Flatpak on Fedora (com.core447.StreamController).
  services.flatpak.enable = true;
  services.printing.enable = true;          # Fedora: cups / driverless (Brother HL-L2395DW)

  # --- RGB / peripherals (match Fedora services) ---
  services.hardware.openrgb.enable = true;  # Fedora: openrgb-udev-rules
  services.ratbagd.enable = true;           # Fedora: piper (needs ratbagd)
  services.input-remapper.enable = true;    # Fedora: input-remapper (Naga preset)

  # --- File sync ---
  services.syncthing = {                    # Fedora: syncthing
    enable = true;
    user = "username";
    dataDir = "/home/username";
    configDir = "/home/username/.config/syncthing";
  };

  # --- Fan / GPU control daemon ---
  programs.coolercontrol.enable = true;     # Fedora: coolercontrol

  # NOTE: keyd (Fedora: keyd, used for the Naga remap) is installed as a
  # package. Enabling services.keyd needs the machine-specific keyboard +
  # hash config (see input_remapper_naga memory) -- configure after install.

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.rtkit.enable = true;
}
