# `sc-meta` Nix Flake

This repository packages the MultiversX
[`sc-meta`](https://docs.multiversx.com/developers/meta/sc-meta/) tool as a Nix
flake so that it can be used in downstream projects at RV.

The packaging closely follows the example given by the [`cargo2nix`
documentation](https://github.com/cargo2nix/cargo2nix/tree/release-0.11.0/examples/4-independent-packaging);
to prepare a new version of this repository when the MultiversX SDK needs to be
updated:
```console
$ git clone git@github.com:multiversx/mx-sdk-rs.git
$ cd mx-sdk-rs
$ git checkout "v${VERSION}"
$ nix develop github:cargo2nix/cargo2nix#bootstrap
$ cargo2nix --locked
$ cp Cargo.nix ../mx-sdk-rs-flake
```

At this point, the Cargo dependencies of the updated SDK version are present in
this repo. Also update:
* The versioned flake input URL pointing to the SDK source code
* The version check in the `test` package

When a PR that updates the SDK version is merged to this repo, also create a
GitHub release with the same version so that downstream repos can reference a
single shared version between the SDK package and this Nix packaging.
