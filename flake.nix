{
  description = "1password-backup";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.onepassword-flake.url = "github:heywoodlh/flakes?dir=1password";

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    onepassword-flake,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      onepassword-wrapper = onepassword-flake.packages.${system}.default;
    in {
      devShell = pkgs.mkShell {
        name = "1password-backup-shell";
        buildInputs = with pkgs; [
          coreutils
          gnused
          jq
          pass
        ];
      };

      formatter = pkgs.alejandra;
    });
}
