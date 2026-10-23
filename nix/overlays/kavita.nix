self: super:

{
  # Kavita's web reader saves its position as an xpath id("...") selector whenever the
  # element has an id. KOReader can only scroll to structural xpaths, so the stock
  # /api/koreader progress endpoint degrades those to the start of the xhtml file: open
  # a book in the browser and the next KOReader pull drags you back to the top of the
  # chapter. The patch resolves the id against the epub and returns a real path instead.
  # Built from unstable's kavita (the module wants 0.9.x); drop once upstream fixes it.
  kavita-koreader-sync = super.unstable.kavita.overrideAttrs (old: {
    backend = old.backend.overrideAttrs (b: {
      patches = (b.patches or [ ]) ++ [ ../modules/patches/kavita-koreader-id-xpath.patch ];
    });
  });
}
