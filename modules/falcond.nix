# falcond - gaming optimization daemon (PikaOS). Package built in pkgs/falcond,
# threaded in here via specialArgs as `falcond`.
#
# falcond optionally drives sched-ext schedulers per game through the
# org.scx.Loader D-Bus daemon (scx_loader). We build that daemon from
# pkgs/scx-loader and run it with the scx scheduler binaries on PATH so falcond
# can switch schedulers (proton/cs2/... profiles set scx_sched).
{ config, lib, pkgs, falcond, ... }:

let
  cfg = config.services.falcond;
  scxLoaderPkg = pkgs.callPackage ../pkgs/scx-loader { };

  # falcond's loadDir skips dir entries whose kind != .file (symlinks are
  # ignored), so we cannot drop per-file symlinks into the user dir. Instead we
  # build a store directory of *real* .conf files and symlink the whole user
  # dir at it - openDirAbsolute follows the dir symlink and iterates the real
  # files inside.
  userProfilesDir = pkgs.runCommand "falcond-user-profiles" { } (
    "mkdir -p $out\n"
    + lib.concatStrings (
      lib.mapAttrsToList (
        fname: text: "cp ${pkgs.writeText "falcond-user-${fname}" text} $out/${fname}\n"
      ) cfg.userProfiles
    )
  );
  hasUserProfiles = cfg.userProfiles != { };
in
{
  options.services.falcond = {
    enable = lib.mkEnableOption "falcond gaming optimization daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = falcond;
      defaultText = lib.literalExpression "inputs-built falcond package";
      description = "The falcond package to use.";
    };

    scxLoader = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Run the org.scx.Loader D-Bus daemon so falcond can load and switch
          sched-ext schedulers per game profile. Requires a kernel with
          sched_ext (6.12+); the daemon stays idle until falcond requests a
          scheduler.
        '';
      };

      schedulerPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.scx.full;
        defaultText = lib.literalExpression "pkgs.scx.full";
        description = "Package providing the scx_* scheduler binaries on the daemon's PATH.";
      };
    };

    userProfiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      example = lib.literalExpression ''
        { "proton.conf" = "name = \"Proton\"\nscx_sched = bpfland\n"; }
      '';
      description = ''
        falcond user profile overrides, written into the user-profiles dir
        (/var/lib/falcond/profiles/user). The attr name is the file name; the
        value is the .conf body. A profile whose `name` matches a bundled one
        partially overrides it (only fields you set). Use this to enable an scx
        scheduler for games whose desktop profile ships `scx_sched = none`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # falcond: exposes share/falcond/{profiles,system.conf} at
    # /run/current-system/sw, where the binary was compiled to look for them.
    # scx_loader: exposes its polkit .policy action to polkit (scanned from the
    # system profile's share/polkit-1/actions).
    environment.systemPackages = [ cfg.package ] ++ lib.optional cfg.scxLoader.enable scxLoaderPkg;

    # falcond drives power profiles over D-Bus; it needs power-profiles-daemon
    # (or tuned + tuned-ppd) running. PPD is the simplest default.
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # Mutable paths baked into the binary that StateDirectory does not cover:
    # /etc/falcond (auto-generated config) and the user-profiles override dir.
    # When userProfiles are set, point the user dir at a store dir of real
    # override files; otherwise just create an empty dir for runtime use.
    systemd.tmpfiles.rules = [
      "d /etc/falcond 0755 root root -"
    ] ++ (
      if hasUserProfiles then [
        "d /var/lib/falcond/profiles 0755 root root -"
        "L+ /var/lib/falcond/profiles/user - - - - ${userProfilesDir}"
      ] else [
        "d /var/lib/falcond/profiles/user 0755 root root -"
      ]
    );

    systemd.services.falcond = {
      description = "falcond gaming optimization daemon";
      after = [ "multi-user.target" ] ++ lib.optional cfg.scxLoader.enable "scx_loader.service";
      wants = lib.optional cfg.scxLoader.enable "scx_loader.service";
      wantedBy = [ "graphical.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 2;
        StateDirectory = "falcond";   # /var/lib/falcond (status file lives here)
      };
    };

    # --- scx_loader: org.scx.Loader D-Bus scheduler daemon ---
    # dbus: own the bus name (polkit action is exposed via systemPackages above).
    services.dbus.packages = lib.mkIf cfg.scxLoader.enable [ scxLoaderPkg ];

    # scx_loader gates Start/Switch/StopScheduler behind the polkit action
    # org.scx.loader.manage-schedulers (default auth_admin_keep). falcond calls
    # it as root with no interactive session, so grant root non-interactively.
    security.polkit.extraConfig = lib.mkIf cfg.scxLoader.enable ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.scx.loader.manage-schedulers" && subject.user == "root") {
          return polkit.Result.YES;
        }
      });
    '';

    systemd.services.scx_loader = lib.mkIf cfg.scxLoader.enable {
      description = "On-demand D-Bus loader of sched-ext schedulers";
      wantedBy = [ "multi-user.target" ];

      # Only meaningful on a sched_ext-capable kernel.
      unitConfig.ConditionPathIsDirectory = "/sys/kernel/sched_ext";

      # scx_loader execs schedulers by bare name (Command::new "scx_bpfland"),
      # so the scheduler binaries must be on its PATH.
      path = [ cfg.scxLoader.schedulerPackage ];

      serviceConfig = {
        Type = "dbus";
        BusName = "org.scx.Loader";
        ExecStart = lib.getExe scxLoaderPkg;
        KillSignal = "SIGINT";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
