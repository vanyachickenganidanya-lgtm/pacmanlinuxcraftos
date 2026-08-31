PYTHON ?= python3
LUA ?= lua

.PHONY: help build check test

help:
	@echo "ccLinux targets:"
	@echo "  make build  - regenerate install.lua from startup.lua + linux/ (single-file installer)"
	@echo "  make check  - syntax-check all Lua files (luac, or luaparser via python3)"
	@echo "  make test   - host-side smoke tests (needs a lua interpreter, LUA=... to override)"

build:
	$(PYTHON) tools/build_installer.py

check:
	$(PYTHON) tools/check_lua.py

test:
	@if command -v $(LUA) >/dev/null 2>&1; then \
	    $(LUA) tools/test/test.lua; \
	else \
	    echo "no $(LUA) interpreter on PATH (set LUA=/path/to/lua) — skipping tests"; \
	fi
