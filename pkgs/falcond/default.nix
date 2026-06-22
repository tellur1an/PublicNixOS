# falcond - PikaOS gaming optimization daemon, packaged for NixOS.
#
# Upstream is a Zig project (zig >= 0.16.0) with build.zig.zon git deps hosted
# on git.pika-os.com. We build it with zig2nix, which fetches those deps offline
# from the committed build.zig.zon2json-lock (regenerate with:
#   nix run github:Cloudef/zig2nix#zon2json-lock -- build.zig.zon
# run inside the upstream falcond/ source dir, then copy the lock here).
#
# Game profiles live in a separate repo (falcond-profiles); they are installed
# into share/falcond so the system profile exposes them at
# /run/current-system/sw/share/falcond (see the baked -D paths below).
{ zig2nix, falcond-src, falcond-profiles, system }:

let
  env = zig2nix.outputs.zig-env.${system} { };
in
env.package {
  pname = "falcond";
  version = "2.0.0";
  src = "${falcond-src}/falcond";

  zigBuildZonLock = ./build.zig.zon2json-lock;

  # Zig emits a generic ELF interpreter (/lib64/ld-linux-x86-64.so.2) that does
  # not exist on NixOS. falcond's build.zig has no -Ddynamic-linker option, so
  # patch the interpreter + rpath to the Nix glibc loader after the build.
  nativeBuildInputs = [ env.pkgs.autoPatchelfHook ];

  # Override the compile-time FHS path defaults from build.zig with Nix-friendly
  # locations. Read-only data points at the system profile; mutable state at
  # /etc and /var/lib (provided by the NixOS module's tmpfiles + StateDirectory).
  zigBuildFlags = [
    "-Doptimize=ReleaseFast"
    "-Dconfig-path=/etc/falcond/config.conf"
    "-Dprofiles-dir=/run/current-system/sw/share/falcond/profiles"
    "-Duser-profiles-dir=/var/lib/falcond/profiles/user"
    "-Dsystem-conf-path=/run/current-system/sw/share/falcond/system.conf"
    "-Dstatus-file=/var/lib/falcond/status"
  ];

  postInstall = ''
    mkdir -p $out/share/falcond
    cp -r ${falcond-profiles}/usr/share/falcond/. $out/share/falcond/
  '';

  meta = {
    description = "Gaming optimization daemon that auto-applies profiles to running games";
    homepage = "https://github.com/PikaOS-Linux/falcond";
    license = env.pkgs.lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "falcond";
  };
}
