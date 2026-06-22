{ config, pkgs, ... }:

{
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;

  systemd.services.mullvad-daemon = {
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = "${pkgs.mullvad-vpn}/bin/mullvad-daemon -v --disable-stdout-timestamps";
      Environment = "MULLVAD_RESOURCE_DIR=${pkgs.mullvad-vpn}/share/mullvad/resources";
    };
  };
}
