{ ... }:
let
  server   = "<NAS-IP>";
  nfsOpts  = [
    "noauto"
    "x-systemd.automount"
    "x-systemd.idle-timeout=600"
    "nofail"
    "_netdev"
    "soft"
    "timeo=30"
  ];
  mkMount  = device: { inherit device; fsType = "nfs4"; options = nfsOpts; };
in
{
  # Tank (primary NAS)
  fileSystems."/mnt/media/tank/movies"      = mkMount "${server}:/tank/movies";
  fileSystems."/mnt/media/tank/tv"          = mkMount "${server}:/tank/tv";
  fileSystems."/mnt/media/tank/music"       = mkMount "${server}:/tank/music";
  fileSystems."/mnt/media/tank/audio"       = mkMount "${server}:/tank/audio";
  fileSystems."/mnt/media/tank/watch"       = mkMount "${server}:/tank/watch";
  fileSystems."/mnt/media/tank/books"       = mkMount "${server}:/tank/books";

  # Tank2 (virtio-share exports)
  fileSystems."/mnt/media/tank2/movies"     = mkMount "${server}:/tank2/virtio-share/movies";
  fileSystems."/mnt/media/tank2/tv"         = mkMount "${server}:/tank2/virtio-share/tv";
  fileSystems."/mnt/media/tank2/music"      = mkMount "${server}:/tank2/virtio-share/music";
  fileSystems."/mnt/media/tank2/audio"      = mkMount "${server}:/tank2/virtio-share/audio";
  fileSystems."/mnt/media/tank2/books"      = mkMount "${server}:/tank2/virtio-share/books";
  fileSystems."/mnt/media/tank2/audiobooks" = mkMount "${server}:/tank2/virtio-share/audiobooks";
  fileSystems."/mnt/media/tank2/courses"    = mkMount "${server}:/tank2/virtio-share/courses";
  fileSystems."/mnt/media/tank2/podcasts"   = mkMount "${server}:/tank2/virtio-share/podcasts";
}
