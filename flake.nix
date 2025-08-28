{
  description = "MyrkTools WoW Addon Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Lua 5.1 ecosystem
            lua5_1
            lua51Packages.luarocks
            lua51Packages.busted
            lua51Packages.luacheck
            lua51Packages.luacov
            
            # Build tools
            gnumake
            gcc
            
            # Development tools
            git
          ];
          
          shellHook = ''
            echo "🎮 MyrkTools Development Environment (Flake)"
            echo "==========================================="
            echo "Lua: $(lua -v)"
            echo "LuaRocks: $(luarocks --version | head -n1)"
            echo "Busted: $(busted --version 2>/dev/null || echo 'Available')"
            echo ""
            echo "Available commands:"
            echo "  make test          - Run all unit tests"
            echo "  make lint          - Lint Lua code"
            echo "  make check         - Run tests + lint"
            echo "  make help          - Show all commands"
            echo ""
            
            # Set up Lua paths
            export LUA_PATH="./?.lua;./tests/?.lua;$LUA_PATH"
          '';
        };
        
        # Alternative minimal shell for compatibility
        devShells.minimal = pkgs.mkShell {
          buildInputs = with pkgs; [
            lua5_1
            luarocks
            gnumake
            gcc
            git
          ];
          
          shellHook = ''
            echo "🎮 MyrkTools Development Environment (Minimal Flake)"
            echo "================================================="
            echo "Run 'make test-install' to install test dependencies"
            echo ""
            
            # Set up local luarocks
            export LUA_PATH="./?.lua;./tests/?.lua;./lua_modules/share/lua/5.1/?.lua;$LUA_PATH"
            export LUA_CPATH="./lua_modules/lib/lua/5.1/?.so;$LUA_CPATH"
            export PATH="./lua_modules/bin:$PATH"
          '';
        };
      }
    );
}
