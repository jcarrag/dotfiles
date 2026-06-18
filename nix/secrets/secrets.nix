# Create secret file
# > agenix -e secret1.age
# Update all secret files with new publicKeys
# > agenix -r

with (import ../sshPublicKeys.nix);
let
  trusted-systems = [
    hm90_james
    fwk_james
    lunar-fwk_james
  ];
in
{
  "putioarr_pass.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "putio_api_key.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sonarr_api_key.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "radarr_api_key.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sabnzbd_api_key.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sabnzbd_frugal_user.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sabnzbd_frugal_pass.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sabnzbd_eweka_user.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sabnzbd_eweka_pass.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sabnzbd_blocknews_user.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  "sabnzbd_blocknews_pass.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
  # Contains:
  # Host deluge
  #     HostName $DELUGE_HOST
  #     User $DELUGE_USER
  #     IdentityFile /root/.ssh/ultra_vps
  "deluge_ssh_config.age" = {
    publicKeys = trusted-systems;
    armor = true;
  };
}
