self: super:

{
  tmate-connect = super.writeShellScriptBin "tmate_connect" ''
    ${super.openssh}/bin/ssh jcarrag/jcarrag@lon1.tmate.io
  '';
  tmate-my =
    let
      authorizedKeys = super.writeText "authorized_keys" ''
        # XPS
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+kfnnvuaVqRuhUPpPlUY4s7UPMkoI9vGskJxep0ZPa james@carragher.dev
      '';
      # file generated by `gpg --armor --symmetric api_key`
      apiKeyAsc = super.writeText "api_key.asc"
        ''
          -----BEGIN PGP MESSAGE-----

          jA0EBwMC1M3/1FKWn7T/0lsBo6wPOQXPP4htaAr1W8T9NKBtb2DpNSw9inih6wO2
          5YoTegU3vBmlKGNa8QFhguzeECTfOcXH3ipj80Oax1f3ObNKhlkdvUNbfP1hMPlG
          kQXg2LCtyzZHdvJ5
          =otFb
          -----END PGP MESSAGE-----
        '';
      tmateConfig = super.writeText "tmate.conf" ''
        set -s escape-time 0

        # https://stackoverflow.com/a/33461197
        set -g mouse on
        # make scrolling with wheels work
        bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
        bind -n WheelDownPane select-pane -t= \; send-keys -M

        set tmate-authorized-keys "${authorizedKeys}"

        set tmate-session-name "jcarrag"
      '';
    in
    super.writeShellScriptBin "tmate" ''
      set -e

      read -sp "Enter the api key passphrase: " passphrase

      apiKey=$(
        ${super.gnupg}/bin/gpg \
        --pinentry-mode=loopback \
        --quiet \
        --no-symkey-cache \
        --passphrase $passphrase \
        --decrypt ${apiKeyAsc} \
      ) 

      ${super.tmate}/bin/tmate \
      -f ${tmateConfig} \
      -k $apiKey \
      new-session \
      'nix run --experimental-features "nix-command flakes" --refresh github:jcarrag/dotfiles#neovim .; \
      echo nix run --experimental-features \"nix-command flakes\" --refresh github:jcarrag/dotfiles#neovim .; \
      exec $SHELL'
    '';
}
