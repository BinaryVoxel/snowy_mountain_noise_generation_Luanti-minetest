# Tech Stack — stone_pillars

> Approved technologies and prohibited patterns for the stone_pillars Luanti mod.

---

## Project Info

- **Project**: stone_pillars
- **Date**: 2026-02-27
- **Auto-Generated**: No (Luanti mod — manual configuration)

---

## Core Technologies

### Language
- **Lua 5.1** (LuaJIT runtime)
  - Version: 5.1 (engine-provided)
  - Notes: Luanti embeds LuaJIT; no external Lua installation needed

### Platform
- **Luanti Engine** (formerly Minetest)
  - Minimum version: 5.0+
  - API: `core.*` namespace (aliased from `minetest.*`)
  - Notes: Use `core.*` for forward compatibility

### Build Tool
- None required — Luanti loads Lua source files directly from the mod folder

### Package Manager
- None — Luanti mods are self-contained directories

---

## Engine APIs (Approved)

### Worldgen
- `core.register_on_generated` — Worldgen callback
- `VoxelManip` — Bulk node read/write
- `VoxelArea` — Index math for VoxelManip data
- `PerlinNoise` / `PerlinNoiseMap` — Noise generation
- `core.get_content_id()` — Node ID lookup (load-time only)

### Node Registration
- `core.register_node()` — Fallback node registration
- `core.registered_nodes` — Node existence checks

### Settings
- `core.settings:get()` — Read settingtypes.txt values
- `core.settings:get_bool()` — Read boolean settings

### Schematics (Optional)
- `core.place_schematic()` — Tree placement if game provides schematics

---

## Approved Patterns

### Data Structures
- Lua tables as arrays (1-indexed)
- Lua tables as hashmaps
- Flat data arrays for VoxelManip operations

### Noise Configuration
- 2D PerlinNoiseMap for cluster placement
- 2D PerlinNoise for pillar surface irregularity
- Noise parameters as table literals

### Compatibility
- `core.get_modpath("default")` — Detect Minetest Game
- `core.get_modpath("mcl_core")` — Detect MineClone/VoxeLibre
- Runtime content ID resolution based on detected game

---

## Prohibited Technologies / Patterns

### External Dependencies
- ❌ LuaRocks packages (Luanti does not support external package managers)
- ❌ FFI calls (not portable across Luanti builds)
- ❌ `os.*` or `io.*` library calls (sandboxed in Luanti)
- ❌ `require()` for external modules (use `dofile()` for mod-internal files only)

### Deprecated APIs
- ❌ `minetest.*` namespace (use `core.*` instead for forward compatibility)
- ❌ `core.env:*` legacy environment methods

### Performance Anti-Patterns
- ❌ `core.get_content_id()` inside generation loops (cache at load time)
- ❌ `core.get_node()` inside worldgen (use VoxelManip data array)
- ❌ Creating new tables inside tight loops (reuse buffers)
- ❌ `core.set_node()` for bulk operations (use VoxelManip)
- ❌ String concatenation in loops (pre-compute or use table.concat)

### Code Style
- ❌ Global variables (use `local` everywhere)
- ❌ OOP / metatables for simple data (use plain tables)
- ❌ Deeply nested callbacks (extract into named functions)

---

## Texture Requirements

### Fallback Textures (Bundled)
- `stone_pillars_stone.png` — 16x16 stone texture
- `stone_pillars_cobble.png` — 16x16 cobblestone texture
- `stone_pillars_mossycobble.png` — 16x16 mossy cobble texture
- `stone_pillars_dirt.png` — 16x16 dirt texture
- `stone_pillars_dirt_with_grass.png` — 16x16 grass-top dirt texture
- `stone_pillars_leaves.png` — 16x16 leaf texture
- `stone_pillars_tree.png` — 16x16 tree trunk texture

### Format
- PNG, 16x16 pixels (Luanti standard)
- No transparency needed for terrain nodes
- Alpha channel for leaves/vegetation only

---

## Notes

- This file was created by `/specswarm:init` for a Luanti mod project
- Luanti mods have no build step, package manager, or external dependencies
- Tech stack enforcement focuses on API usage patterns and performance anti-patterns
- Update this file when targeting new Luanti engine versions
