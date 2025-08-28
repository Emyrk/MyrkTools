.PHONY: test test-install test-clean help

# Default target
help:
	@echo "Available commands:"
	@echo "  make test-install  - Install busted testing framework"
	@echo "  make test          - Run all unit tests"
	@echo "  make test-clean    - Clean test artifacts"
	@echo "  make help          - Show this help message"

# Install busted testing framework
test-install:
	@echo "Installing busted testing framework..."
	@if command -v luarocks >/dev/null 2>&1; then \
		luarocks install busted; \
	else \
		echo "Error: luarocks not found. Please install luarocks first."; \
		echo "On Ubuntu/Debian: sudo apt-get install luarocks"; \
		echo "On macOS: brew install luarocks"; \
		echo "On Windows: Download from https://luarocks.org/"; \
		exit 1; \
	fi

# Run all tests
test:
	@echo "Running unit tests..."
	@if command -v busted >/dev/null 2>&1; then \
		busted --verbose; \
	else \
		echo "Error: busted not found. Run 'make test-install' first."; \
		exit 1; \
	fi

# Run tests with coverage (if available)
test-coverage:
	@echo "Running tests with coverage..."
	@if command -v busted >/dev/null 2>&1; then \
		busted --coverage --verbose; \
	else \
		echo "Error: busted not found. Run 'make test-install' first."; \
		exit 1; \
	fi

# Run specific test file
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=tests/tools_spec.lua"; \
		exit 1; \
	fi
	@echo "Running test file: $(FILE)"
	@if command -v busted >/dev/null 2>&1; then \
		busted --verbose $(FILE); \
	else \
		echo "Error: busted not found. Run 'make test-install' first."; \
		exit 1; \
	fi

# Clean test artifacts
test-clean:
	@echo "Cleaning test artifacts..."
	@rm -f luacov.*.out
	@rm -f luacov.report.out
	@echo "Test artifacts cleaned."

# Lint Lua files (if luacheck is available)
lint:
	@echo "Linting Lua files..."
	@if command -v luacheck >/dev/null 2>&1; then \
		luacheck *.lua tests/*.lua --ignore 113 --ignore 111; \
	else \
		echo "luacheck not found. Install with: luarocks install luacheck"; \
	fi

# Install development dependencies
dev-install: test-install
	@echo "Installing development dependencies..."
	@if command -v luarocks >/dev/null 2>&1; then \
		luarocks install luacheck; \
		luarocks install luacov; \
	else \
		echo "Error: luarocks not found."; \
		exit 1; \
	fi

# Run all checks (tests + lint)
check: test lint
	@echo "All checks completed."
