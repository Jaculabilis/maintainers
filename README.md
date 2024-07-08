# maintainers

This flake provides two [Nix bundlers](https://github.com/NixOS/bundlers) that compile information about the maintainership of packages.

Usage:

```
nix bundle --bundler github:Jaculabilis/maintainers [installable]
```

where `installable` is a flake reference to a derivation or a NixOS configuration. For example, if you have NixOS configs on GitHub, you would use `github:myusername/nixos-configs#nixosConfigurations.mycomputer`. If your configs are elsewhere, you could use the more generic `git+https://git.example.com/myusername/nixos-configs#nixosConfigurations.mycomputer`, or even run against a local checkout using `path:.#nixosConfigurations.mycomputer`.

The default bundler is `#unmaintained`. You can specify a bundler by name using `--bundler github:Jaculabilis/maintainers#bundlername`.

## Bundlers

### unmaintained

This bundler accepts a derivation or a NixOS configuration and returns a report containing a list of derivations in the closure of the input that have no maintainer in nixpkgs. (Put simply: it returns a list of unmaintained dependency packages.) Each package is accompanied by a link to the package source in nixpkgs. If you see a package in your report that you care about, sign up as a maintainer!

Note that many derivations have no `.meta.maintainers`, e.g. `fetchTarball`. This list specificaly includes packages that _have_ a `.meta.maintainers` that is empty.

### all

This bundler accepts a derivation or a NixOS configuration and returns a report containing a list of every derivation in the closure of the input and the GitHub usernames of the maintainers. You can use this to see if there are packages you depend on that could use some additional maintainership, e.g. yours!
