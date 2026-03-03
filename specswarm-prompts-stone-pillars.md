# stone_pillars — SpecSwarm Prompt List

A sequence of human-language prompts for building the stone_pillars Luanti mod using SpecSwarm. Each prompt is a self-contained feature or milestone. Work through them in order since later prompts build on earlier ones.

---

## Prompt 1 — Project Skeleton and Game Detection

Set up the stone_pillars Luanti mod with its basic file structure: mod.conf, init.lua, settingtypes.txt, a textures folder, README, and LICENSE. In init.lua, write the startup logic that detects whether the Minetest Game ("default" mod) or MineClone/VoxeLibre ("mcl_core" mod) is loaded. Store which game was found so the rest of the mod knows which node names to use. If neither game is detected, register minimal fallback nodes for stone, cobble, mossy cobble, dirt, and dirt with grass, using simple bundled textures in the textures folder. Also read all user-configurable settings from settingtypes.txt at load time with sensible defaults: cluster rarity (default 400), min/max pillars per cluster (10/30), min/max pillar height (60/100), min/max pillar radius (4/7), and a vegetation toggle (default on). Cache all content IDs for every node the mod will use at load time so they are never looked up inside the generation loop.

---

## Prompt 2 — Cluster Placement Noise and Worldgen Hook

Register a worldgen callback using core.register_on_generated. Inside it, set up a two-tier Perlin noise system. The first tier is a large-scale "cluster noise" that decides whether the current map chunk contains a pillar cluster. Sample this noise at the center of the chunk and compare it against a threshold derived from the cluster rarity setting. If the noise says no cluster here, return immediately without touching the VoxelManip so there is zero performance cost for empty chunks. When a cluster is present, use a second smaller-scale noise layer to scatter individual pillar positions within the chunk footprint. Respect the min/max pillars-per-cluster settings. For each pillar, record its x,z position, a randomized height between the min and max height settings, and a randomized radius between the min and max radius settings, making sure the height-to-width aspect ratio is always at least 4 to 1. Also check the biome map and skip any position that falls in an ocean or underground biome. Store all pillar positions in a list for the next step to consume.

---

## Prompt 3 — Basic Pillar Shape Generation

Using the pillar position list from the worldgen hook, generate each pillar into the VoxelManip data array. For each pillar, read the heightmap to find the ground level at its x,z center and use that as the base. Build the pillar upward from the base. At each vertical slice, compute the radius for that height using these rules: the bottom 10 percent of the pillar flares out by 1 to 3 extra blocks, the middle section holds steady at the base radius, and the top 20 percent tapers inward losing 1 to 3 blocks. Apply 2D Perlin noise to the radius at each slice so the cross-section is an irregular rounded shape rather than a perfect circle, with noise displacing the edge by up to 1 to 2 blocks in or out. Only write stone nodes into positions that currently contain air or the mapgen ignore node, and do not destroy existing terrain except at the base where the pillar should merge seamlessly into the ground. After all pillars are written, call calc_lighting once and write the data back to the map.

---

## Prompt 4 — Surface Detail and Erosion Features

Add visual variety to the pillar surfaces. After filling each pillar's interior with stone, go back over the outermost layer of nodes on each pillar and randomly replace some of them: about 15 percent should become cobble (weighted more heavily toward the lower half of the pillar) and about 15 percent should become mossy cobble (also weighted toward the lower half and any north-facing surfaces to suggest shade). The remaining 70 percent stays as plain stone. Also carve vertical erosion grooves into the surface: for roughly 20 percent of the pillar's circumference angles, cut a narrow channel 1 block deep and 1 to 2 blocks wide that runs most of the pillar's height, simulating water erosion. For 10 to 15 percent of pillars, add a subtle overhang near the top where one or two vertical slices have a radius 1 to 2 blocks wider than the section immediately below them.

---

## Prompt 5 — Flat Tops with Soil and Vegetation

Give each pillar a naturalistic flat top. Identify all the topmost stone nodes of each pillar and place a 1 to 2 block layer of dirt on top, capped with dirt-with-grass. On this soil surface, place 1 to 3 small trees. If the host game provides a tree schematic, use it; otherwise build a simple tree with a 4 to 6 block tall trunk and a cluster of leaf nodes on top. Only place trees where there are at least 8 blocks of air above the planting spot. Scatter a few grass or flower decorations on the remaining top surface if those nodes are available in the host game. If the vegetation setting is turned off, skip all vegetation placement but still place the soil cap.

---

## Prompt 6 — Side Vegetation: Vines, Moss, and Ledge Plants

Add vegetation to the vertical faces of each pillar. Select 10 to 20 percent of exposed side-face positions, concentrated in the upper half of the pillar, and place hanging vine nodes there. Each vine should extend downward 3 to 8 blocks. Before placing vines, check that the vine node actually exists in the current game; if it does not, skip vine placement entirely. On any natural ledge or overhang surface wider than 2 blocks, place a small grass or shrub node. The total vegetation coverage on the pillar sides should be roughly 20 to 30 percent of visible surface area so the pillars still read clearly as stone formations with greenery clinging to them rather than as green columns.

---

## Prompt 7 — Performance Tuning and Edge Cases

Review the entire generation pipeline for performance. Make sure the VoxelManip data buffer table is reused across calls and never recreated. Confirm that content IDs are only looked up once at load time. Add an early-out at the top of the on_generated callback so chunks with no cluster potential skip all VoxelManip access entirely. Handle pillar clipping at chunk boundaries gracefully: if a pillar extends above or beyond the current chunk, just generate the portion that fits and let the irregular shape mask the truncation naturally. Do not attempt any cross-chunk coordination or pending-data storage. Test that pillars merging into sloped terrain do not leave floating gaps or visible seams at the ground line. Make sure calc_lighting is called exactly once per chunk after all pillars are placed, not once per pillar.

---

## Prompt 8 — Settings File and User Configuration

Write the settingtypes.txt file with all configurable settings, proper labels, type annotations, defaults, and min/max ranges so they appear correctly in the Luanti settings UI. Include: cluster rarity (integer, default 400, range 100 to 2000), minimum and maximum pillars per cluster (integers, defaults 10 and 30), minimum and maximum pillar height (integers, defaults 60 and 100), minimum and maximum pillar radius (integers, defaults 4 and 7), and the vegetation toggle (boolean, default true). Each setting should have a human-readable description that explains what it controls.

---

## Prompt 9 — Final Integration Testing and Polish

Do a final review of the complete mod. Verify that init.lua loads cleanly with no errors when no optional dependencies are present, when Minetest Game is present, and when MineClone is present. Check that all three material paths (MTG nodes, MineClone nodes, fallback nodes) resolve correctly. Confirm pillars generate at reasonable intervals, have organic and varied shapes, display correct surface materials, carry vegetation on tops and sides, and merge cleanly into the terrain. Fix any remaining issues with node placement order, lighting artifacts, or vegetation nodes floating in air. Make sure the README documents the mod's purpose, settings, compatibility, and license.
