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
    # Local sessions only: the agent's approval prompt is a GUI dialog on this
    # machine, so inside an SSH session leave SSH_AUTH_SOCK alone and use the
    # agent forwarded from the client instead.
    # ~ expands per-user; root has no socket so ssh silently falls back to
    # on-disk keys there.
    Match exec "test -z \"$SSH_CONNECTION\""
      IdentityAgent ~/.1password/agent.sock

    # Forward the local agent to the other 1Password hosts so git works there
    # over SSH (approval pops up on the machine being typed at). Deliberately
    # not `Host *`: a forwarded agent is usable by root on the remote.
    Host lunar-fwk lunar-fwk.* fwk fwk.*
      ForwardAgent yes
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

  # Not environment.variables: that would clobber the forwarded-agent socket
  # sshd sets for SSH sessions.
  environment.extraInit = ''
    if [ -z "$SSH_CONNECTION" ]; then
      export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
    fi
  '';

  # gnome-keyring pulls in gcr, whose socket-activated ssh-agent also sets
  # SSH_AUTH_SOCK in the systemd user environment.
  systemd.user.sockets.gcr-ssh-agent.enable = false;
  systemd.user.services.gcr-ssh-agent.enable = false;
}
