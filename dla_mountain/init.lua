-- dla_mountain: DLA-based snowy mountain generator
-- Generates a massive mountain at world origin using Diffusion-Limited Aggregation,
-- surrounded by an infinite flat snow plain.

------------------------------------------------------------------------
-- Section 1: Game Detection, Fallback Nodes, Content ID Caching
------------------------------------------------------------------------

local stone_name, dirt_name, snow_name

if core.get_modpath("default") then
	stone_name = "default:stone"
	dirt_name = "default:dirt"
	snow_name = "default:snowblock"
elseif core.get_modpath("mcl_core") then
	stone_name = "mcl_core:stone"
	dirt_name = "mcl_core:dirt"
	snow_name = "mcl_core:snow"
else
	stone_name = "dla_mountain:stone"
	dirt_name = "dla_mountain:dirt"
	snow_name = "dla_mountain:snow"

	core.register_node("dla_mountain:stone", {
		description = "Stone",
		tiles = {"dla_mountain_stone.png"},
		groups = {cracky = 3},
	})
	core.register_node("dla_mountain:dirt", {
		description = "Dirt",
		tiles = {"dla_mountain_dirt.png"},
		groups = {crumbly = 3},
	})
	core.register_node("dla_mountain:snow", {
		description = "Snow",
		tiles = {"dla_mountain_snow.png"},
		groups = {crumbly = 3},
	})
end

-- Content IDs resolved after all mods load (nodes don't exist yet during init)
local c_stone, c_dirt, c_snow, c_air

core.register_on_mods_loaded(function()
	c_stone = core.get_content_id(stone_name)
	c_dirt = core.get_content_id(dirt_name)
	c_snow = core.get_content_id(snow_name)
	c_air = core.CONTENT_AIR
end)

------------------------------------------------------------------------
-- Section 2: Utility Functions
------------------------------------------------------------------------

local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_cos = math.cos
local math_sqrt = math.sqrt
local math_random = math.random
local math_pi = math.pi

-- Bilinear resize from source to destination size
local function resize_bilinear(src, src_w, src_h, dst_w, dst_h)
	local dst = {}
	local sx_scale = (src_w - 1) / (dst_w - 1)
	local sz_scale = (src_h - 1) / (dst_h - 1)
	for dz = 1, dst_h do
		local sz = (dz - 1) * sz_scale
		local sz0 = math_floor(sz)
		local fz = sz - sz0
		sz0 = sz0 + 1
		local sz1 = math_min(sz0 + 1, src_h)
		local dst_row = (dz - 1) * dst_w
		local src_row0 = (sz0 - 1) * src_w
		local src_row1 = (sz1 - 1) * src_w
		for dx = 1, dst_w do
			local sx = (dx - 1) * sx_scale
			local sx0 = math_floor(sx)
			local fx = sx - sx0
			sx0 = sx0 + 1
			local sx1 = math_min(sx0 + 1, src_w)
			local v00 = src[src_row0 + sx0]
			local v10 = src[src_row0 + sx1]
			local v01 = src[src_row1 + sx0]
			local v11 = src[src_row1 + sx1]
			dst[dst_row + dx] = v00 * (1 - fx) * (1 - fz)
				+ v10 * fx * (1 - fz)
				+ v01 * (1 - fx) * fz
				+ v11 * fx * fz
		end
	end
	return dst
end

-- Box blur: average cells within radius, clamped at edges
local function box_blur(grid, w, h, radius)
	local out = {}
	for z = 1, h do
		local z0 = math_max(1, z - radius)
		local z1 = math_min(h, z + radius)
		local row = (z - 1) * w
		for x = 1, w do
			local x0 = math_max(1, x - radius)
			local x1 = math_min(w, x + radius)
			local sum = 0
			local count = 0
			for bz = z0, z1 do
				local brow = (bz - 1) * w
				for bx = x0, x1 do
					sum = sum + grid[brow + bx]
					count = count + 1
				end
			end
			out[row + x] = sum / count
		end
	end
	return out
end

-- Radial gradient: cosine falloff^0.7, zero at/beyond edge
local function radial_gradient(grid, w, h)
	local cx = (w + 1) / 2
	local cz = (h + 1) / 2
	local max_dist = math_min(cx - 1, cz - 1)
	for z = 1, h do
		local dz = (z - cz) / max_dist
		local row = (z - 1) * w
		for x = 1, w do
			local dx = (x - cx) / max_dist
			local dist = math_sqrt(dx * dx + dz * dz)
			if dist >= 1.0 then
				grid[row + x] = 0
			else
				local falloff = (0.5 * (1 + math_cos(math_pi * dist))) ^ 0.7
				grid[row + x] = grid[row + x] * falloff
			end
		end
	end
end

------------------------------------------------------------------------
-- Section 3: DLA Heightmap Generation (5 additive layers)
------------------------------------------------------------------------

-- Run DLA walkers with deposit trails for height variation
local function run_walkers(grid, w, h, num_walkers)
	local agg_x0, agg_x1 = w, 1
	local agg_z0, agg_z1 = h, 1
	for z = 1, h do
		local row = (z - 1) * w
		for x = 1, w do
			if grid[row + x] > 0 then
				if x < agg_x0 then agg_x0 = x end
				if x > agg_x1 then agg_x1 = x end
				if z < agg_z0 then agg_z0 = z end
				if z > agg_z1 then agg_z1 = z end
			end
		end
	end

	local margin = math_max(10, math_floor(w * 0.1))
	local deposit_steps = math_max(5, math_floor(w * 0.15))
	local max_steps = w * 10
	local sp_x0 = math_max(1, agg_x0 - margin)
	local sp_x1 = math_min(w, agg_x1 + margin)
	local sp_z0 = math_max(1, agg_z0 - margin)
	local sp_z1 = math_min(h, agg_z1 + margin)
	local max_wander = math_max(sp_x1 - sp_x0, sp_z1 - sp_z0) + margin

	local stuck = 0
	for i = 1, num_walkers do
		if i % 500 == 0 and stuck > 0 then
			sp_x0 = math_max(1, agg_x0 - margin)
			sp_x1 = math_min(w, agg_x1 + margin)
			sp_z0 = math_max(1, agg_z0 - margin)
			sp_z1 = math_min(h, agg_z1 + margin)
			max_wander = math_max(sp_x1 - sp_x0, sp_z1 - sp_z0) + margin
		end

		local x, z
		local side = math_random(1, 4)
		if side == 1 then
			x = math_random(sp_x0, sp_x1); z = sp_z0
		elseif side == 2 then
			x = math_random(sp_x0, sp_x1); z = sp_z1
		elseif side == 3 then
			x = sp_x0; z = math_random(sp_z0, sp_z1)
		else
			x = sp_x1; z = math_random(sp_z0, sp_z1)
		end

		local ox, oz = x, z
		for step = 1, max_steps do
			local has_nb = false
			if x > 1 and grid[(z - 1) * w + (x - 1)] > 0 then has_nb = true
			elseif x < w and grid[(z - 1) * w + (x + 1)] > 0 then has_nb = true
			elseif z > 1 and grid[(z - 2) * w + x] > 0 then has_nb = true
			elseif z < h and grid[z * w + x] > 0 then has_nb = true
			end

			if has_nb then
				grid[(z - 1) * w + x] = grid[(z - 1) * w + x] + 1.0
				stuck = stuck + 1
				if x < agg_x0 then agg_x0 = x end
				if x > agg_x1 then agg_x1 = x end
				if z < agg_z0 then agg_z0 = z end
				if z > agg_z1 then agg_z1 = z end

				-- Deposit trail on aggregate
				local dep = 1.0
				for ds = 1, deposit_steps do
					dep = dep * 0.9
					local dir = math_random(1, 4)
					if dir == 1 then x = x - 1
					elseif dir == 2 then x = x + 1
					elseif dir == 3 then z = z - 1
					else z = z + 1 end
					if x < 1 or x > w or z < 1 or z > h then break end
					local idx = (z - 1) * w + x
					if grid[idx] > 0 then
						grid[idx] = grid[idx] + dep
					else
						break
					end
				end
				break
			end

			local dir = math_random(1, 4)
			if dir == 1 then x = x - 1
			elseif dir == 2 then x = x + 1
			elseif dir == 3 then z = z - 1
			else z = z + 1 end
			if x < 1 or x > w or z < 1 or z > h then break end
			local ddx = x - ox
			local ddz = z - oz
			if ddx * ddx + ddz * ddz > max_wander * max_wander then break end
		end
	end
	return stuck
end

-- Run a single DLA layer: grid, seed, walkers. No per-layer gradient/normalization.
local function run_dla_layer(size, num_walkers)
	local grid = {}
	for i = 1, size * size do grid[i] = 0 end
	local cc = math_floor(size / 2) + 1
	for dz = -1, 1 do
		for dx = -1, 1 do
			grid[(cc + dz - 1) * size + (cc + dx)] = 1.0
		end
	end
	local stuck = run_walkers(grid, size, size, num_walkers)
	return grid, stuck
end

-- Generate 5 additive DLA layers
local HM_FINAL = 801
local start_time = core.get_us_time()
core.log("action", "[dla_mountain] Starting 5-layer DLA heightmap...")

local layers = {
	{size = 51,  walkers = 3000,   weight = 8.0, blur = 2},
	{size = 101, walkers = 8000,   weight = 4.0, blur = 2},
	{size = 201, walkers = 20000,  weight = 2.0, blur = 1},
	{size = 401, walkers = 50000,  weight = 1.0, blur = 1},
	{size = 801, walkers = 80000,  weight = 0.5, blur = 0},
}

local heightmap = {}
for i = 1, HM_FINAL * HM_FINAL do heightmap[i] = 0 end

for li, L in ipairs(layers) do
	local grid, stuck = run_dla_layer(L.size, L.walkers)

	-- Blur this layer to smooth DLA edges into natural ridges
	if L.blur > 0 then
		grid = box_blur(grid, L.size, L.size, L.blur)
	end

	-- Resize to final resolution
	local resized
	if L.size == HM_FINAL then
		resized = grid
	else
		resized = resize_bilinear(grid, L.size, L.size, HM_FINAL, HM_FINAL)
	end
	grid = nil

	-- Add to accumulator with weight
	local wt = L.weight
	for i = 1, HM_FINAL * HM_FINAL do
		heightmap[i] = heightmap[i] + resized[i] * wt
	end
	resized = nil

	core.log("action", string.format(
		"[dla_mountain] Layer %d: %dx%d, %d/%d stuck, weight=%.1f, blur=%d",
		li, L.size, L.size, stuck, L.walkers, L.weight, L.blur))
end

-- Apply radial gradient once to shape the mountain envelope
radial_gradient(heightmap, HM_FINAL, HM_FINAL)

-- Final light blur to blend the multi-resolution layers together
heightmap = box_blur(heightmap, HM_FINAL, HM_FINAL, 2)

-- Scale to max 250, round to integers
local max_val = 0
for i = 1, HM_FINAL * HM_FINAL do
	if heightmap[i] > max_val then max_val = heightmap[i] end
end
if max_val > 0 then
	local scale = 250 / max_val
	for i = 1, HM_FINAL * HM_FINAL do
		heightmap[i] = math_floor(heightmap[i] * scale + 0.5)
	end
end

-- Stats
local diag_zero, diag_nonzero = 0, 0
for i = 1, HM_FINAL * HM_FINAL do
	if heightmap[i] == 0 then diag_zero = diag_zero + 1
	else diag_nonzero = diag_nonzero + 1 end
end
local total = HM_FINAL * HM_FINAL
local elapsed = (core.get_us_time() - start_time) / 1000000
local stats_msg = string.format(
	"DLA Mountain: %.1fs, %d nonzero (%.1f%%), peak=%d",
	elapsed, diag_nonzero, diag_nonzero * 100 / total, 250)
core.log("action", "[dla_mountain] " .. stats_msg)

------------------------------------------------------------------------
-- Section 4: Mapgen and Terrain Generation
------------------------------------------------------------------------

core.set_mapgen_setting("mapgen", "singlenode", true)

local vm_data = {}
local HM_SIZE = HM_FINAL
local HM_CENTER = 401
local CELL_SIZE = 2
local PEAK_HEIGHT = 250

-- Verification chat message
core.register_on_joinplayer(function(player)
	core.after(2, function()
		core.chat_send_player(player:get_player_name(), "*** " .. stats_msg .. " ***")
	end)
end)

-- Bilinear height lookup for smooth terrain
local function get_surface_height(wx, wz)
	local fx = wx / CELL_SIZE + HM_CENTER
	local fz = wz / CELL_SIZE + HM_CENTER
	if fx < 1 or fx > HM_SIZE or fz < 1 or fz > HM_SIZE then
		return 0
	end
	local gx0 = math_floor(fx)
	local gz0 = math_floor(fz)
	local tx = fx - gx0
	local tz = fz - gz0
	if gx0 < 1 then gx0 = 1 end
	if gz0 < 1 then gz0 = 1 end
	local gx1 = math_min(gx0 + 1, HM_SIZE)
	local gz1 = math_min(gz0 + 1, HM_SIZE)
	local h00 = heightmap[(gz0 - 1) * HM_SIZE + gx0]
	local h10 = heightmap[(gz0 - 1) * HM_SIZE + gx1]
	local h01 = heightmap[(gz1 - 1) * HM_SIZE + gx0]
	local h11 = heightmap[(gz1 - 1) * HM_SIZE + gx1]
	local h = h00 * (1 - tx) * (1 - tz)
		+ h10 * tx * (1 - tz)
		+ h01 * (1 - tx) * tz
		+ h11 * tx * tz
	local surface = math_floor(h + 0.5)
	if surface <= 0 then return 0 end
	return surface
end

core.register_on_generated(function(minp, maxp, blockseed)
	if minp.y > PEAK_HEIGHT then return end

	local vm, emin, emax = core.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	vm:get_data(vm_data)

	local ystride = area.ystride

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local surface = get_surface_height(x, z)
			local vi = area:index(x, minp.y, z)
			for y = minp.y, maxp.y do
				if y > surface then
					vm_data[vi] = c_air
				elseif y == surface then
					vm_data[vi] = c_snow
				elseif y >= surface - 4 then
					vm_data[vi] = c_dirt
				else
					vm_data[vi] = c_stone
				end
				vi = vi + ystride
			end
		end
	end

	vm:set_data(vm_data)
	vm:calc_lighting()
	vm:write_to_map()
end)

core.log("action", "[dla_mountain] Mod loaded. 5-layer DLA, 801x801, cell=2, spans +-800.")
