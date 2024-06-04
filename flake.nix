{
  description = "Nix packaging for MultiversX SDK tools";

  inputs = {
    rv-utils.url = "github:runtimeverification/rv-nix-tools";
    nixpkgs.follows = "rv-utils/nixpkgs";
    cargo2nix.url = "github:cargo2nix/cargo2nix/release-0.11.0";
    flake-utils.follows = "cargo2nix/flake-utils";
    mx-sdk-rs-src = {
      url = "github:multiversx/mx-sdk-rs/v0.50.3";
      flake = false;
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, rv-utils, nixpkgs, cargo2nix, flake-utils, mx-sdk-rs-src, rust-overlay }:
  let
    overlay = (final: prev:
      let
        pkgs = import nixpkgs {
          inherit (prev) system;
          overlays = [
            cargo2nix.overlays.default
            rust-overlay.overlays.default
          ];
        };
      in {
        rustPkgs = pkgs.rustBuilder.makePackageSet {
          packageFun = import ./Cargo.nix;
          rustVersion = "1.78.0";
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

        contracts = pkgs.stdenv.mkDerivation {
          pname = "mx-sdk-contracts";
          version = "0.50.3";
          src = mx-sdk-rs-src;
          dontBuild = true;
          installPhase = ''
            mkdir $out
            cp -R contracts/* $out
          '';
        };

        make-test = sc-meta: pkgs.stdenv.mkDerivation {
          pname = "sc-meta-test";
          version = "0";
          buildInputs = [ sc-meta pkgs.coreutils ];
          unpackPhase = "true";
          buildPhase = "sc-meta --version | grep 0.50.3";
          installPhase = "touch $out";
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
          inherit (pkgs) contracts;
          sc-meta = (pkgs.rustPkgs.workspace.multiversx-sc-meta {});
          test = pkgs.make-test packages.sc-meta;
          default = packages.sc-meta;
        };
    }) // {
      overlays.default = overlay;
    };
}
