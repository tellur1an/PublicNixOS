{ config, pkgs, ... }:

{
  imports = [
    ./users.nix
    ./nfs-mounts.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Cap the boot menu so old generations don't pile up on the ESP.
  boot.loader.systemd-boot.configurationLimit = 15;
  
  # CachyOS kernel via chaotic (Fedora box runs kernel-cachyos).
  # The chaotic overlay (chaotic.nixosModules.default) provides this attr.
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # RDNA4 (RX 9070 XT) machine fixes carried over from the Fedora box:
  #   amdgpu.mes=0                  -> works around RDNA4 MES GPU-hang bug
  #   mem_sleep_default=deep        -> S3 suspend (fixes s2idle SMU no-response -62)
  #   amdgpu.ppfeaturemask=0xff..ff -> unlocks the full powerplay table so LACT can
  #                                    do clock/voltage control + undervolting. Without
  #                                    it LACT is limited to power-limit + fan only.
  boot.kernelParams = [ "amdgpu.mes=0" "mem_sleep_default=deep" "amdgpu.ppfeaturemask=0xffffffff" ];

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Auto-trim old generations weekly; keep the last 30 days. Dedup the store.
  # randomizedDelaySec spreads the run out so GC can't kick off mid-game at the
  # exact timer boundary.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    randomizedDelaySec = "1h";
    options = "--delete-older-than 30d";
  };
  nix.settings.auto-optimise-store = true;

  # zram swap: compressed RAM-backed swap as a stability / OOM safety net.
  # There is no disk swap device on this box; with 64 GB this rarely pages, but
  # zero swap means zero margin. zstd-compressed, sized at 25% (~16 GB effective
  # before compression). Pairs with the kernel's existing swappiness=100.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  networking.firewall.enable = false;

  # NFS client — needed for megaton media/backup mounts
  services.rpcbind.enable = true;
  boot.supportedFilesystems = [ "nfs4" ];
}
