# Agent bootstrap

You are working on **ccLinux** (`pacmanlinuxcraftos`).

## Visual identity (mandatory)

Read [`DESIGN.md`](./DESIGN.md) before any UI.

Brand in one line: **Shizuku running on a ComputerCraft monitor.**

- Pixel fonts only (Pixelify Sans / Monocraft / Unbounded). Sizes 12 / 16 / 24 / 32 / 48 / 64.
- Booleans = Material 3 switches (52×32, phosphor when ON) in Android Settings / Shizuku preference rows.
- Icons = 16×16 or 32×32, `image-rendering: pixelated`. Recreate Minecraft blocks. Do not commit Mojang jar files.
- Open source: credit, GPL/MIT/Apache. Steal internet assets with a source line.

No Inter, no serif, no iOS toggles, no rainbow, no liquid metal.

## Steal list

- Controls: AOSP Settings, [Shizuku](https://github.com/RikkaApps/Shizuku)
- Assets: Minecraft 16×16 language (recreate) + credited internet files
- Skeletons: [21st.dev](https://21st.dev) ASCII/terminal
- Method: [Refero Styles](https://styles.refero.design) DESIGN.md — not their palettes

## Product facts (do not invent)

ccLinux is a GNU/Linux-like **TTY** for CC: Tweaked. No GUI. GRUB, kernel, pacman, bash-like shell. Code in `linux/`. `make build` regenerates `install.lua`.

Human brand book: `brand/index.html`.
