self: super:

{
  # `sunsetr test` ends a session by writing the magic pair "0\n0" to the SIGUSR1
  # parameter file. If the daemon has already left test mode on its own (wake
  # from suspend, clock jump, reload) while the CLI is still running, the next
  # Ctrl+C is parsed as a fresh request for 0K @ 0% gamma and every output goes
  # black. The patch replaces the magic value with an explicit exit message that
  # the daemon ignores when it is not in test mode. Drop once upstream fixes it.
  sunsetr = super.unstable.sunsetr.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../modules/patches/sunsetr-explicit-test-exit.patch ];
  });
}
