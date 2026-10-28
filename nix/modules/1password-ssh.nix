{
  pkgs,
  config,
  lib,
  ...
}:

# Use 1Password as the SSH agent and for signing git commits (desktop hosts
# only: the agent socket is owned by the running, unlocked 1Password GUI).
# One-off setup in the app: Settings > Developer > "Use the SSH agent", and
# import/generate the key. GitHub needs it registered as a *Signing Key*.
# Verify with `git log --show-signature`.
{
  programs.ssh.extraConfig = ''
    # ~ expands per-user; root has no socket so ssh silently falls back to
    # on-disk keys there.
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';

  programs.git.config = [
    {
      user.signingkey = pkgs.sshPublicKeys.lunar-fwk_james;
      gpg = {
        format = "ssh";
        # op-ssh-sign talks to the 1Password app directly (no SSH_AUTH_SOCK).
        ssh = {
          program = "${config.programs._1password-gui.package}/bin/op-ssh-sign";
          allowedSignersFile = pkgs.writeText "allowed_signers" ''
            james@carragher.dev ${pkgs.sshPublicKeys.lunar-fwk_james}
          '';
        };
      };
      commit.gpgsign = true;
      tag.gpgsign = true;
    }
  ];

  # Don't let gpg-agent export its own SSH_AUTH_SOCK.
  programs.gnupg.agent.enableSSHSupport = lib.mkForce false;

  # Double-quoted in /etc/set-environment so $HOME expands at login.
  environment.variables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

  # gnome-keyring pulls in gcr, whose socket-activated ssh-agent also sets
  # SSH_AUTH_SOCK in the systemd user environment.
  systemd.user.sockets.gcr-ssh-agent.enable = false;
  systemd.user.services.gcr-ssh-agent.enable = false;
}
