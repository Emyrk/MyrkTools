# Minimal shell.nix for systems where lua packages might not be available
{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    # Core Lua 5.1
    lua5_1
    
    # LuaRocks for package management
    luarocks
    
    # Build essentials
    gnumake
    gcc
    
    # Development tools
    git
    
    # Optional: if you want to install packages system-wide
    # You can also install these via luarocks in the shell
  ];
  
  shellHook = ''
    echo "🎮 MyrkTools Development Environment (Minimal)"
    echo "============================================="
    echo "Lua version: $(lua -v)"
    echo "LuaRocks version: $(luarocks --version | head -n1)"
    echo ""
    echo "Setting up local LuaRocks environment..."
    
    # Set up local luarocks tree
    export LUAROCKS_CONFIG="$PWD/.luarocks/config-5.1.lua"
    mkdir -p .luarocks
    
    # Create luarocks config for local installation
    cat > "$LUAROCKS_CONFIG" << 'EOF'
rocks_trees = {
   { name = "project", root = "./lua_modules" },
   { name = "user", root = os.getenv("HOME") .. "/.luarocks" },
}
variables = {
   LUA_DIR = "/nix/store/" .. string.match("$(which lua)", "/nix/store/([^/]+)"),
   LUA_INCDIR = "/nix/store/" .. string.match("$(which lua)", "/nix/store/([^/]+)") .. "/include",
}
EOF
    
    # Set up Lua paths
    export LUA_PATH="./?.lua;./tests/?.lua;./lua_modules/share/lua/5.1/?.lua;./lua_modules/share/lua/5.1/?/init.lua;$LUA_PATH"
    export LUA_CPATH="./lua_modules/lib/lua/5.1/?.so;$LUA_CPATH"
    
    # Add local bin to PATH
    export PATH="./lua_modules/bin:$PATH"
    
    echo "Local LuaRocks tree: ./lua_modules"
    echo ""
    echo "To install test dependencies:"
    echo "  luarocks install busted"
    echo "  luarocks install luacheck"
    echo "  luarocks install luacov"
    echo ""
    echo "Or simply run: make test-install"
    echo ""
    echo "Available commands:"
    echo "  make test          - Run all unit tests"
    echo "  make test-install  - Install test dependencies locally"
    echo "  make lint          - Lint Lua code"
    echo "  make check         - Run tests + lint"
  '';
}
