{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.bash.hyprland-notifier;
in
{
  options.programs.bash.hyprland-notifier = {
    enable = mkEnableOption "Hyprland long-running task notifications for Bash";

    threshold = mkOption {
      type = types.ints.positive;
      default = 20;
      description = "Duration in seconds before a command is considered long-running.";
    };
  };

  config = mkIf cfg.enable {
    # Added systemd to ensure systemd-cat is explicitly available via the nix store
    environment.systemPackages = with pkgs; [
      bash-preexec
      libnotify
      jq
      systemd
    ];

    programs.bash.interactiveShellInit = lib.mkAfter ''
      # 1. Clean up stray double semicolons injected by other Nix modules (like direnv/autojump)
      PROMPT_COMMAND="''${PROMPT_COMMAND//; ;/;}"
      PROMPT_COMMAND="''${PROMPT_COMMAND//;;/;}"

      # 2. Now it is safe to load bash-preexec
      source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh

      __notify_threshold=${toString cfg.threshold}

      _alacritty_notify_preexec() {
        __notify_cmd_start=$SECONDS
        __notify_cmd_text="$1"
        __notify_window_address=""

        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
          __notify_window_address=$({ { hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.address'; } 2>&1 1>&3 | ${pkgs.systemd}/bin/systemd-cat -t hyprland-notifier -p err; } 3>&1)
        fi
      }

      _alacritty_notify_precmd() {
        if [ -z "''${__notify_cmd_start:-}" ]; then return; fi

        local duration=$(( SECONDS - __notify_cmd_start ))
        unset __notify_cmd_start

        if (( duration >= __notify_threshold )); then
          if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && [ -n "''${__notify_window_address:-}" ]; then

            local current_window
            current_window=$({ { hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.address'; } 2>&1 1>&3 | ${pkgs.systemd}/bin/systemd-cat -t hyprland-notifier -p err; } 3>&1)

            if [ "$current_window" != "$__notify_window_address" ]; then
              ${pkgs.systemd}/bin/systemd-cat -t hyprland-notifier -p info -- ${pkgs.libnotify}/bin/notify-send \
                --app-name="Terminal" \
                --icon=utilities-terminal \
                "Task Completed" \
                "Command \`$__notify_cmd_text\` finished in ''${duration}s."
            fi
          fi
        fi

        unset __notify_window_address
      }

      preexec_functions+=(_alacritty_notify_preexec)
      precmd_functions+=(_alacritty_notify_precmd)
    '';
  };
}
