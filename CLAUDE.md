# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`forthlike` is an experimental learning project: a game/game engine built on Zig + Raylib whose game logic, entity behavior, and content are authored in a **hosted Forth dialect**. This is meant to be something like Love2D, but swap Lua for Forth.

The mental model is **two machines, one membrane**: the engine is the host and drives the Forth VM as a guest, reentering it each frame, while the VM reaches back into the engine only through *primitives* (Forth words backed by Zig functions). This is experimental; the implementation is still being explored, so treat the design as open rather than settled.

One boundary is settled: the `forthlike` module (the Forth core, rooted at `src/root.zig`) **never imports raylib**. Engine-facing words are installed from the executable's side of the membrane via `defineWord`; they do not go in the core's builtin table.

## How to help

This is a **learning exercise for the user**, who is new to both Forth and Zig. The user writes the code themselves. By default, **do not write or edit code** in `src/` (or other source files) — no unprompted first drafts, scaffolding, or example slices meant to be pasted in.

Your default role is **guidance**: explain concepts, point to the next concrete step, sketch the *shape* of a solution in prose (name the pieces, their responsibilities, how they fit), review code the user has written, and answer questions. When tempted to show code, describe it instead and let the user write it.

The exception is when the user **explicitly asks** for code generation or an edit — then it's fine to provide it. Only write or suggest source edits on explicit request; never volunteer them. (Editing non-source docs like this file when asked is always fine.)

## Toolchain

- Zig and ZLS are managed by **mise** (`mise.toml`, both `latest`; currently Zig **0.16.0**). Zig is pre-1.0 and this tracks `latest`, so **verify `comptime`/build-system syntax against the installed version rather than assuming**.
- Dependency: `raylib-zig` 6.0.0, git-pinned in `build.zig.zon`; it builds Raylib from C source, so the **first build is slow**, then cached.
- `.zig-cache/`, `zig-out/`, and the dependency cache `zig-pkg/` are gitignored.

## Version control

This repo uses **Jujutsu (`jj`), not git** (note the `.jj/` directory). Use `jj` commands. jj auto-snapshots the whole working copy on every command, so keep build/cache dirs gitignored.

## Commands

- `zig build run` — build and launch the game window (`zig build run -- <args>` to pass args)
- `zig build` — build and install the executable to `zig-out/`
- `zig build test` — run tests
- `zig test src/<file>.zig --test-filter "<name>"` — compile and run one file's tests, optionally filtered to a single test
