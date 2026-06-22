{ config, pkgs, inputs, ... }:

# agenix wiring. Two halves:
#
#   1. SSH host key = the machine's always-available age identity. agenix
#      decrypts `age.secrets.*` at activation using /etc/ssh/ssh_host_ed25519_key
#      (the default in `age.identityPaths`). No YubiKey / PIN needed at boot.
#
#   2. The `agenix` CLI (added below) is what YOU run to create/edit/rekey
#      secrets, authenticating with a YubiKey (age-plugin-yubikey, already in
#      modules/yubikey.nix). Recipients live in secrets/secrets.nix.
#
# RECOVERY: every secret is encrypted to the host key AND to >=1 YubiKey
# (enforced by secrets/secrets.nix). So a fresh machine can be brought up with
# just a YubiKey + this repo:  rebuild -> new host key generated -> add its age
# pubkey to secrets.nix -> `agenix --rekey` (YubiKey decrypts) -> rebuild again.
{
  # We only want NixOS to generate + manage the host key. The daemon stays off
  # the network (firewall closed, no password auth) — this is not for remote login.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PasswordAuthentication = false;
  };

  # `agenix` CLI for editing/rekeying secrets.
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # --- Declared secrets. Add one block per secret. Example template (create the
  #     blob first with `cd secrets && agenix -e example.age`, then uncomment):
  # age.secrets.example = {
  #   file = ../secrets/example.age;       # encrypted blob, safe to commit
  #   # path  = "/run/agenix/example";     # default decrypt target (root:root 0400)
  #   # owner = "username";                # set if a user/service needs to read it
  #   # group = "users";
  #   # mode  = "0400";
  # };

  # Then reference config.age.secrets.example.path wherever the secret is needed,
  # e.g.  services.foo.passwordFile = config.age.secrets.example.path;
}
