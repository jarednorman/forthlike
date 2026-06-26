# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`forthlike` is an experimental learning project: a game built on Zig + Raylib whose game logic, entity behavior, and content are authored in a **hosted Forth dialect**. The Zig engine owns the process, frame loop, rendering, audio, and input; an embedded Forth VM (written in Zig) runs the game logic on top.

The mental model is **two machines, one membrane**: the engine is the host and drives the Forth VM as a guest, reentering it each frame, while the VM reaches back into the engine only through *primitives* (Forth words backed by Zig functions). This is experimental — the implementation is still being explored, so treat the design as open rather than settled.

Current state: the Forth layer is **not yet implemented**. `src/main.zig` is a minimal Raylib window and `src/root.zig` is a stub.

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
