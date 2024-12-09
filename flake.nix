{
  description = "STM32 Development Environment Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # STM32 Toolchain and Development Tools
        stm32Toolchain = with pkgs; [
          clang-tools
          clang
          gnumake
          gcc-arm-embedded # ARM embedded GCC compiler
          openocd # Open On-Chip Debugger
          stlink # ST-LINK/V2 USB driver and tools
          cmake # Build system
          gdb # GNU Debugger
          picocom # Serial communication
        ];

        # Python tools for STM32 development
        # pythonEnv = pkgs.python3.withPackages (
        #   ps: with ps; [
        #     pyserial # Serial port communication
        #     intelhex # Intel HEX file support
        #   ]
        # );

      in
      {
        # Development shell configuration
        devShells.default = pkgs.mkShell {
          buildInputs = stm32Toolchain ++ [
            # pythonEnv
          ];

          # Environment variables and shell hooks
          shellHook = ''
            echo "STM32 Development Environment"
            echo "Toolchain versions:"
            arm-none-eabi-gcc --version
            openocd --version
          '';

        };
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "stm32-template";
          version = "0.1.0";

          # Source configuration
          src = ./.;

          nativeBuildInputs = stm32Toolchain;

        };
      }
    );
}
