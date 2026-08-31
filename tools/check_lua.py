#!/usr/bin/env python3
"""Syntax-check all Lua files in the repo.

Tries a real Lua compiler first (luac5.2 / luac5.3 / luac5.4 / luac,
`luac -p`); falls back to the pure-python `luaparser` package.

Exit code 0 = all files parse.
"""

import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Not real Lua: install_template.lua is a template with a @@FILES@@ marker,
# it only becomes valid Lua after tools/build_installer.py runs.
SKIP = {os.path.join("tools", "install_template.lua")}


def find_luac():
    for name in ("luac5.2", "luac5.3", "luac5.4", "luac"):
        path = shutil.which(name)
        if path:
            return path
    return None


def find_lua():
    for name in ("lua5.2", "lua5.3", "lua5.4", "lua"):
        path = shutil.which(name)
        if path:
            return path
    return None


def lua_files():
    out = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules", "__pycache__")]
        for f in filenames:
            if f.endswith(".lua"):
                path = os.path.join(dirpath, f)
                rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
                if rel in SKIP:
                    continue
                out.append(path)
    return sorted(out)


def main():
    files = lua_files()
    if not files:
        sys.exit("no .lua files found")

    luac = find_luac()
    lua = find_lua()
    parser = None
    if not luac and not lua:
        try:
            from luaparser import ast  # noqa: F401
            parser = ast
        except ImportError:
            sys.exit("no luac*/lua interpreter found and luaparser is not installed\n"
                     "  install one of: apt install lua5.2  /  pip install luaparser")

    check_expr = 'assert(loadfile(os.getenv("CC_CHECK_FILE")))'

    failed = 0
    for f in files:
        rel = os.path.relpath(f, ROOT)
        if luac:
            r = subprocess.run([luac, "-p", f], capture_output=True, text=True)
            if r.returncode != 0:
                failed += 1
                print("FAIL %s" % rel)
                for line in (r.stderr or "").strip().splitlines():
                    print("     " + line)
            else:
                print("ok   %s" % rel)
        elif lua:
            env = dict(os.environ, CC_CHECK_FILE=f)
            r = subprocess.run([lua, "-e", check_expr], env=env,
                               capture_output=True, text=True)
            if r.returncode != 0:
                failed += 1
                print("FAIL %s" % rel)
                for line in (r.stderr or "").strip().splitlines():
                    print("     " + line)
            else:
                print("ok   %s" % rel)
        else:
            with io_open(f) as fh:
                src = fh.read()
            try:
                parser.parse(src)
                print("ok   %s" % rel)
            except Exception as e:
                failed += 1
                print("FAIL %s: %s" % (rel, e))
    sys.exit(1 if failed else 0)


def io_open(path):
    import io
    return io.open(path, "r", encoding="utf-8")


if __name__ == "__main__":
    main()
