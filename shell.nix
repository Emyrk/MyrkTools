{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    # Lua 5.1 (required for WoW addon compatibility)
    lua5_1
    
    # LuaRocks package manager
    lua51Packages.luarocks
    
    # Testing framework
    lua51Packages.busted
    
    # Development tools
    lua51Packages.luacheck  # Lua linter
    lua51Packages.luacov    # Code coverage
    
    # Build tools
    gnumake
    
    # Git for version control
    git
  ];
  
  shellHook = ''
    echo "🎮 MyrkTools Development Environment"
    echo "===================================="
    
    # Create a local bin directory and symlink lua to lua5.1
    mkdir -p .nix-shell-bin
    ln -sf $(which lua) .nix-shell-bin/lua5.1
    export PATH="$PWD/.nix-shell-bin:$PATH"
    
    echo "Lua version: $(lua -v)"
    echo "Lua5.1 available: $(lua5.1 -v 2>/dev/null || echo 'Creating symlink...')"
    echo "LuaRocks version: $(luarocks --version | head -n1)"
    echo "Busted version: $(busted --version 2>/dev/null || echo 'Available')"
    echo ""
    echo "Available commands:"
    echo "  make test          - Run all unit tests"
    echo "  make test-install  - Install additional test dependencies"
    echo "  make lint          - Lint Lua code"
    echo "  make check         - Run tests + lint"
    echo "  make help          - Show all available commands"
    echo ""
    
    # Set up Lua path for local modules
    export LUA_PATH="./?.lua;./tests/?.lua;$LUA_PATH"
    
    # Ensure luarocks can install packages locally if needed
    export LUAROCKS_CONFIG="$PWD/.luarocks/config.lua"
    mkdir -p .luarocks
    
    # Create local luarocks config if it doesn't exist
    if [ ! -f "$LUAROCKS_CONFIG" ]; then
      cat > "$LUAROCKS_CONFIG" << EOF
rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/nix/store" };
}
EOF
    fi
  '';
  
  # Environment variables
  NIX_SHELL_PRESERVE_PROMPT = 1;
}