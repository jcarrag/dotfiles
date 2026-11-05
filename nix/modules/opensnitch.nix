{ pkgs, config, ... }:

{
  services.opensnitch = {
    enable = true;
    settings = {
      # The NixOS module defaults this to "iptables" unless networking.nftables
      # is enabled, but opensnitch's shipped system-fw.json uses nftables
      # table/chain names, so every policy rule then fails at startup
      # ("Error while running firewall rule ... -P input ACCEPT -t filter").
      # The nftables backend talks netlink directly and needs no binary.
      Firewall = "nftables";
      # No UI prompt is required: anything not matched by a rule is allowed,
      # so the daemon is purely a declarative blocklist here.
      DefaultAction = "allow";
      InterceptUnknown = false;
    };
    rules = {
      # Block YouTube and Twitch system-wide for every process/user. Matching
      # is on the resolved hostname, so the video CDNs (googlevideo.com,
      # ttvnw.net) and static/thumbnail hosts (ytimg.com, jtvnw.net) are
      # included to also kill embeds and the app/API paths.
      deny-video-sites = {
        name = "deny-video-sites";
        enabled = true;
        precedence = true; # evaluated before any allow rules
        action = "deny";
        duration = "always";
        operator = {
          type = "regexp";
          operand = "dest.host";
          sensitive = false;
          data = "^(.*\\.)?(youtube\\.com|youtu\\.be|youtube-nocookie\\.com|googlevideo\\.com|ytimg\\.com|yt3\\.ggpht\\.com|twitch\\.tv|ttvnw\\.net|jtvnw\\.net|twitchcdn\\.net)$";
        };
      };
    };
  };

  environment.systemPackages = [ pkgs.opensnitch-ui ];

  # Quieten the "Error loading network aliases" warning at startup by linking
  # in the (empty) aliases file the package ships, as the module already does
  # for system-fw.json.
  systemd.tmpfiles.rules = [
    "L+ /etc/opensnitchd/network_aliases.json - - - - ${config.services.opensnitch.package}/etc/opensnitchd/network_aliases.json"
  ];
}
