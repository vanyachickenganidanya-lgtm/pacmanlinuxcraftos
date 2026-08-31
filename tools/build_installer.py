#!/usr/bin/env python3
"""Rebuild install.lua (single-file installer) from the source tree.

Source of truth:
  startup.lua            -> /startup.lua
  linux/<module>.lua     -> /linux/<module>.lua
  linux/rootfs/etc/*     -> /linux/rootfs/etc/*

The installer's logic lives in tools/install_template.lua; only the
embedded `files` table is regenerated from the files above, so the
installer stays a single file you can paste onto a CC: Tweaked computer.

Usage:
    python3 tools/build_installer.py [output-file]
"""

import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, "tools", "install_template.lua")
OUTPUT = os.path.join(ROOT, "install.lua")

# Ordered (repo path -> virtual path) — matches the installed system.
SOURCES = [
    ("startup.lua", "/startup.lua"),
    ("linux/boot.lua", "/linux/boot.lua"),
    ("linux/kernel.lua", "/linux/kernel.lua"),
    ("linux/panic.lua", "/linux/panic.lua"),
    ("linux/vfs.lua", "/linux/vfs.lua"),
    ("linux/shell.lua", "/linux/shell.lua"),
    ("linux/commands.lua", "/linux/commands.lua"),
    ("linux/extra.lua", "/linux/extra.lua"),
    ("linux/pacman.lua", "/linux/pacman.lua"),
    ("linux/dos.lua", "/linux/dos.lua"),
    ("linux/rootfs/etc/os-release", "/linux/rootfs/etc/os-release"),
    ("linux/rootfs/etc/motd", "/linux/rootfs/etc/motd"),
]

MARKER = "@@FILES@@"


def fail(msg):
    sys.exit("build_installer: " + msg)


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else OUTPUT
    with io.open(TEMPLATE, "r", encoding="utf-8", newline="") as fh:
        tpl = fh.read()
    if MARKER not in tpl:
        fail("template %s is missing %s" % (TEMPLATE, MARKER))

    entries = []
    for rel, vpath in SOURCES:
        p = os.path.join(ROOT, rel)
        if not os.path.isfile(p):
            fail("missing source file: %s" % rel)
        with io.open(p, "r", encoding="utf-8", newline="") as fh:
            data = fh.read()
        if "\r" in data:
            fail("%s: CRLF/CR line endings are not allowed" % rel)
        if "]===]" in data:
            fail('%s: contains the long-string terminator "]===]"' % rel)
        if not data.endswith("\n"):
            data += "\n"
        entries.append('    { "%s", [===[\n%s]===] },\n' % (vpath, data))

    table = "".join(entries)
    idx = tpl.index(MARKER)
    result = tpl[:idx] + table + tpl[idx + len(MARKER):]

    with io.open(out_path, "w", encoding="utf-8", newline="") as fh:
        fh.write(result)
    print("wrote %s (%d files embedded, %d bytes)"
          % (os.path.relpath(out_path, ROOT), len(SOURCES), len(result)))


if __name__ == "__main__":
    main()
