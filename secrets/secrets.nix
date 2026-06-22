# agenix recipient rules. The `agenix` CLI reads THIS file (run it from inside
# secrets/, or `export RULES=$PWD/secrets/secrets.nix`) to know who each secret
# is encrypted to. NixOS does not read this file — it reads the .age blobs via
# `age.secrets.*` in modules/agenix.nix.
#
# Every secret is encrypted to: the host key (auto-decrypt at boot) + every
# YubiKey (so any YubiKey can decrypt/rekey on a fresh machine). Never drop the
# YubiKeys from a rule — they are the recovery root of trust.

let
  # ---------------------------------------------------------------------------
  # YubiKey recipients  (age-plugin-yubikey, PIV applet — identity lives ON the
  # hardware and is portable across machines).
  #
  # To get a recipient, with the key plugged in:
  #     age-plugin-yubikey --generate      # first time: creates identity on the key
  #     age-plugin-yubikey --list          # prints existing "age1yubikey1..." recipients
  # Copy the printed `age1yubikey1...` line here.
  # ---------------------------------------------------------------------------
  yubikey1 = "age1yubikey1REPLACE_WITH_YOUR_OWN_RECIPIENT";
  yubikey2 = "age1yubikey1REPLACE_WITH_YOUR_OWN_RECIPIENT";   # add as many keys as you keep for recovery
  yubikey3 = "age1yubikey1REPLACE_WITH_YOUR_OWN_RECIPIENT";

  # ---------------------------------------------------------------------------
  # Host key recipient  (this machine; auto-decrypts at boot).
  # agenix uses age's NATIVE ssh support, so this is the RAW ssh public key
  # (NOT an ssh-to-age age1… value — that's the sops-nix pattern). Get it with:
  #     cat /etc/ssh/ssh_host_ed25519_key.pub
  # On a reinstall this changes — replace it and `agenix --rekey`.
  # ---------------------------------------------------------------------------
  nixos = "ssh-ed25519 AAAA_REPLACE_WITH_YOUR_HOST_PUBKEY root@nixos";

  # ---------------------------------------------------------------------------
  yubikeys = [ yubikey1 yubikey2 yubikey3 ];  # who can edit/rekey + recovery
  hosts    = [ nixos ];                              # machines that auto-decrypt at boot
  all      = yubikeys ++ hosts;
in
{
  # Add one line per secret. Filename is what `agenix -e NAME.age` creates.
  "example.age".publicKeys = all;
}
