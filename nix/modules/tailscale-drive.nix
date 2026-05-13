{ ... }:

{
  services.davfs2 = {
    enable = true; # tailscale drive share webdav FUSE mount
    settings = {
      globalSection = {
        # Increases the local cache to hide network jitters
        cache_size = 1024; # 1GB cache
        table_size = 4096;
        delay_upload = 2; # Wait 2 seconds before uploading (like write-back cache)
        gui_optimize = 1; # Reduces 'stat' calls which lag file explorers
      };
    };

  };

  fileSystems."/mnt/ts" = {
    device = "http://100.100.100.100:8080";
    fsType = "davfs";
    options = [
      "user" # Allows you to unmount/manage it
      "noauto" # Don't mount on boot (prevents hangs)
      "x-systemd.automount" # Mount it only when the directory is accessed
      "x-systemd.idle-timeout=60" # Unmount after 60s of inactivity (saves battery/bandwidth)
      "x-systemd.after=tailscaled.service" # Ensure it knows about Tailscale
      "_netdev" # Marks it as a network device
      "uid=1000" # Map file ownership
      "gid=100" # Map group
    ];
  };

  environment.etc."davfs2/secrets" = {

    text = ''
      http://100.100.100.100:8080 "" ""
    '';
    mode = "0600";
    user = "root";
    group = "root";
  };
}
