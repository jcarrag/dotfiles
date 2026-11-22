self: super:

{
  # Carry HDR on gamescope's PipeWire node so Steam Remote Play can stream HDR
  # from a gamescope session: https://github.com/ValveSoftware/gamescope/issues/2126
  # Neither patch is merged upstream. Drop both once a release includes them;
  # the fetched patch will stop applying when that happens.
  # Status 2026-11-22: gamescope offers the HDR format, but Steam (beta of 2026-11-19) in a
  # gamescope session only asked for 8-bit formats, so the stream stayed SDR. Only tried with
  # SDR content; not yet tried with a game that outputs HDR.
  gamescope = super.gamescope.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # https://github.com/ValveSoftware/gamescope/pull/2270, pinned to its commit:
      # offer 10-bit xBGR_210LE tagged BT.2020/PQ when HDR output is on.
      (super.fetchpatch {
        name = "gamescope-pipewire-hdr-format.patch";
        url = "https://github.com/ValveSoftware/gamescope/commit/0d86c647eea75799bd24960970dfb7c7ceb1641a.patch";
        hash = "sha256-9y8axkoiBAxyW45YN0omxSGthEGag8WjA8Zu/XsAAdU=";
      })
      # Paint PQ-encoded pixels into that format instead of gamma 2.2 SDR.
      ../modules/patches/gamescope-pipewire-hdr-paint.patch
    ];
  });
}
