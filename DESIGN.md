---
version: alpha
name: ccLinux
description: Phosphor receipt from a kernel that thinks it's Arch. Dark TTY brand for ccLinux / pacmanlinuxcraftos.
colors:
  void: "#080A09"
  chassis: "#101412"
  panel: "#171C19"
  rule: "#2A332E"
  dim: "#6E7B73"
  mist: "#C5CEC4"
  paper: "#E8EADC"
  phosphor: "#C8F542"
  amber: "#FFB020"
  panic: "#FF3B4E"
  cyan: "#3EE0C8"
  on-phosphor: "#080A09"
  on-paper: "#080A09"
typography:
  display:
    fontFamily: Instrument Serif
    fontSize: 72px
    fontWeight: 400
    lineHeight: 0.95
    letterSpacing: -0.03em
  heading:
    fontFamily: Instrument Serif
    fontSize: 40px
    fontWeight: 400
    lineHeight: 1.1
    letterSpacing: -0.02em
  heading-sm:
    fontFamily: Instrument Serif
    fontSize: 28px
    fontWeight: 400
    lineHeight: 1.15
    letterSpacing: -0.015em
  body:
    fontFamily: IBM Plex Mono
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: -0.01em
  ui:
    fontFamily: IBM Plex Mono
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: 0.04em
  caption:
    fontFamily: IBM Plex Mono
    fontSize: 11px
    fontWeight: 500
    lineHeight: 1.35
    letterSpacing: 0.12em
rounded:
  hair: 2px
  sm: 6px
  md: 12px
  pill: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  xxl: 96px
components:
  button-primary:
    backgroundColor: "{colors.phosphor}"
    textColor: "{colors.on-phosphor}"
    rounded: "{rounded.sm}"
    padding: 10px 16px
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.mist}"
    rounded: "{rounded.sm}"
    padding: 10px 16px
  button-panic:
    backgroundColor: "{colors.panic}"
    textColor: "{colors.paper}"
    rounded: "{rounded.sm}"
    padding: 10px 16px
  card:
    backgroundColor: "{colors.chassis}"
    rounded: "{rounded.md}"
    padding: 24px
  input:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.paper}"
    rounded: "{rounded.sm}"
    padding: 12px 14px
  badge:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.dim}"
    rounded: "{rounded.hair}"
    padding: 2px 8px
  grub-selected:
    backgroundColor: "{colors.phosphor}"
    textColor: "{colors.on-phosphor}"
    rounded: "{rounded.hair}"
    padding: 8px 12px
---

# ccLinux — Style Reference

> phosphor receipt from a kernel that thinks it's Arch

**Theme:** dark
**Density:** compact
**Product:** ccLinux — GNU/Linux-like TTY for CC: Tweaked / ComputerCraft

ccLinux is not a SaaS dashboard and not a Minecraft texture pack. It is a **midnight TTY** that borrowed Arch's confidence, Linear's restraint, and a CRT's one job: make the next character readable. The canvas is near-black with a green bias (`#080A09`). Type is either Instrument Serif (display only) or IBM Plex Mono (everything else). One phosphor lime (`#C8F542`) is the flashlight — the selected GRUB row, the primary button, the cursor. Amber is warning. Panic red is fatal. Cyan is dmesg info. Nothing else is allowed to be chromatic.

This file is the brand book for humans **and** the contract for coding agents (Cursor, Claude Code, Codex, v0, Lovable). If a decision is not in this file, default to *less*.

## Atmosphere (the one sentence agents must internalize)

A kernel panic printed on thermal paper, then photographed under a green CRT. Quiet, dry, slightly arrogant — like an Arch wiki page that happens to look expensive. Texture comes from scanlines, hairline rules, and monospaced metadata — never from gradients, glassmorphism, or 3D candy.

## Tokens — Colors

| Name | Value | Token | Role |
|------|-------|-------|------|
| Void | `#080A09` | `--color-void` | Page canvas. The default everything sits on. Slightly green-black, never pure `#000`. |
| Chassis | `#101412` | `--color-chassis` | Cards, nav, terminal chrome — one step above canvas. |
| Panel | `#171C19` | `--color-panel` | Nested surfaces, input fills, code wells. |
| Rule | `#2A332E` | `--color-rule` | Hairline borders, dividers, ghost outlines. |
| Dim | `#6E7B73` | `--color-dim` | Secondary text, inactive icons, placeholders. |
| Mist | `#C5CEC4` | `--color-mist` | Body copy on dark, button labels on ghost. |
| Paper | `#E8EADC` | `--color-paper` | Headlines, high-contrast type, inverse fills. |
| Phosphor | `#C8F542` | `--color-phosphor` | **The only primary action color.** GRUB selection, CTA, caret, active tab. One per view. |
| Amber | `#FFB020` | `--color-amber` | Warnings, `--force`, uncommitted state. Never a CTA. |
| Panic | `#FF3B4E` | `--color-panic` | Destructive / kernel panic / uninstall. Never decorative. |
| Cyan | `#3EE0C8` | `--color-cyan` | Info, links, dmesg `info:` lines. Supporting only. |

### Color law

1. Phosphor appears **once per view** as a filled control. It may also tint the caret and the GRUB selected row.
2. Do not mix Phosphor + Amber + Panic on the same component.
3. Body text is Mist or Dim. Never colored body copy.
4. Do not introduce violet, pink, electric blue, rainbow, or gold-foil accents. Those belong to other products.

## Tokens — Typography

Two families. No third.

### Instrument Serif — display only · `--font-display`

- **Substitute:** Newsreader, Fraunces, or `Georgia`
- **Weight:** 400 only (italic allowed)
- **Sizes:** 28 / 40 / 72 (and 96 on the cover)
- **Tracking:** `-0.03em` at 72+, `-0.02em` at 40
- **Role:** Hero and section titles. Never buttons, never nav, never code, never badges.

### IBM Plex Mono — everything else · `--font-mono`

- **Substitute:** Geist Mono, JetBrains Mono, `ui-monospace`
- **Weights:** 400 (body), 500 (labels, selected)
- **Sizes:** 11 / 13 / 15
- **Tracking:** `0.12em` + uppercase for eyebrows/nav; `-0.01em` for body
- **Role:** UI, body, captions, buttons, tables, terminal, badges.

### Type scale

| Role | Family | Size | Weight | Line height | Tracking |
|------|--------|------|--------|-------------|----------|
| cover | Instrument Serif | 96px | 400 | 0.92 | -0.03em |
| display | Instrument Serif | 72px | 400 | 0.95 | -0.03em |
| heading | Instrument Serif | 40px | 400 | 1.1 | -0.02em |
| heading-sm | Instrument Serif | 28px | 400 | 1.15 | -0.015em |
| body | IBM Plex Mono | 15px | 400 | 1.6 | -0.01em |
| ui | IBM Plex Mono | 13px | 400 | 1.4 | 0 |
| eyebrow | IBM Plex Mono | 11px | 500 | 1.35 | 0.12em |
| terminal | IBM Plex Mono | 13px | 400 | 1.45 | 0 |

**Hard cap:** no weight ≥ 600. Serif contrast and phosphor color do the shouting.

## Tokens — Spacing & shape

**Base unit:** 4px. **Density:** compact. **Content max:** 1120px. **Section gap:** 96px. **Card padding:** 24px. **Element gap:** 8px.

| Radius | Value | Used on |
|--------|-------|---------|
| hair | 2px | badges, GRUB rows, code chips |
| sm | 6px | buttons, inputs, small cards |
| md | 12px | terminal windows, feature cards |
| pill | 9999px | status dots only — **not** buttons |

Elevation is a 1px `Rule` border, not a drop shadow. Phosphor may have a 16px glow (`0 0 24px rgba(200,245,66,0.25)`) **only** on the primary CTA and the caret.

## Components

### Primary button (Phosphor)

Fill `#C8F542`, text `#080A09`, radius 6px, padding 10×16, IBM Plex Mono 13px/500. Hover: slightly brighter, keep the glow. **One per view.**

### Ghost button

Transparent, 1px `Rule` border, text Mist, same radius/padding/type. Hover: Panel fill.

### Panic button

Fill `#FF3B4E`, text Paper. Only for uninstall / destroy / panic. Never in the header.

### Terminal window (signature)

Chassis fill, 12px radius, 1px Rule border. Title bar: three 8px dots (dim) + mono filename. Body: 13px IBM Plex Mono, Phosphor for the prompt `root@ccLinux:~#`, Mist for output, Cyan for info, Amber for warn, Panic for oops. Optional 2px scanline overlay at 4% opacity. This is the product shot — treat it like Linear treats the issue list.

### GRUB row

Unselected: transparent, Mist text, 2px radius. Selected: Phosphor fill, Void text, weight 500. This is the brand's "highlight" primitive — reuse for active nav and selected list rows.

### Card

Chassis, 12px radius, 1px Rule, 24px padding. No shadow. Nested wells use Panel.

### Input

Panel fill, 6px radius, 1px Rule, 12×14 padding, 13px mono. Focus: border Phosphor (no fat ring).

### Badge / kbd

Hair radius, Panel fill, Dim text, 11px/500, 2×8 padding. Keyboard hints use Paper on Panel.

### Eyebrow

Uppercase IBM Plex Mono 11px/500, tracking 0.12em, Dim or Phosphor. Always precedes a serif heading. Pattern: `01 — ATMOSPHERE`.

## Voice & copy

- Dry. Technical. Short. Like `man pacman`.
- Russian or English is fine; never marketing-English ("unlock your potential", "reimagine", "seamless").
- Prefer verbs the kernel would use: boot, mount, panic, sync, install.
- Product name is **ccLinux** (camel c). Repo may stay `pacmanlinuxcraftos`.
- Jokes are allowed if they fit in one line. Never a paragraph of whimsy.

## Motion

- Caret blink 1.1s step-end.
- Hover 120ms ease.
- No bounce, no elastic, no auto-playing loops longer than a blink.
- Scanlines are CSS, not a video.

## Layout

- Desktop: sticky 12-column content, left rail for section numbers on the brand book.
- Product UI (if any): single column TTY, 80-character mental model.
- Do not build a three-column SaaS marketing grid with icon-in-circle features.

## External sources — what agents may steal

Agents **should** look at these two libraries, then **restyle** to this file. Never paste a component's colors or fonts through.

### [21st.dev](https://21st.dev) — structure and craft only

**Take (layout / interaction / density):**

- ASCII / terminal heroes — [Hero ASCII one](https://21st.dev/@larsen66/components/hero-ascii-one)
- Dark compact nav + two-button hero
- Terminal-window chrome, hover-preview cards, hairline feature grids
- Subtle shader *floors* (CRT bloom under a terminal), not as the product

**Leave on 21st.dev (do not copy):**

- Rainbow border buttons, liquid metal, colourful gradient CTAs
- Glossy 3D candy, glassmorphism, aurora meshes as UI
- Playful rounded-full marketing buttons, serif-on-serif stacks that aren't ours
- Any component whose first impression is "Dribbble 2024"

Rule: steal the **skeleton**, paint it with `--color-*` from this file.

### [Refero Styles](https://styles.refero.design) — discipline

This DESIGN.md is written in Refero's agent format on purpose.

**Take the method from:**

- [Linear](https://styles.refero.design/style/90ce5883-bb24-4466-93f7-801cd617b0d1) — midnight canvas, one acid accent, hairline elevation, weight cap, "flashlight" CTA
- [Monad](https://styles.refero.design/style/fc84e9f0-2058-4a0a-8d26-9cc1ba84ec9c) — serif display at weight 400 + mono for all UI

**Do not** clone Linear's `#e4f222` or Inter, and do not clone Monad's parchment canvas. We are the TTY cousin, not a fork.

## Do

- Read this file before writing any HTML/CSS/UI.
- Use Instrument Serif at 400 for headings and IBM Plex Mono for everything else.
- Use Phosphor `#C8F542` for the single primary action per view.
- Separate surfaces with 1px `#2A332E`, not shadows.
- Keep section gaps near 96px and element gaps on the 4/8/16/24 ladder.
- Prefixed eyebrows (`01 — COLOR`) in uppercase mono.
- When you need a hero, start from a 21st.dev ASCII/terminal skeleton and retoken it.
- Put this file in context (`@DESIGN.md`) and say "strictly follow DESIGN.md".

## Don't

- Do not use Inter, Roboto, Arial, or system-ui as the primary voice.
- Do not use font-weight 600+.
- Do not use pure black `#000000` or pure white `#FFFFFF` as canvas/type (Paper is warm-green `#E8EADC`).
- Do not put gradients on buttons, cards, or headlines.
- Do not use pill-shaped (9999px) buttons — pills are for dots only.
- Do not add a second filled chromatic button in the same view.
- Do not illustrate with Minecraft Steve, Creeper, or clip-art Tux as the logo.
- Do not generate "AI purple" (`#8b5cf6`) anything.
- Do not ignore this file because the request was "make it pop".

## Agent prompt (paste)

```
Read DESIGN.md at the repo root and follow it strictly.

Visual contract:
- Canvas #080A09, surfaces #101412 / #171C19, hairline #2A332E
- Display: Instrument Serif 400. UI/body: IBM Plex Mono 400/500
- One phosphor CTA #C8F542 on #080A09 per view
- No weight 600+, no gradients on UI, no Inter, no rainbow, no liquid metal

If you need a component skeleton, take structure from 21st.dev
(ASCII hero, terminal window, dark compact cards) and restyle
every color/font/radius to DESIGN.md tokens.

If you need a taste reference, Linear + Monad on styles.refero.design
are the method, not the palette.
```

## File map

| File | Who reads it |
|------|----------------|
| `DESIGN.md` | Every coding agent. Source of truth. |
| `AGENTS.md` | Agent bootstrap — points here. |
| `brand/index.html` | Human-readable brand book (this system, rendered). |
| `.cursor/rules/design.mdc` | Cursor auto-context. |
