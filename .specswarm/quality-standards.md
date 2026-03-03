# Quality Standards — stone_pillars

> Quality gates and standards for the stone_pillars Luanti mod.

---

## Project Info

- **Project**: stone_pillars
- **Date**: 2026-02-27
- **Quality Level**: Relaxed

---

## Quality Score Thresholds

```yaml
min_quality_score: 70
min_test_coverage: 70
block_merge_on_failure: false
```

---

## Testing Requirements

```yaml
require_tests: false
```

### Unit Tests
- **Framework**: busted (Lua testing framework) — optional
- **Minimum pass rate**: 70%
- **Notes**: Luanti mods have limited unit testing support; manual in-game testing is primary

### Integration Tests
- **Method**: In-game worldgen validation
- **Criteria**:
  - Mod loads without errors in all three game modes (MTG, MineClone, standalone)
  - Pillars generate at expected intervals
  - No lighting artifacts or floating nodes
  - Vegetation renders correctly when enabled and is absent when disabled

### Performance Tests
- **Method**: Manual profiling via Luanti debug info (F5)
- **Criteria**:
  - Worldgen callback < 100ms per chunk with pillars
  - Empty chunks (no cluster) < 1ms overhead
  - No measurable FPS impact during gameplay near pillars

---

## Code Quality

```yaml
complexity_threshold: 15
max_file_lines: 500
max_function_lines: 80
max_function_params: 6
```

### Luanti-Specific Quality Rules
- All content IDs cached at load time — zero lookups in generation loops
- VoxelManip data buffer reused across calls
- `calc_lighting` called exactly once per chunk, not per pillar
- No `core.set_node()` or `core.get_node()` in worldgen path
- Settings read once at load time, not per callback invocation
- All node existence checks done at load time with graceful fallbacks

---

## Performance Budgets

```yaml
enforce_budgets: false
```

- Luanti mods have no bundle/build concept
- Performance is measured by worldgen callback duration and FPS impact
- No automated bundle size analysis applicable

---

## Code Review

```yaml
require_code_review: false
min_reviewers: 0
```

---

## Validation Checklist

Before shipping, verify:

- [ ] `init.lua` loads without errors (no optional deps)
- [ ] `init.lua` loads with Minetest Game (`default` mod)
- [ ] `init.lua` loads with MineClone (`mcl_core` mod)
- [ ] Fallback nodes register correctly in standalone mode
- [ ] `settingtypes.txt` renders correctly in Luanti settings UI
- [ ] Pillars generate with organic, varied shapes
- [ ] Surface materials (stone, cobble, mossy cobble) distribute correctly
- [ ] Erosion grooves and overhangs appear on subset of pillars
- [ ] Flat tops have soil cap and vegetation (when enabled)
- [ ] Side vegetation (vines, ledge plants) renders correctly
- [ ] Vegetation toggle disables all plant placement
- [ ] No floating nodes or lighting artifacts
- [ ] Pillars merge cleanly into terrain at ground line
- [ ] Chunk boundary clipping is visually seamless
- [ ] Performance is acceptable (no worldgen stalls)

---

## Exemptions

- **No automated test runner**: Luanti lacks a standard CI-compatible test harness for worldgen mods. Quality is validated through in-game testing.
- **No coverage measurement**: Code coverage tools are not applicable to Luanti mod development.
- **No bundle analysis**: Luanti loads raw Lua files; there is no build/bundle step.

---

## Notes

- Quality level: Relaxed (70/100 threshold)
- Created by `/specswarm:init`
- Enforced by `/specswarm:ship` before merge
- Primary quality validation is manual in-game testing
- Adjust thresholds if automated Lua testing (busted) is added later
