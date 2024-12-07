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
          gcc-arm-embedded # ARM embedded GCC compiler
          openocd # Open On-Chip Debugger
          stlink # ST-LINK/V2 USB driver and tools
          cmake # Build system
          gdb # GNU Debugger
          picocom # Serial communication
        ];

        # Python tools for STM32 development
        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            pyserial # Serial port communication
            intelhex # Intel HEX file support
          ]
        );

      in
      {
        # Development shell configuration
        devShells.default = pkgs.mkShell {
          buildInputs = stm32Toolchain ++ [
            pythonEnv
          ];

          # Environment variables and shell hooks
          shellHook = ''
            echo "STM32 Development Environment"
            echo "Toolchain versions:"
            arm-none-eabi-gcc --version
            openocd --version
          '';

          # Additional development tools configuration
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
        };
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "stm32-template";
          version = "0.1.0";

          src = ./.;

          nativeBuildInputs = stm32Toolchain;

          buildPhase = ''
            # Create output directories
            mkdir -p $out/bin

            # Compilation Flags for STM32F4
            CFLAGS="-mcpu=cortex-m4 \
                    -mthumb \
                    -Wall \
                    -g \
                    -O2 \
                    -ffunction-sections \
                    -fdata-sections"

            # Compile object file
            arm-none-eabi-gcc $CFLAGS \
              -c main.c \
              -o main.o

            # Generate executable
            arm-none-eabi-gcc $CFLAGS \
              main.o \
              -o $out/bin/main.elf \
              -Wl,--gc-sections \
              -T STM32F411CEUx_FLASH.ld

            # Generate binary and hex files
            arm-none-eabi-objcopy -O binary $out/bin/main.elf $out/bin/main.bin
            arm-none-eabi-objcopy -O ihex $out/bin/main.elf $out/bin/main.hex
          '';
        };
      }
    );
}
