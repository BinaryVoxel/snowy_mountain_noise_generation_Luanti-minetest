# Project Constitution — stone_pillars

> Governance and coding principles for the stone_pillars Luanti mod.

---

## Project Overview

- **Name**: stone_pillars
- **Type**: Luanti (Minetest) game mod
- **Language**: Lua 5.1 (LuaJIT)
- **Platform**: Luanti engine (formerly Minetest)
- **Created**: 2026-02-27

## Core Principles

### 1. Performance First
Every node placement, noise calculation, and VoxelManip operation runs inside the worldgen callback. Minimize allocations, reuse buffers, cache content IDs at load time, and exit early when no work is needed. Never look up node IDs inside a generation loop.

### 2. Game Compatibility
Support Minetest Game (`default` mod), MineClone/VoxeLibre (`mcl_core` mod), and a standalone fallback mode with bundled textures. All three code paths must work identically. Use runtime detection, never hard-code game-specific node names.

### 3. Clean Lua Patterns
Write idiomatic Lua 5.1. Use local variables for performance. Avoid global pollution — scope everything inside the mod namespace. Prefer simple data structures (tables, arrays) over complex OOP patterns. Keep functions short and single-purpose.

### 4. Configurable by Design
Every tunable parameter (rarity, dimensions, vegetation toggle, etc.) must be exposed in `settingtypes.txt` with proper type annotations, defaults, and min/max ranges. Read all settings once at load time and cache them.

### 5. Documented and Readable
Each major function gets a brief comment explaining its purpose. The README documents installation, settings, compatibility, and license. Code should be self-explanatory through clear naming and logical structure.

## Coding Standards

- **Indentation**: Tabs (Luanti convention)
- **Naming**: `snake_case` for variables and functions
- **Line length**: 120 characters max
- **Comments**: Brief, explaining *why* not *what*
- **Error handling**: Graceful degradation — skip features if nodes/mods are missing, never crash

## File Structure Convention

```
stone_pillars/
  mod.conf            -- Mod metadata
  init.lua            -- Entry point, game detection, settings
  settingtypes.txt    -- User-configurable settings
  textures/           -- Fallback textures
  README.md           -- Documentation
  LICENSE             -- License file
```

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-27 | Lua 5.1 / LuaJIT | Luanti engine requirement |
| 2026-02-27 | VoxelManip API | Only viable approach for bulk worldgen |
| 2026-02-27 | Perlin noise for placement | Engine-native, deterministic, performant |
| 2026-02-27 | Fallback nodes for standalone | Enables use without MTG or MineClone |
