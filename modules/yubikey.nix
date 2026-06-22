{ config, pkgs, ... }:

# YubiKey 5 (1050:0407) support. On the Fedora box the key backs a FIDO2
# resident SSH key (~/.ssh/id_ed25519_sk_rk_dotfiles) and web U2F. GPG key is
# currently on-disk (not on the card), used by aerc/mu4e to decrypt authinfo.
{
  # Smartcard daemon (PIV/OpenPGP card, ykman, GPG-on-card if you migrate later)
  services.pcscd.enable = true;

  # udev rules so the key is accessible without root (FIDO2 + OTP/CCID)
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # GPG agent with SSH support. enableSSHSupport lets gpg-agent also serve
  # on-card SSH keys if you move the GPG auth subkey to the YubiKey later.
  # FIDO2 sk-ssh keys do NOT need this (they use ssh-agent + libfido2).
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;   # flip to true only if you put an SSH key on the GPG card
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  environment.systemPackages = with pkgs; [
    yubikey-manager       # ykman (Fedora: yubikey-manager)
    yubikey-personalization
    libfido2              # fido2-token; OpenSSH sk-ed25519 support
    age-plugin-yubikey    # optional: age identities on a YubiKey
  ];

  # OPTIONAL — YubiKey for login/sudo (NOT configured on the Fedora box).
  # Uncomment + enroll (`pamu2fcfg > ~/.config/Yubico/u2f_keys`) to require a
  # touch for sudo/login:
  # security.pam.u2f = {
  #   enable = true;
  #   settings.cue = true;
  #   control = "sufficient";
  # };
  # security.pam.services.sudo.u2fAuth = true;
}
