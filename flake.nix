{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    cargo2nix.url = "github:cargo2nix/cargo2nix/release-0.11.0";
    flake-utils.follows = "cargo2nix/flake-utils";
    mx-sdk-rs-src = {
      url = "github:multiversx/mx-sdk-rs/v0.48.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, cargo2nix, flake-utils, mx-sdk-rs-src }:
  let
    overlay = (final: prev:
      let
        pkgs = import nixpkgs {
          inherit (prev) system;
          overlays = [ cargo2nix.overlays.default ];
        };
      in {
        rustPkgs = pkgs.rustBuilder.makePackageSet {
          packageFun = import ./Cargo.nix;
          rustChannel = "nightly";
          rustVersion = "2023-12-11";
          workspaceSrc = mx-sdk-rs-src;

          packageOverrides = pkgs: pkgs.rustBuilder.overrides.all ++ [
            (pkgs.rustBuilder.rustLib.makeOverride {
                name = "multiversx-sc-meta";
                overrideAttrs = drv: {
                  nativeBuildInputs = drv.nativeBuildInputs or [ ] ++
                    pkgs.lib.optionals pkgs.stdenv.targetPlatform.isDarwin [
                      pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
                    ];
                };
            })
          ];
        };
    });
  in flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in rec {
        packages = {
          sc-meta = (pkgs.rustPkgs.workspace.multiversx-sc-meta {});
          default = packages.sc-meta;
        };
    }) // {
      overlays.default = overlay;
    };
}
