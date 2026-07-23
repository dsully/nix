{lib}: {
  # Recursively drop attributes whose value is null, and prune attrsets that
  # become empty as a result. Used so unset typed options never appear in the
  # generated config.json, leaving zaly's own defaults in force.
  filterNull = let
    go = attrs:
      lib.filterAttrs (_: v: v != null && v != {}) (
        lib.mapAttrs (
          _: v:
            if builtins.isAttrs v && !lib.isDerivation v
            then go v
            else v
        )
        attrs
      );
  in
    go;
}
