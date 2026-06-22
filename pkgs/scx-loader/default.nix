# scx_loader - the org.scx.Loader D-Bus daemon that loads/switches sched-ext
# schedulers on demand. falcond drives it to apply per-game schedulers.
#
# Upstream lives in its own repo (sched-ext/scx-loader), separate from the scx
# scheduler binaries. The daemon execs schedulers by bare name (Command::new),
# so it needs the scx schedulers on PATH at runtime (wired in the NixOS module).
#
# Cargo.lock is vendored alongside this file (copied from the upstream tag) so
# the build is offline without tracking a cargoHash.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "scx-loader";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx-loader";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5OvdtW/Li+ubHDBSKe2ssE9ZyNSCcxNFSJffzxQ9WMk=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  # Pure-Rust D-Bus (zbus); no libdbus/openssl native deps needed.

  # Install the D-Bus system policy (so the service may own org.scx.Loader) and
  # the polkit action (org.scx.loader.manage-schedulers) - without the action
  # registered, Start/Switch/StopScheduler fail with "not registered". Grant of
  # the action to root is done with a polkit rule in the NixOS module.
  postInstall = ''
    install -Dm644 configs/org.scx.Loader.conf \
      $out/share/dbus-1/system.d/org.scx.Loader.conf
    install -Dm644 configs/org.scx.Loader.policy \
      $out/share/polkit-1/actions/org.scx.Loader.policy
  '';

  meta = {
    description = "On-demand D-Bus loader for sched-ext schedulers (org.scx.Loader)";
    homepage = "https://github.com/sched-ext/scx-loader";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "scx_loader";
  };
})
