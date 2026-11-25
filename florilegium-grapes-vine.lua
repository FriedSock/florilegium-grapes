-- florilegium-grapes-vine.lua -- one grapevine of a chosen variety, trained up the page's margin
-- as a vineyard's is, in its own colors. Its leaves, bunches, green shoots and old wood are drawn
-- by their own modules (florilegium-grapes-leaf.lua, -bunch.lua, -shoot.lua and -wood.lua).
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE or florilegium-grapes.sty.
--
-- The season ripens the grapes from green through veraison, and in autumn turns the leaves red
-- (a black grape's) or yellow (a white one's).
-- Use: \usepackage[vine=pinot]{florilegium-grapes} (or saperavi, gewurztraminer, rkatsiteli,
-- regent, johanniter, touriga, vidiano).

local ink = require("florilegium-grapes-ink")
local COLORS = require("florilegium-grapes-palette")
local varieties = require("florilegium-grapes-varieties")
local leaves = require("florilegium-grapes-leaf")
local bunches = require("florilegium-grapes-bunch")
local shoots = require("florilegium-grapes-shoot")
local wood = require("florilegium-grapes-wood")
local M = {}

local sin, cos, sqrt, exp, pi, floor = math.sin, math.cos, math.sqrt, math.exp, math.pi, math.floor
local max, min, abs = math.max, math.min, math.abs
local radians, lerp, clamp, heading_vector = ink.radians, ink.lerp, ink.clamp, ink.heading_vector
local heading_of, mix_colors, scale_color = ink.heading_of, ink.mix_colors, ink.scale_color
local append_all = ink.append_all
local function distance_between(x1, y1, x2, y2) return sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end

local RIPE_CANE_COLOR = mix_colors(COLORS.cane, COLORS.bark, 0.35)
local UNFOLDING_LEAF_COLOR = mix_colors(mix_colors(COLORS.leaf_light, COLORS.unripe_grape, 0.6), COLORS.red, 0.18)

-- the bunches drawn a little larger than life, as an illustrator enlarges the fruit
local FRUIT_ENLARGEMENT = 1.3

-- ---------------------------------------------------------------- the page
-- The vine as a vineyard trains it, spur-pruned on a vertical shoot positioned trellis, seen
-- from the side of the row, the margin's column its panel:
--   - the trunk rises from the ground to the fruiting wire, a third of the way up, and
--     divides into the cordon, two permanent arms laid along the wire, barked and knobbed;
--   - along the cordon, every hand's breadth, a spur: a stub of last year's cane cut back to
--     two buds, its cut end showing;
--   - from each bud a shoot (a cane once it ripens to brown in autumn), trained straight up
--     between the catch wires, thick at its base, its nodes swollen; ending in its soft growing
--     tip until veraison, hedged flat at the top from then on, where some lean over;
--   - at every node a leaf, alternately left and right, held at a depth of its own so the
--     canopy overlaps, the dormant bud in its axil, and from about one in five a lateral shoot,
--     from early summer, curving up with two to four small leaves, a tendril of its own and
--     a growing tip;
--   - in the fruit zone just above the cordon, the bunches hang from the third, fourth and
--     fifth nodes, and most leaves there are plucked to let the light and air at them; higher,
--     tendrils opposite the leaves, gripping the catch wires where they reach one;
--   - in spring the shoots are short, in autumn canes with turned leaves.
local LATE_SUMMER = 0.8

-- the canopy is layered by how near each thing in it is, depth -1 behind to 1 in front; the
-- wood sits in the middle
local function depth_layer(depth) return 10 + floor((clamp(depth, -1, 1) + 1) * 20) end
local MIDDLE_LAYER = depth_layer(0)
local TRUNK_LAYER, CANE_LAYER = MIDDLE_LAYER - 2, MIDDLE_LAYER - 1
local POLE_LAYER, WIRE_LAYER, BRAID_LAYER = MIDDLE_LAYER, MIDDLE_LAYER + 1, MIDDLE_LAYER + 1
local NODE_SUBLAYER, LEAF_STALK_SUBLAYER, LEAF_BLADE_SUBLAYER = 0.1, 0.25, 0.5
local CLIP_START_LAYER, CLIP_END_LAYER = 0, 99

local function add_item(page, item) page.items[#page.items + 1] = item end

local function point_index_at(distances, distance)
  local i = 1
  while i < #distances and distances[i] < distance do i = i + 1 end
  return i
end

-- a leaf on its stalk: where the stalk ends, stalk_length out from the node, and which way
-- the blade hangs from it, between the stalk's direction and straight down
local function leaf_blade_hang(node, stalk_heading, stalk_length)
  local dx, dy = heading_vector(stalk_heading)
  return { node[1] + stalk_length * dx, node[2] + stalk_length * dy }, heading_of(0.55 * dx, 0.55 * dy - 0.6)
end

local function add_growing_tip(page, shoot_points, length, width, depth)
  local before, last = shoot_points[#shoot_points - 1], shoot_points[#shoot_points]
  add_item(page, { kind = "growing_tip", base = last, heading = heading_of(last[1] - before[1], last[2] - before[2]),
    length = length, width = width, depth = depth })
end

-- a lateral (a side shoot): each axil, the angle between a leaf's stalk and the shoot, holds
-- two buds, the dormant one that waits for next spring and a lateral bud that grows at once.
-- Laterals start around flowering, in early summer, when the main shoot is growing hard, and
-- lengthen through the summer; growers strip them from the fruit zone with its leaves, so
-- they grow only above it. Each is a shoot in small: it leaves the axil at an angle, between
-- the leaf and the main shoot, and bends up toward the light, with short internodes, small
-- leaves alternately left and right that shrink toward its soft tip, and a tendril from
-- about its second node
local function grow_lateral(page, node, stem_heading, side, shoot_depth)
  local rng, scale = page.rng.laterals, page.scale
  -- it grows from flowering (age 0.3) to its full length by midsummer (0.6), already a third
  -- grown when it first shows; two to four leaves, fewer early on
  local flowering, midsummer = 0.3, 0.6
  local grown = clamp((page.season.age - flowering) / (midsummer - flowering), 0.35, 1)
  local leaf_count = max(2, floor(rng.between(2, 3.99) * grown + 0.5))
  -- its internodes are short, under half a main shoot's (1.0 to 1.35 scale), and its stem
  -- thin, about half a main shoot's
  local internode = rng.between(0.42, 0.55) * scale
  local thickness = 0.06 * scale
  -- it leaves the axil 35 to 55 degrees off the main shoot, toward the leaf's side, and each
  -- step along it turns an eighth of the way back to straight up
  local straight_up, bend, steps_per_internode, tip_steps = 90, 0.12, 3, 2
  local heading = stem_heading - side * rng.between(35, 55)
  local depth = shoot_depth + rng.plus_or_minus(0.45)
  local points, at = { node }, node
  for _ = 1, steps_per_internode * leaf_count + tip_steps do
    heading = heading + bend * (straight_up - heading)
    local dx, dy = heading_vector(heading)
    at = { at[1] + internode / steps_per_internode * dx, at[2] + internode / steps_per_internode * dy }
    points[#points + 1] = at
  end
  add_item(page, { kind = "shoot", points = points, depth = depth, base_width = thickness, tip_width = 0.45 * thickness })
  add_growing_tip(page, points, 0.32 * scale, 0.45 * thickness, depth)
  -- its leaves are small: the first under half a main shoot's full leaf (1.2 scale), each
  -- after it smaller toward the soft tip; their stalks are shorter for their blades than a
  -- main shoot's leaves' (0.75 to 1.05 of the blade), and leave the stem 50 to 75 degrees
  -- off it; only the leaf at the tip is still young and downy
  local first_leaf, smaller_each = 0.55, 0.07
  for k = 1, leaf_count do
    side = -side
    local leaf_node, before = points[steps_per_internode * k + 1], points[steps_per_internode * k]
    local along = heading_of(leaf_node[1] - before[1], leaf_node[2] - before[2])
    local length = scale * page.variety.leaf_size * (first_leaf - smaller_each * (k - 1)) * rng.between(0.85, 1.1)
    local stalk_heading = along - side * rng.between(50, 75)
    local stalk_length = rng.between(0.6, 0.85) * length
    local blade_base, blade_heading = leaf_blade_hang(leaf_node, stalk_heading, stalk_length)
    blade_heading = blade_heading + rng.plus_or_minus(18)
    local leaf_depth = depth + rng.plus_or_minus(0.4)
    local autumn_turn = page.season.leaf_turn * rng.uniform()
    add_item(page, { kind = "leaf", node = leaf_node, blade_base = blade_base, blade_heading = blade_heading, length = length,
      depth = leaf_depth, stalk_depth = depth, autumn_turn = autumn_turn, tint = rng.plus_or_minus(1),
      youth = k == leaf_count and 0.8 or 0, oldness = 0 })
    -- a tendril opposite the second leaf, smaller than a main shoot's (0.7 to 1.1 scale)
    if k == 2 then
      local tendril_heading = along + side * rng.between(40, 65)
      add_item(page, { kind = "tendril", node = leaf_node, heading = tendril_heading,
        length = rng.between(0.45, 0.65) * scale, depth = depth })
    end
  end
end

local function node_distances_along(layout, first_node, shoot_length, scale)
  local distances, at = {}, first_node
  while at < shoot_length - 0.1 do
    distances[#distances + 1] = at
    at = at + layout.between(1.0, 1.35) * scale
  end
  return distances
end

-- the bunches spread over the heights: a node is crowded by the bunches hung near its
-- height, and weighed against the least crowded node, so one bunch more near it than
-- there makes it 1 in 9 to the other's 8 in 9, and evened up, it is even again. They hang
-- from the third, fourth and fifth nodes
local function choose_fruiting_node(layout, node_heights, bunch_heights, fruiting, scale)
  local last = min(5, #node_heights)
  local crowding, least_crowding = {}, math.huge
  for n = 3, last do
    local crowd = 0
    for _, height in ipairs(bunch_heights) do crowd = crowd + exp(-((node_heights[n] - height) / (0.6 * scale)) ^ 2) end
    crowding[n] = crowd
    if not fruiting[n] then least_crowding = min(least_crowding, crowd) end
  end
  local weights, total = {}, 0
  for n = 3, last do
    local weight = fruiting[n] and 0 or exp(-math.log(9) * (crowding[n] - least_crowding))
    weights[n], total = weight, total + weight
  end
  if total <= 0 then return nil end
  local roll, n = layout.uniform() * (total + 0.1), 3
  if roll >= total then return nil end
  while n < last and roll > weights[n] do roll, n = roll - weights[n], n + 1 end
  if fruiting[n] then return nil end
  return n
end

-- one or two bunches to a fruiting shoot; a barren shoot has a tendril where a fruiting one
-- has its bunch: the two are the same organ
local function fruiting_nodes(page, node_heights, barren)
  local fruiting = {}
  if barren then return fruiting end
  local bunch_heights = {}
  append_all(bunch_heights, page.bunch_heights)
  for _ = 1, page.rng.layout.chance(0.55) and 2 or 1 do
    local n = choose_fruiting_node(page.rng.layout, node_heights, bunch_heights, fruiting, page.scale)
    if not n then break end
    fruiting[n] = true
    bunch_heights[#bunch_heights + 1] = node_heights[n]
  end
  return fruiting
end

-- the oldest leaves, low on the cane, are the largest, fully grown; they shrink toward the
-- young tip, and the first one or two are a little small
local function add_main_leaf(page, node, node_number, up_the_shoot, shoot_heading, side, shoot_depth)
  local layout, scale = page.rng.layout, page.scale
  local length = 1.2 * scale * page.variety.leaf_size * (node_number <= 2 and 0.8 or 1) * (1.25 - 0.75 * up_the_shoot ^ 1.1)
    * layout.between(0.88, 1.08)
  local stalk_heading = shoot_heading - side * layout.between(55, 85)
  local blade_base, blade_heading = leaf_blade_hang(node, stalk_heading, layout.between(0.75, 1.05) * length)
  blade_heading = blade_heading + layout.plus_or_minus(18)
  local depth = layout.plus_or_minus(1)
  local autumn_turn = page.season.leaf_turn * (layout.uniform() < 0.75 and 1 or 0.35) * layout.between(0.5, 1)
  add_item(page, { kind = "leaf", node = node, blade_base = blade_base, blade_heading = blade_heading, length = length,
    depth = depth, stalk_depth = shoot_depth, autumn_turn = autumn_turn, tint = layout.plus_or_minus(1),
    youth = clamp((up_the_shoot - 0.6) / 0.4, 0, 1), oldness = clamp(1.15 - up_the_shoot / 0.7, 0, 1) })
end

local function crowds_a_hanging_bunch(page, stalk_end, length)
  for _, item in ipairs(page.items) do
    if item.kind == "bunch" and abs(item.stalk_end[1] - stalk_end[1]) < 0.2 * (item.length + length)
      and min(item.stalk_end[2], stalk_end[2]) - max(item.stalk_end[2] - item.length, stalk_end[2] - length)
        > 0.3 * min(item.length, length) then
      return true
    end
  end
  return false
end

-- the bunch at its real size, on the leaf's scale (a midrib about 11 cm long); thinned, as
-- a grower thins them, where it would crowd one already hanging
local function hang_bunch(page, node, opposite_heading, shoot_depth)
  local layout, variety = page.rng.layout, page.variety
  local young = page.season.age < 0.45
  local length = FRUIT_ENLARGEMENT * variety.bunch_length_cm * page.real_cm * layout.between(0.85, 1.1) * (young and 0.5 or 1)
  -- its stalk leaves the node on the tendril's side, but nearly level, rising only a
  -- third as steeply, as the bunch's weight holds it down
  local opposite_x, opposite_y = heading_vector(opposite_heading)
  local outward = opposite_x >= 0 and 1 or -1
  local rise = 0.3 * heading_of(abs(opposite_x), opposite_y)
  local stalk_x, stalk_y = heading_vector(outward > 0 and rise or 180 - rise)
  local stalk_end = { node[1] + 0.18 * stalk_x, node[2] + 0.18 * stalk_y }
  if crowds_a_hanging_bunch(page, stalk_end, length) then return end
  page.bunch_heights[#page.bunch_heights + 1] = node[2]
  add_item(page, { kind = "bunch", node = node, stalk_end = stalk_end, outward = outward, length = length,
    depth = shoot_depth + 0.3 * layout.between(-0.5, 0.9),
    grape_radius = FRUIT_ENLARGEMENT * variety.grape_diameter_mm / 20 * page.real_cm * (young and 0.6 or 1) })
end

-- a tendril opposite the leaf, gripping a catch wire where it reaches one
local function add_tendril(page, node, heading)
  local layout = page.rng.layout
  local wire_y
  for _, y in ipairs(page.catch_wires) do
    if abs(y - node[2]) < 0.55 * page.scale then wire_y = y end
  end
  local length = layout.between(0.7, 1.1) * page.scale
  add_item(page, { kind = "tendril", node = node, heading = heading, length = length, wire_y = wire_y,
    depth = layout.plus_or_minus(0.6) })
end

local function bears_a_tendril(node_number, barren)
  return (node_number >= 6 or barren and node_number >= 3) and (node_number - 6) % 3 < 2
end

-- a shoot along its points, base_width thick at its base (a real one is 1 to 1.5 cm),
-- thinning steadily to under a third of that at its end, where the newest internodes have
-- hardly thickened: at its nodes, a leaf at each, alternately left and right, its bud in the
-- axil; bunches low, tendrils higher, now and then a lateral. The shoots stand a little nearer
-- or farther in the canopy, each at a depth of its own, and what grows from one keeps near its
-- depth, so a bunch hangs in front of the shoots behind its own and behind those in front of it
local function grow_shoot(page, points, base_width, in_fruit_zone, barren)
  local layout, scale, season = page.rng.layout, page.scale, page.season
  page.counts.shoots = page.counts.shoots + 1
  local depth = page.rng.depths.plus_or_minus(0.3)
  add_item(page, { kind = "shoot", points = points, depth = depth, base_width = base_width, tip_width = 0.3 * base_width })
  -- a main shoot grows on until it is hedged, from about veraison
  if season.age < 0.55 then add_growing_tip(page, points, 0.55 * scale, 0.3 * base_width, depth) end
  local distances, shoot_length = ink.distances_along(points)
  local first_node = layout.between(0.15, 0.25) * scale
  local side = layout.random_sign()
  local node_distances = node_distances_along(layout, first_node, shoot_length, scale)
  local node_heights = {}
  for n, at in ipairs(node_distances) do node_heights[n] = points[point_index_at(distances, at)][2] end
  local fruiting = fruiting_nodes(page, node_heights, barren)
  for node_number, at in ipairs(node_distances) do
    local i = point_index_at(distances, at)
    local node, before, after = points[i], points[max(1, i - 1)], points[min(#points, i + 1)]
    local shoot_heading = heading_of(after[1] - before[1], after[2] - before[2])
    side = -side
    local plucked = in_fruit_zone(node[2])
    add_item(page, { kind = "node", node = node, shoot_heading = shoot_heading, leaf_side = side, depth = depth })
    if not plucked then add_main_leaf(page, node, node_number, at / shoot_length, shoot_heading, side, depth) end
    local opposite_heading = shoot_heading + side * layout.between(40, 65)
    if fruiting[node_number] and season.age >= 0.3 then
      hang_bunch(page, node, opposite_heading, depth)
    elseif bears_a_tendril(node_number, barren) then
      add_tendril(page, node, opposite_heading)
    end
    if node_number >= 3 and not plucked and season.age >= 0.3 and page.rng.laterals.chance(0.2) then
      grow_lateral(page, node, shoot_heading, side, depth)
    end
  end
end

-- a shoot from a bud, trained straight up between the catch wires and hedged at the top,
-- where now and then one flops over the top wire and down
local function train_shoot_upright(page, bud_x, bud_y, lean, base_width, in_fruit_zone, barren)
  local layout, column = page.rng.layout, page.column
  local hedge_y = page.canopy_top + layout.between(-0.3, 0.25)
  local flops_over = layout.chance(0.3)
  local points, x, y, heading = { { bud_x, bud_y } }, bud_x, bud_y, 90 + lean
  local target_length = (hedge_y - bud_y) * page.season.shoot_growth
  local length, sway = 0, layout.between(0, 360)
  while length < target_length do
    heading = 90 + lean + 4 * sin(radians(length * 60 + sway))
    x, y = x + 0.12 * cos(radians(heading)), y + 0.12 * sin(radians(heading))
    length = length + 0.12
    points[#points + 1] = { clamp(x, column.left - 0.1, max(column.right + 0.1, page.row_end + 0.2)), y }
  end
  if flops_over and page.season.shoot_growth >= 1 then
    local flop_heading, side = heading, layout.random_sign()
    for _ = 1, floor(layout.between(6, 12)) do
      flop_heading = flop_heading + side * 14
      x, y = x + 0.12 * cos(radians(flop_heading)), y + 0.12 * sin(radians(flop_heading))
      points[#points + 1] = { x, y }
    end
  end
  grow_shoot(page, points, base_width, in_fruit_zone, barren)
end

-- a spur: a stub of last year's cane cut back to two buds, and a shoot from each (now and
-- then one is blind). knob_at: where years of spurs cut back here have knobbed the cordon
local function add_spur(page, base, heading, in_fruit_zone, knob_at, barren)
  local layout = page.rng.layout
  local length = layout.between(0.5, 0.8) * page.scale
  local cut_end = { base[1] + length * cos(radians(heading)), base[2] + length * sin(radians(heading)) }
  add_item(page, { kind = "spur", base = base, cut_end = cut_end, heading = heading, knob_at = knob_at })
  for bud = 1, 2 do
    if bud == 1 or layout.chance(0.85) then
      local along = bud == 1 and 0.45 or 0.92
      local lean = layout.plus_or_minus(3) + (bud == 1 and 7 or -7) * (cos(radians(heading)) >= 0 and 1 or -1)
      train_shoot_upright(page, lerp(base[1], cut_end[1], along), lerp(base[2], cut_end[2], along), lean,
        (bud == 1 and 1.35 or 1.25) * page.real_cm, in_fruit_zone, barren)
    end
  end
end

-- the row's trunks: one vine in the margin, and where the row goes on under the text, the
-- next vines along it
local function trunk_positions(page)
  local layout = page.rng.layout
  local trunks = { page.vine_left + page.vine_width * layout.between(0.38, 0.52) }
  if page.row_end > page.vine_right then
    local spacing = 5.5 * page.scale * layout.between(1, 1.25)
    while trunks[#trunks] + spacing < page.row_end - 1 do trunks[#trunks + 1] = trunks[#trunks] + spacing end
  end
  return trunks
end

-- a trunk, from the ground up to its head, wandering a little as an old one does
local function trunk_centerline(page, x, head_y)
  local layout = page.rng.layout
  local centerline = {}
  local phase = layout.between(0, 360)
  for i = 0, 16 do
    local t = i / 16
    centerline[#centerline + 1] = { x + 0.25 * page.scale * sin(radians(t * 300 + phase)) + layout.plus_or_minus(0.05),
      lerp(page.ground_y, head_y, t) }
  end
  return centerline, phase
end

-- how far an arm or a cane from the head may reach along the wire: to the margin's edge, or
-- halfway to the next vine's
local function reach_along_wire(page, trunks, k, head, side)
  if side < 0 then return k == 1 and head[1] - page.vine_left - 0.1 or (trunks[k] - trunks[k - 1]) / 2 - 0.15 end
  return k == #trunks and page.row_end - head[1] - 0.1 or (trunks[k + 1] - trunks[k]) / 2 - 0.15
end

-- the fruiting wire and the catch wires above it
local function string_trellis(page, fruiting_wire_y)
  local above = page.canopy_top - fruiting_wire_y
  page.catch_wires = { fruiting_wire_y + 0.3 * above, fruiting_wire_y + 0.58 * above, fruiting_wire_y + 0.84 * above }
  local wire_start = page.column.left - 0.3
  local wire_end = page.under_text and page.row_end + 0.25 or page.column.right - 0.05
  ink.select_layer(WIRE_LAYER)
  for _, y in ipairs({ fruiting_wire_y - 0.08, page.catch_wires[1], page.catch_wires[2], page.catch_wires[3] }) do
    ink.move_to(wire_start, y) ink.line_to(wire_end, y + 0.01)
  end
  ink.stroke(COLORS.wire, 0.4, 0.85)
end

-- the cordon's arms: from inside the head, curving out and up onto the wire, then along it,
-- knuckled
local function cordon_arms(page, trunks, k, head, fruiting_wire_y, wander_phase)
  local scale = page.scale
  local arms = {}
  for _, side in ipairs({ -1, 1 }) do
    local reach = reach_along_wire(page, trunks, k, head, side)
    if reach > 0.8 then
      local start_y = head[2] - 0.55 * scale
      local points = { { head[1] - side * 0.1 * scale, start_y } }
      local sag = page.rng.layout.between(0.03, 0.1)
      for i = 1, 18 do
        local t = i / 18
        local onto_wire = min(1, t * 2.6)
        points[#points + 1] = { head[1] + side * reach * t,
          lerp(start_y, fruiting_wire_y, 1 - (1 - onto_wire) ^ 2.2) - sag * sin(radians(t * 180))
            + 0.05 * scale * sin(radians(t * 900 + wander_phase)) }
      end
      arms[#arms + 1] = { points = points, side = side }
    end
  end
  return arms
end

-- each arm ends where it was stopped: a knob round the cut, now and then an old spur's stub
local function draw_arm_end_knob(page, arm)
  local knobs, scale = page.rng.knobs, page.scale
  local cut = arm.points[#arm.points]
  local cut_end_angle = (arm.side > 0 and 0 or 180) + knobs.plus_or_minus(20)
  local stubs = { { angle = cut_end_angle, length = 0.06 * scale, width = 0.28 * scale } }
  if knobs.chance(0.5) then
    local angle = 90 + arm.side * knobs.between(10, 50)
    stubs[2] = { angle = angle, length = knobs.between(0.12, 0.25) * scale, width = 0.12 * scale }
  end
  local radius = knobs.between(0.24, 0.3) * scale
  local scar_count = knobs.chance(0.5) and 1 or 0
  wood.draw_pruning_knob(knobs, { x = cut[1] - arm.side * 0.1 * scale, y = cut[2], radius = radius, squash = 1.1,
    light_side = page.light_side, scale = scale, stubs = stubs, scar_count = scar_count, wound_side = arm.side,
    join_angle = arm.side > 0 and 180 or 0 })
end

-- the trunk and its arms; the head, where the trunk divides, swollen and scarred where shoots
-- were cut from it
local function draw_trunk_and_cordon(page, trunk, arms)
  local knobs, scale = page.rng.knobs, page.scale
  ink.select_layer(TRUNK_LAYER)
  local rng = page.rng.drawing.fork()
  for _, arm in ipairs(arms) do wood.draw_old_wood(rng, arm.points, 0.8 * scale, 0.38 * scale) end
  wood.draw_old_wood(rng, trunk, 1.1 * scale, 0.95 * scale)
  local head = trunk[#trunk]
  local wound_side = knobs.random_sign()
  local radius = knobs.between(0.45, 0.55) * scale
  local stub_angle = 90 + wound_side * knobs.between(0, 50)
  local stub_length = knobs.between(0.15, 0.35) * scale
  local stub = { angle = stub_angle, length = stub_length, width = knobs.between(0.16, 0.24) * scale }
  wood.draw_pruning_knob(knobs, { x = head[1], y = head[2] - 0.1 * scale, radius = radius, squash = 0.85,
    light_side = page.light_side, scale = scale, stubs = { stub }, scar_count = 2, wound_side = wound_side, rim = { 30, 150 } })
  for _, arm in ipairs(arms) do draw_arm_end_knob(page, arm) end
end

local function add_spurs_along(page, arm, knuckle_height, in_fruit_zone)
  local layout, scale = page.rng.layout, page.scale
  local distances, arm_length = ink.distances_along(arm.points)
  local at = layout.between(0.9, 1.4) * scale
  while at < arm_length - 0.15 do
    local position = arm.points[point_index_at(distances, at)]
    add_spur(page, { position[1], position[2] + knuckle_height }, 90 + layout.plus_or_minus(35), in_fruit_zone, position)
    at = at + layout.between(2.2, 2.9) * scale
  end
end

-- spur pruned on a cordon: the trunks and their cordons, each cordon arm reaching halfway to
-- its neighbour's, then the spurs along them, and from each bud a shoot. Each spur stands on
-- its knuckle, and the fruit zone, where the leaves are plucked, with it
local function train_spur_pruned(page)
  local fruiting_wire_y = page.ground_y + 0.3 * page.canopy_height
  local knuckle_height = 0.28 * page.scale
  local function in_fruit_zone(y)
    return y < fruiting_wire_y + knuckle_height + 0.22 * (page.canopy_top - fruiting_wire_y)
  end
  local trunks = trunk_positions(page)
  local all_arms = {}
  for k, trunk_x in ipairs(trunks) do
    local trunk, wander_phase = trunk_centerline(page, trunk_x, fruiting_wire_y - 0.3)
    local arms = cordon_arms(page, trunks, k, trunk[#trunk], fruiting_wire_y, wander_phase)
    append_all(all_arms, arms)
    draw_trunk_and_cordon(page, trunk, arms)
  end
  string_trellis(page, fruiting_wire_y)
  for _, arm in ipairs(all_arms) do add_spurs_along(page, arm, knuckle_height, in_fruit_zone) end
end

-- the head: a fist of old wood, the stubs of old canes standing out of its top, cut long,
-- and the flush cuts of older ones on its face, all toward one side; from it last year's
-- spurs, each now carrying its cane
local function guyot_head_stubs(page, wound_side, cane_sides)
  local layout, scale = page.rng.layout, page.scale
  local stubs = {}
  for _ = 1, floor(layout.between(2, 4)) do
    local angle = 90 + wound_side * layout.between(-10, 55)
    local length = layout.between(0.15, 0.35) * scale
    stubs[#stubs + 1] = { angle = angle, length = length, width = layout.between(0.13, 0.2) * scale }
  end
  for _, cane_side in ipairs(cane_sides) do
    local angle = 90 - cane_side.side * layout.between(40, 55)
    stubs[#stubs + 1] = { angle = angle, length = layout.between(0.15, 0.3) * scale, width = 0.2 * scale, live = true,
      cane_side = cane_side }
  end
  return stubs
end

-- from the spur's end, rising, over in a bow and down onto the wire, then lying along it
local function laid_down_cane(page, stub, spur_end, head_x, fruiting_wire_y, wander_phase)
  local layout, scale = page.rng.layout, page.scale
  local side, reach = stub.cane_side.side, stub.cane_side.reach
  local bow_reach = min(reach - 0.3 * scale, layout.between(1.5, 2.1) * scale)
  local arch = layout.between(0.2, 0.45) * scale
  local leaving_x, leaving_y = heading_vector(stub.angle)
  local p0 = spur_end
  local p3 = { head_x + side * bow_reach, fruiting_wire_y }
  local p1 = { p0[1] + 0.25 * bow_reach * leaving_x, p0[2] + 0.25 * bow_reach * leaving_y }
  local p2 = { p3[1] - side * 0.45 * bow_reach, max(fruiting_wire_y + arch, p1[2] + 0.15 * scale) }
  local points = {}
  for j = 0, 16 do
    local t = j / 16
    local u = 1 - t
    points[#points + 1] = { u ^ 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ^ 3 * p3[1],
      u ^ 3 * p0[2] + 3 * u * u * t * p1[2] + 3 * u * t * t * p2[2] + t ^ 3 * p3[2] }
  end
  local along_wire = max(2, floor((reach - bow_reach) / 0.15))
  for j = 1, along_wire do
    local x = p3[1] + side * (reach - bow_reach) * j / along_wire
    points[#points + 1] = { x, fruiting_wire_y + 0.02 * scale * sin(x * 7 + wander_phase) }
  end
  return points
end

-- the renewal spur, low on the head on one side, below that side's cane. Its shoots are
-- next year's canes, and the grower takes off any bunches they set, to keep their
-- strength for the wood, so they bear none
local function add_renewal_spur(page, cane_sides, head_edge, in_fruit_zone)
  local layout = page.rng.layout
  local cane_side = cane_sides[layout.chance(0.5) and 1 or #cane_sides]
  local heading = 90 - cane_side.side * layout.between(55, 75)
  local x, y = head_edge(radians(heading), 0.75)
  add_spur(page, { x, y }, heading, in_fruit_zone, nil, true)
end

local function draw_cane_node(node)
  local p, width = node.point, node.width
  local across_x, across_y = heading_vector(node.heading + 90)
  wood.trace_ellipse(p[1], p[2], 0.56 * width, 0.3 * width, radians(node.heading + 90))
  ink.fill(mix_colors(RIPE_CANE_COLOR, COLORS.bark_dark, 0.15))
  ink.move_to(p[1] - 0.5 * width * across_x, p[2] - 0.5 * width * across_y)
  ink.line_to(p[1] + 0.5 * width * across_x, p[2] + 0.5 * width * across_y)
  ink.stroke(COLORS.bark_dark, 0.3, 0.6)
  if node.blind then
    ink.trace_circle(p[1] + 0.5 * width * across_x, p[2] + 0.5 * width * across_y, 0.22 * width)
    ink.fill(mix_colors(COLORS.cane, COLORS.bark_dark, 0.4))
  end
end

-- each cane, its nodes swollen, its cut end showing; a shoot from every bud that is not blind
local function grow_from_cane(page, points, in_fruit_zone)
  local layout, scale = page.rng.layout, page.scale
  local base_width, end_width = 0.2 * scale, 0.13 * scale
  local distances, cane_length = ink.distances_along(points)
  local function heading_at(i)
    local before, after = points[max(1, i - 1)], points[min(#points, i + 1)]
    return heading_of(after[1] - before[1], after[2] - before[2])
  end
  local nodes, at = {}, layout.between(0.25, 0.4) * scale
  while at < cane_length - 0.12 do
    local i = point_index_at(distances, at)
    nodes[#nodes + 1] = { point = points[i], heading = heading_at(i), width = lerp(base_width, end_width, at / cane_length),
      blind = not layout.chance(0.9) }
    at = at + layout.between(0.9, 1.2) * scale
  end
  ink.select_layer(CANE_LAYER)
  shoots.draw_round_stem(points, base_width, end_width, RIPE_CANE_COLOR)
  for _, node in ipairs(nodes) do draw_cane_node(node) end
  local cut = points[#points]
  wood.draw_cut_face(page.rng.knobs, cut[1], cut[2], 0.5 * end_width, 0.25 * end_width, radians(heading_at(#points) + 90), false,
    COLORS.heartwood)
  for _, node in ipairs(nodes) do
    if not node.blind then
      train_shoot_upright(page, node.point[1], node.point[2] + 0.4 * node.width, layout.plus_or_minus(6), 1.25 * page.real_cm,
        in_fruit_zone)
    end
  end
end

-- cane pruned (double Guyot), on the same trellis: no cordon, but each winter the trunk's
-- head is cut back to two of last year's canes, one each way, and a renewal spur. The head
-- sits a hand's breadth or two under the fruiting wire, so each cane leaves it rising, arches
-- over and is bent down onto the wire and tied along it, and cut after its eighth to
-- fifteenth bud. A cane is a finger thick, a year old, smooth brown wood swollen at its
-- nodes; a shoot grows from nearly every bud and is trained up between the catch wires. Next
-- winter the canes are cut away and new ones laid down from the renewal spur's shoots, so the
-- head grows knobbed with the stubs of years of canes
local function train_double_guyot(page)
  local layout, scale = page.rng.layout, page.scale
  local fruiting_wire_y = page.ground_y + 0.3 * page.canopy_height
  local function in_fruit_zone(y) return y < fruiting_wire_y + 0.22 * (page.canopy_top - fruiting_wire_y) end
  local trunks = trunk_positions(page)
  local canes = {}
  for k, trunk_x in ipairs(trunks) do
    local trunk, wander_phase = trunk_centerline(page, trunk_x, fruiting_wire_y - layout.between(0.9, 1.2) * scale)
    local head = trunk[#trunk]
    local head_x, head_y = head[1], head[2] + 0.15 * scale
    local cane_sides = {}
    for _, side in ipairs({ -1, 1 }) do
      local reach = reach_along_wire(page, trunks, k, head, side)
      if reach > 0.8 then cane_sides[#cane_sides + 1] = { side = side, reach = reach } end
    end
    local wound_side = layout.random_sign()
    local stubs = guyot_head_stubs(page, wound_side, cane_sides)
    local radius, squash = layout.between(0.52, 0.6) * scale, layout.between(0.85, 1)
    ink.select_layer(TRUNK_LAYER)
    wood.draw_old_wood(page.rng.drawing.fork(), trunk, 1.1 * scale, 0.95 * scale)
    local scar_count = page.rng.knobs.chance(0.5) and 2 or 1
    local stub_ends, head_edge = wood.draw_pruning_knob(page.rng.knobs, { x = head_x, y = head_y, radius = radius,
      squash = squash, light_side = page.light_side, scale = scale, stubs = stubs, scar_count = scar_count,
      wound_side = wound_side })
    for i, stub in ipairs(stubs) do
      if stub.live then canes[#canes + 1] = laid_down_cane(page, stub, stub_ends[i], head_x, fruiting_wire_y, wander_phase) end
    end
    if #cane_sides > 0 then add_renewal_spur(page, cane_sides, head_edge, in_fruit_zone) end
  end
  string_trellis(page, fruiting_wire_y)
  for _, cane in ipairs(canes) do grow_from_cane(page, cane, in_fruit_zone) end
end

-- thin steel poles hold the braid up close to the ground
local function draw_poles(page, poles)
  local half_width, foot_y = 0.6 * page.real_cm, page.ground_y - 0.4
  ink.select_layer(POLE_LAYER)
  for _, pole in ipairs(poles) do
    local top_x = pole.x + pole.lean * (pole.top_y - page.ground_y)
    local rod = { { pole.x - half_width, foot_y }, { top_x - half_width, pole.top_y }, { top_x + half_width, pole.top_y },
      { pole.x + half_width, foot_y } }
    ink.trace_polyline(rod, true) ink.fill(COLORS.steel_pole)
    ink.move_to(pole.x - 0.4 * half_width, foot_y) ink.line_to(top_x - 0.4 * half_width, pole.top_y)
    ink.stroke(mix_colors(COLORS.steel_pole, COLORS.white, 0.35), 0.3, 0.7)
    ink.trace_polyline(rod, true) ink.stroke(COLORS.bark_dark, 0.25, 0.85)
  end
end

local function trace_twine_turn(from_x, to_x, top_y, bottom_y, real_cm)
  ink.move_to(from_x, top_y + 0.2 * real_cm)
  ink.curve_to(from_x + 0.8 * real_cm, lerp(top_y, bottom_y, 0.3), to_x + 0.8 * real_cm, lerp(top_y, bottom_y, 0.7), to_x,
    bottom_y - 0.2 * real_cm)
end

-- each pole is lashed to the braid with two turns of twine, round all the canes it crosses
local function lash_braid_to_pole(canes, x, real_cm)
  local bottom_y, top_y = 1e9, -1e9
  for _, cane in ipairs(canes) do
    local nodes = cane.nodes
    for j = 1, #nodes - 1 do
      if nodes[j][1] <= x and nodes[j + 1][1] >= x then
        local t = (x - nodes[j][1]) / max(1e-9, nodes[j + 1][1] - nodes[j][1])
        local y, half_width = lerp(nodes[j][2], nodes[j + 1][2], t), lerp(nodes[j].width, nodes[j + 1].width, t) / 2
        bottom_y, top_y = min(bottom_y, y - half_width), max(top_y, y + half_width)
      end
    end
  end
  for turn = 0, 1 do
    local from_x, to_x = x - 0.9 * real_cm + turn * 0.9 * real_cm, x + 0.3 * real_cm + turn * 0.9 * real_cm
    trace_twine_turn(from_x, to_x, top_y, bottom_y, real_cm) ink.stroke(COLORS.twine, 1.4, 1)
    trace_twine_turn(from_x, to_x, top_y, bottom_y, real_cm) ink.stroke(COLORS.twine_light, 0.8, 1)
  end
end

-- shoots grow from the nodes of the braid's canes, wherever one faces out
local function braid_buds(page, canes)
  local buds = {}
  for _, cane in ipairs(canes) do
    for _, node in ipairs(cane.nodes) do
      if node[1] > page.vine_left and node[1] < page.row_end and node.depth > -0.2 then
        buds[#buds + 1] = { node[1], node[2] + 0.3 * node.width }
      end
    end
  end
  table.sort(buds, function(a, b) return a[1] < b[1] end)
  return buds
end

-- with no wires to train it, a shoot rises at a lean of its own and arches over under its
-- weight
local function grow_free_shoot(page, bud, braid_y, in_fruit_zone)
  local layout, column = page.rng.layout, page.column
  local middle_x = (page.vine_left + page.vine_right) / 2
  local lean = clamp((bud[1] - middle_x) / page.vine_width * 40, -20, 20) + layout.plus_or_minus(10)
  local start_heading, arch_side = 90 - lean, lean > 0 and 1 or -1
  local arch = layout.between(10, 70)
  local target_length = (page.canopy_top - braid_y) * page.season.shoot_growth * layout.between(0.75, 1.1)
  local far_right = max(column.right, page.row_end) + 0.3
  local x, y = bud[1], bud[2]
  local points, length = { { x, y } }, 0
  while length < target_length and x > column.left - 0.3 and x < far_right do
    local heading = start_heading - arch_side * arch * (length / target_length) ^ 2
    x, y = x + 0.12 * cos(radians(heading)), max(page.ground_y + 0.3, y + 0.12 * sin(radians(heading)))
    length = length + 0.12
    points[#points + 1] = { x, y }
  end
  grow_shoot(page, points, layout.between(1.2, 1.4) * page.real_cm, in_fruit_zone)
end

-- the cordón trenzado of the Valle de La Orotava, Tenerife: a stretch of the braided cordon
-- crossing the margin, lifted off the ground on props and sagging between them, a narrow band
-- of leaves above it plucked, and the bunches hanging low over it
local function train_trenzado(page)
  local layout, real_cm, column = page.rng.layout, page.real_cm, page.column
  local braid_y = page.ground_y + layout.between(25, 40) * real_cm
  local function in_fruit_zone(y) return y < braid_y + 0.12 * (page.canopy_top - braid_y) end
  local pole_spacing = layout.between(40, 65) * real_cm
  local first_pole_x = column.left - layout.between(0, pole_spacing)
  local tilt, sag = layout.plus_or_minus(0.04), layout.between(4, 9) * real_cm
  local function braid_height_at(x)
    local between_poles = (x - first_pole_x) / pole_spacing
    return braid_y + tilt * (x - page.vine_left) - sag * sin(pi * (between_poles - floor(between_poles)))
  end
  local far_right = max(column.right, page.row_end)
  local centerline = {}
  for i = 0, 60 do
    local x = lerp(column.left - 0.6, far_right + 0.6, i / 60)
    centerline[#centerline + 1] = { x, braid_height_at(x) }
  end
  local canes = wood.braid_canes(layout.fork(), centerline, real_cm)
  local poles = {}
  for x = first_pole_x, far_right + 0.3, pole_spacing do
    if x > column.left - 0.3 then
      local top_y = braid_height_at(x) + layout.between(15, 40) * real_cm
      poles[#poles + 1] = { x = x, top_y = top_y, lean = layout.plus_or_minus(0.04) }
    end
  end
  draw_poles(page, poles)
  ink.select_layer(BRAID_LAYER)
  wood.draw_braid(page.rng.drawing.fork(), canes)
  for _, pole in ipairs(poles) do lash_braid_to_pole(canes, pole.x, real_cm) end
  local last_shoot_x = -1e9
  for _, bud in ipairs(braid_buds(page, canes)) do
    if bud[1] - last_shoot_x > layout.between(0.7, 1.0) * page.scale then
      last_shoot_x = bud[1]
      grow_free_shoot(page, bud, braid_y, in_fruit_zone)
    end
  end
end

local TRAININGS = { spur = train_spur_pruned, cane = train_double_guyot, trenzado = train_trenzado }

-- summer pruning: a leaf whose blade hangs over a bunch is pulled, stalk and all
local function hangs_over_a_bunch(leaf, items)
  local dx, dy = heading_vector(leaf.blade_heading)
  local center_x, center_y = leaf.blade_base[1] + 0.45 * leaf.length * dx, leaf.blade_base[2] + 0.45 * leaf.length * dy
  for _, item in ipairs(items) do
    if item.kind == "bunch" then
      local half_width, margin = 0.35 * item.length, 0.55 * leaf.length
      if abs(center_x - item.stalk_end[1]) < half_width + margin and center_y < item.stalk_end[2] + margin
        and center_y > item.stalk_end[2] - item.length - margin then
        return true
      end
    end
  end
  return false
end

-- under the text: what grows wholly behind it, out of the margin and above the space it
-- leaves, is not drawn
local function is_hidden_under_text(page, item)
  local anchor = item.node or item.base
  return anchor and anchor[1] > page.column.right + 3 * page.scale and anchor[2] > page.under_text.top + 3 * page.scale
end

local function items_without(items, should_drop)
  local kept = {}
  for _, item in ipairs(items) do
    if not should_drop(item) then kept[#kept + 1] = item end
  end
  return kept
end

local function remove_pulled_and_hidden_items(page)
  page.items = items_without(page.items, function(item)
    return item.kind == "leaf" and hangs_over_a_bunch(item, page.items)
  end)
  if page.under_text then
    page.items = items_without(page.items, function(item) return is_hidden_under_text(page, item) end)
  end
end

-- ---------------------------------------------------------------- painting the page's items
local function draw_placed(layer, x, y, heading, draw)
  ink.select_layer(layer)
  ink.save_transform() ink.translate(x, y) ink.rotate(heading)
  draw()
  ink.restore_transform()
end

local function trace_spur_cut(center, heading, radius)
  local dx, dy = heading_vector(heading)
  local x, y, r = center[1], center[2], radius
  ink.move_to(x + r * dy, y - r * dx)
  ink.curve_to(x + r * dy + 0.5 * r * dx, y - r * dx + 0.5 * r * dy, x - r * dy + 0.5 * r * dx, y + r * dx + 0.5 * r * dy,
    x - r * dy, y + r * dx)
  ink.curve_to(x - r * dy - 0.3 * r * dx, y + r * dx - 0.3 * r * dy, x + r * dy - 0.3 * r * dx, y - r * dx - 0.3 * r * dy,
    x + r * dy, y - r * dx)
  ink.close_path()
end

-- the spur position: knobbed by years of spurs cut back here, each new one a little
-- higher than the last, the stubs of the last one or two left standing beside it
local function draw_spur_position_knob(page, at)
  local knobs, scale = page.rng.knobs, page.scale
  local wound_side = knobs.random_sign()
  local stubs = {}
  for _ = 1, knobs.chance(0.6) and 2 or 1 do
    local angle = 90 + wound_side * knobs.between(25, 70)
    local length = knobs.between(0.12, 0.3) * scale
    stubs[#stubs + 1] = { angle = angle, length = length, width = knobs.between(0.11, 0.15) * scale }
  end
  local radius = knobs.between(0.2, 0.27) * scale
  local scar_count = knobs.chance(0.5) and 1 or 0
  wood.draw_pruning_knob(knobs, { x = at[1], y = at[2] + 0.1 * scale, radius = radius, squash = 1.25,
    light_side = page.light_side, scale = scale, stubs = stubs, scar_count = scar_count, wound_side = wound_side })
end

local function paint_spur(page, spur)
  local scale = page.scale
  ink.select_layer(CANE_LAYER)
  if spur.knob_at then draw_spur_position_knob(page, spur.knob_at) end
  local base, cut = spur.base, spur.cut_end
  local centerline = { { base[1], base[2] }, { lerp(base[1], cut[1], 0.5), lerp(base[2], cut[2], 0.5) + 0.02 }, { cut[1], cut[2] } }
  shoots.draw_round_stem(centerline, 0.24 * scale, 0.17 * scale, COLORS.cane)
  -- the node it was cut above
  ink.trace_circle(lerp(base[1], cut[1], 0.45), lerp(base[2], cut[2], 0.45), 0.1 * scale)
  ink.fill(mix_colors(COLORS.cane, COLORS.bark_dark, 0.3))
  trace_spur_cut(cut, spur.heading, 0.085 * scale)
  ink.fill(COLORS.fresh_cut) ink.stroke(COLORS.bark_dark, 0.25, 0.8)
end

local function paint_shoot(page, shoot)
  ink.select_layer(depth_layer(shoot.depth))
  shoots.draw_round_stem(shoot.points, shoot.base_width, shoot.tip_width, page.shoot_color)
end

-- the swollen node across the shoot, and the dormant bud in the axil, on the leaf's side,
-- just above it
local function paint_node(page, mark)
  local scale, node = page.scale, mark.node
  ink.select_layer(depth_layer(mark.depth) + NODE_SUBLAYER)
  local dx, dy = heading_vector(mark.shoot_heading)
  ink.move_to(node[1] - 0.06 * scale * dy, node[2] + 0.06 * scale * dx)
  ink.line_to(node[1] + 0.06 * scale * dy, node[2] - 0.06 * scale * dx)
  ink.stroke(scale_color(page.shoot_color, 0.6), 0.8, 0.8)
  local bud_x = node[1] - mark.leaf_side * 0.06 * scale * dy + 0.05 * scale * dx
  local bud_y = node[2] + mark.leaf_side * 0.06 * scale * dx + 0.05 * scale * dy
  ink.trace_circle(bud_x, bud_y, 0.035 * scale)
  ink.fill(mix_colors(COLORS.cane, COLORS.green_shoot, 0.3 * (1 - page.season.cane_ripening)))
  ink.trace_circle(bud_x, bud_y, 0.035 * scale) ink.stroke(COLORS.bark_dark, 0.2, 0.7)
end

local function leaf_color(page, leaf)
  local green = leaf.tint > 0 and mix_colors(COLORS.leaf, COLORS.leaf_light, 0.5 * leaf.tint)
    or mix_colors(COLORS.leaf, COLORS.leaf_dark, -0.4 * leaf.tint)
  local turned = mix_colors(green, page.is_white_grape and COLORS.yellow or COLORS.red, leaf.autumn_turn)
  return scale_color(turned, 0.8 + 0.2 * (leaf.depth + 1) / 2)
end

-- the blade is a plane at an angle of its own: turned about its midrib (yaw) and tipped
-- toward or away from the reader (pitch), seen foreshortened; now and then turned far
-- enough to show its paler underside
local function random_leaf_pose(layout, underside)
  local yaw = underside and layout.random_sign() * layout.between(110, 140) or layout.plus_or_minus(62)
  local pitch = layout.plus_or_minus(48)
  local cup, droop = layout.between(-0.1, 0.45), layout.between(-0.15, 0.4)
  local wave, wave_phase = layout.between(0.03, 0.09), layout.between(0, 2 * pi)
  return { yaw = yaw, pitch = pitch, cup = cup, droop = droop, wave = wave, wave_phase = wave_phase,
    twist = layout.plus_or_minus(0.3) }
end

-- a stalk reaching forward is drawn just over the shoot it grows from, under every blade
-- in front of that shoot, so it never lies across a blade that hides its node; one
-- reaching back stays with its own blade, behind the shoot. It reaches out from the node,
-- arching up, the blade hanging from its end; swollen where it joins the cane and where it
-- meets the blade
local function paint_leaf_stalk(page, leaf)
  local node, blade = leaf.node, leaf.blade_base
  ink.select_layer(min(depth_layer(leaf.stalk_depth), depth_layer(leaf.depth)) + LEAF_STALK_SUBLAYER)
  local stalk_length = distance_between(node[1], node[2], blade[1], blade[2])
  local arch_x, arch_y = lerp(node[1], blade[1], 0.5), lerp(node[2], blade[2], 0.5) + 0.22 * stalk_length
  local stalk = {}
  for i = 0, 10 do
    local u = i / 10
    stalk[#stalk + 1] = { (1 - u) ^ 2 * node[1] + 2 * u * (1 - u) * arch_x + u * u * blade[1],
      (1 - u) ^ 2 * node[2] + 2 * u * (1 - u) * arch_y + u * u * blade[2] }
  end
  local width = 0.055 * page.scale * leaf.length / (1.2 * page.scale)
  shoots.draw_round_stem(stalk, 1.5 * width, 0.85 * width, page.petiole_color)
  ink.trace_circle(node[1], node[2], 0.9 * width) ink.fill(scale_color(page.petiole_color, 0.85))
end

local function paint_leaf(page, leaf)
  page.counts.leaves = page.counts.leaves + 1
  local layout, variety = page.rng.layout, page.variety
  local underside = layout.chance(0.12)
  local pose = random_leaf_pose(layout, underside)
  local color = leaf_color(page, leaf)
  if underside then color = mix_colors(color, COLORS.leaf_underside, 0.5) end
  -- its hairs: an underside's felt, the variety's; a young leaf near the tip downy on top
  local hairiness = underside and variety.leaf_hairiness or leaf.youth * (0.35 + 0.6 * variety.leaf_hairiness)
  -- the oldest leaves, low on the cane, wear as the season goes on: a darker, deeper green,
  -- and torn here and there
  local wear = leaf.oldness * clamp((page.season.age - 0.45) / 0.4, 0, 1)
  color = mix_colors(color, scale_color(COLORS.leaf_dark, 0.9), 0.5 * wear)
  paint_leaf_stalk(page, leaf)
  ink.select_layer(depth_layer(leaf.depth) + LEAF_BLADE_SUBLAYER)
  ink.save_transform()
  ink.translate(leaf.blade_base[1], leaf.blade_base[2]) ink.rotate(leaf.blade_heading - 90) ink.scale(leaf.length)
  leaves.draw(page.rng.drawing.fork(), { color = color, lobe_count = page.vine.lobe_count, sinus_depth = page.vine.sinus_depth,
    basal_lobe_angle = variety.basal_lobe_angle, tooth_spacing = variety.tooth_spacing, pose = pose,
    light_side = page.light_side, rotation = radians(leaf.blade_heading - 90), underside = underside,
    hairiness = hairiness, wear = wear })
  ink.restore_transform()
end

local function paint_bunch(page, bunch)
  page.counts.bunches = page.counts.bunches + 1
  local stalk_end, variety = bunch.stalk_end, page.variety
  ink.select_layer(depth_layer(bunch.depth))
  bunches.draw_stalk_from_node(bunch.node, stalk_end, bunch.outward, bunch.grape_radius, variety.grape_diameter_mm)
  ink.save_transform()
  ink.translate(stalk_end[1], stalk_end[2])
  bunches.draw(page.rng.drawing.fork(), { vine = page.vine, variety = variety, length = bunch.length,
    grape_radius = bunch.grape_radius, outward = bunch.outward, ripeness = page.season.grape_ripeness,
    light_side = page.light_side })
  ink.restore_transform()
end

local function paint_growing_tip(page, tip)
  local leaf_color_now = mix_colors(UNFOLDING_LEAF_COLOR, page.is_white_grape and COLORS.yellow or COLORS.red,
    0.5 * page.season.leaf_turn)
  local stem_color = mix_colors(page.shoot_color, COLORS.green_shoot, 0.6)
  draw_placed(depth_layer(tip.depth), tip.base[1], tip.base[2], tip.heading, function()
    shoots.draw_growing_tip(page.rng.drawing.fork(), tip.length, tip.width, stem_color, leaf_color_now,
      page.variety.leaf_hairiness)
  end)
end

local function paint_tendril(page, tendril)
  page.counts.tendrils = page.counts.tendrils + 1
  local color = mix_colors(COLORS.tendril, COLORS.cane, page.season.cane_ripening)
  if tendril.wire_y then
    ink.select_layer(depth_layer(tendril.depth))
    shoots.draw_tendril_gripping_wire(page.rng.drawing.fork(), tendril.node, tendril.wire_y, page.scale, color)
  else
    draw_placed(depth_layer(tendril.depth), tendril.node[1], tendril.node[2], tendril.heading, function()
      shoots.draw_tendril(page.rng.drawing.fork(), tendril.length, color)
    end)
  end
end

local PAINTERS = { spur = paint_spur, shoot = paint_shoot, node = paint_node, leaf = paint_leaf, bunch = paint_bunch,
  growing_tip = paint_growing_tip, tendril = paint_tendril }

-- a clip a little outside the column, so nothing strays into the text
local function clip_to_margin(page)
  local column, under_text = page.column, page.under_text
  ink.select_layer(CLIP_START_LAYER)
  ink.trace_polyline({ { column.left - 0.25, column.bottom - 0.3 }, { column.right + 0.3, column.bottom - 0.3 },
    { column.right + 0.3, column.top + 0.3 }, { column.left - 0.25, column.top + 0.3 } }, true)
  if under_text then
    ink.trace_polyline({ { under_text.left, under_text.bottom - 0.3 }, { under_text.right, under_text.bottom - 0.3 },
      { under_text.right, under_text.top }, { under_text.left, under_text.top } }, true)
  end
  ink.clip()
  ink.select_layer(CLIP_END_LAYER)
  ink.end_clip()
end

local function log_what_grew(page)
  if not texio then return end
  local counts = page.counts
  texio.write_nl(string.format("florilegium-grapes: a %s vine, %d shoots, %d leaves, %d bunches, %d tendrils",
    page.vine.variety_name, counts.shoots, counts.leaves, counts.bunches, counts.tendrils))
end

-- ---------------------------------------------------------------- the page's setting
local function seasonal_state(age)
  return {
    age = age,
    grape_ripeness = clamp((age - 0.55) / 0.25, 0, 1),   -- green, then veraison, then ripe
    leaf_turn = clamp((age - 0.8) / 0.18, 0, 1),
    cane_ripening = clamp((age - 0.62) / 0.3, 0, 1),     -- the shoots ripen to canes
    shoot_growth = clamp(0.25 + 1.5 * age, 0.25, 1),
  }
end

local function random_streams(seed)
  local base = seed * 7919
  local drawing = ink.random_stream(base + 811)
  return { drawing = drawing, layout = drawing.fork(), laterals = ink.random_stream(base + 812),
    knobs = ink.random_stream(base + 813), depths = ink.random_stream(base + 814) }
end

-- the margin's column, from the paper's edge to the text, from the foot of the page to its
-- top; on the page where the text ends, the row goes on under it, in the space the text leaves
local function lay_out_margin(page, settings)
  local column = { left = settings.column_left, bottom = 0.45, right = settings.column_right,
    top = settings.paper_height - 0.5 }
  page.column = column
  page.vine_left, page.vine_right = column.left + 0.15, column.right - 0.1
  if settings.text_end_y and settings.text_end_y - 0.5 - column.bottom > 2.5 then
    page.under_text = { left = column.right, bottom = column.bottom, right = settings.text_right,
      top = settings.text_end_y - 0.5 }
  end
  page.row_end = page.under_text and page.under_text.right - 0.3 or page.vine_right
  page.ground_y, page.canopy_top = column.bottom + 0.05, column.top - 0.35
  page.vine_width, page.canopy_height = page.vine_right - page.vine_left, page.canopy_top - page.ground_y
  page.scale = clamp(page.vine_width / 5.5, 0.75, 1.15)
  -- a leaf's midrib is 11 cm
  page.real_cm = 1.2 * page.scale / 11
end

local function new_page(settings)
  local page = { rng = random_streams(settings.seed) }
  ink.set_page_transform(settings.mirrored and settings.paper_width)
  page.light_side = settings.mirrored and -1 or 1
  page.vine = varieties.document_vine(settings.variety, settings.document_seed)
  page.variety = page.vine.variety
  page.season = seasonal_state(settings.season or LATE_SUMMER)
  page.is_white_grape = page.vine.berry_tone == "pale" or page.variety.white_wine_grape
  lay_out_margin(page, settings)
  page.shoot_color = mix_colors(COLORS.green_shoot, COLORS.cane, page.season.cane_ripening)
  page.petiole_color = mix_colors(COLORS.petiole, COLORS.red, page.is_white_grape and 0.1 or 0.35)
  page.counts = { shoots = 0, leaves = 0, bunches = 0, tendrils = 0 }
  page.items, page.catch_wires, page.bunch_heights = {}, {}, {}
  return page
end

-- settings: the page's layout (florilegium-grapes.lua's, in cm), its seed and document_seed,
-- its season (nil for late summer), the variety and the pruning
function M.draw_page(settings)
  local page = new_page(settings)
  local train = TRAININGS[settings.pruning]
  if not train then
    error("florilegium-grapes: pruning=" .. tostring(settings.pruning) .. "? one of spur, cane, trenzado", 0)
  end
  train(page)
  remove_pulled_and_hidden_items(page)
  for _, item in ipairs(page.items) do PAINTERS[item.kind](page, item) end
  clip_to_margin(page)
  log_what_grew(page)
  ink.write_layers_to_page()
end

return M

