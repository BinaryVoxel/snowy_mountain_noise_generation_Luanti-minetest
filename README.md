<div align="center">

<h1>Snow Mountain DLA Test</h1>

<p><em>Fractal mountains grown from nothing but random walks and patience</em></p>

<a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-4a90d9?style=flat-square" alt="License: MIT"></a>
<img src="https://img.shields.io/badge/Engine-Luanti_5.0+-6cb4ee?style=flat-square" alt="Engine: Luanti 5.0+">
<img src="https://img.shields.io/badge/Language-Lua_5.1-8ec8f0?style=flat-square" alt="Language: Lua 5.1">

</div>

<br>

<!-- Uncomment when screenshot is added
<div align="center">
<img src="screenshots/hero.png" alt="A DLA-grown mountain rising from infinite snow plains" width="80%">
<br>
<em>A DLA-grown mountain rising from infinite snow plains</em>
</div>
-->

*Screenshots coming soon — the mountain generates a unique fractal shape every world.*

<hr>

## Features

| Terrain | Technical |
|---------|-----------|
| DLA branching ridges with natural erosion patterns | 801x801 heightmap from five resolution layers |
| 250-block peak rising from flat terrain | Singlenode mapgen for full terrain control |
| Snow, dirt, and stone layering by altitude | Minetest Game + MineClone + standalone support |
| Infinite snow plains surrounding the mountain | Configurable settings via Luanti settings UI |

<hr>

## Quick Start

```
git clone https://github.com/BinaryVoxel/snowy_mountain_noise_generation_Luanti-minetest.git
```

1. Clone or download into your Luanti `mods/` folder
2. Enable the mod when creating a new world (use **singlenode** mapgen)
3. Wait ~15 seconds for DLA precomputation, then explore

<hr>

## Compatibility

| Game | Status | Nodes Used |
|------|--------|------------|
| Minetest Game | Supported | `default:stone`, `default:dirt`, `default:snow`, etc. |
| MineClone / VoxeLibre | Supported | `mcl_core:stone`, `mcl_core:dirt`, `mcl_core:snow`, etc. |
| Standalone | Supported | Bundled fallback nodes (no game dependency) |

The mod auto-detects which game is active at load time.

<hr>

## How It Works

Diffusion-Limited Aggregation (DLA) grows a branching cluster by releasing random walkers that stick on contact with an existing structure. The mod runs five DLA passes at doubling resolutions (51x51 through 801x801), each adding finer ridge detail. Bilinear upscaling and box blur smooth the transitions between layers, preventing blocky artifacts. A radial gradient shapes the combined heightmap into a central peak. Precomputation takes ~10-30 seconds on first world load.

<hr>

## Configuration

Settings are available in the Luanti settings UI under the mod's section.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `dla_mountain_enabled` | bool | `true` | Master toggle to enable or disable the mod |
| `dla_mountain_peak_height` | int | `250` | Maximum height of the mountain peak in blocks (50-500) |
| `dla_mountain_walker_multiplier` | float | `1.0` | Scales DLA walker count per layer; higher = more detail, slower precomputation (0.1-3.0) |
| `dla_mountain_snow_plain_enabled` | bool | `true` | Whether to generate the flat snow plain surrounding the mountain |

<hr>

## License and Credits

Released under the [MIT License](LICENSE). Created by BinaryVoxel with AI-assisted development.

<div align="center">
<br>
<em>Built with procedural generation and mass random walks</em>
<br><br>
</div>
