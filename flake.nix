{
  description = "1password-backup";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      devShell = pkgs.mkShell {
        name = "1password-backup-shell";
        buildInputs = with pkgs; [
          _1password
          coreutils
          gnused
          jq
        ];
      };

      formatter = pkgs.alejandra;
    });
}
