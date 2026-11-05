self: super:

{
  # Log capture-thread errors via frigate.video.<camera> instead of the shared
  # frigate.video logger, so one camera (iphone) can be muted via logger.logs.
  frigate = super.frigate.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../modules/patches/frigate-per-camera-capture-logger.patch
    ];
  });
}
