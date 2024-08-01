{
  description = "Stable Diffusion LoRA training tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/7b75a79581cfa1cfd676b5b85d6a8ed772635c13";
    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    yaml2nix.url = "github:euank/yaml2nix";
    yaml2nix.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    yaml2nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [
          (final: prev: {
            inherit (import yaml2nix) yaml2nix;
            python3Packages = prev.python3Packages.overrideScope (pyPkgsFinal: pyPkgsPrev: let
              pyPkgs = {
                torch =
                  pyPkgsPrev.torch-bin
                  // {
                    # bitsandbytes assumes that these attributes are present
                    inherit (pyPkgsPrev.torch) cudaCapabilities cudaPackages;
                    cudaSupport = true;
                    rocmSupport = false;
                  };
                torchvision = pyPkgsPrev.torchvision-bin;
                prodigyopt = pyPkgsFinal.callPackage ./packages/prodigyopt {};
              };
            in
              pyPkgs
              // {
                # both necessary?
                python = pyPkgsPrev.python.override {packageOverrides = _: _: pyPkgs;};
                python3 = pyPkgsFinal.python;
              });
          })
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
        pythonPkgs = pkgs.python3Packages;
        fetchFromHuggingFace = pkgs.callPackage ./lib/fetchFromHuggingFace.nix {};
        invoke-training = pythonPkgs.callPackage ./packages/invoke-training {};
        # the result of running invoke-training on a config
        invoke-train-on-cfg = pkgs.callPackage ./lib/invoke-train-on-cfg {inherit invoke-training;};
        # script to extract appropriately cropped faces
        face-extractor = pythonPkgs.callPackage ./packages/face-extractor {
          classifier-xml = ./packages/face-extractor/haarcascade_frontalface_default.xml;
        };
      in {
        inherit overlays;
        lib = {
          # TODO: add cfg2nix
          inherit
            fetchFromHuggingFace
            invoke-train-on-cfg
            ;
        };
        packages = {
          inherit
            invoke-training
            face-extractor
            ;
          invoke-trained-example = invoke-train-on-cfg {
            name = "sd_lora_baroque_1x8gb";
            cfg = import ./lib/invoke-train-on-cfg/sample_configs/sd_lora_baroque_1x8gb.nix {inherit invoke-training fetchFromHuggingFace;};
          };
          default = invoke-training;
          # same as face-extractor but extracts bodies (doesn't work very well though)
          full-body-extractor = face-extractor.override {
            classifier-xml = ./packages/face-extractor/haarcascade_fullbody.xml;
          };
        };
      }
    );
}
