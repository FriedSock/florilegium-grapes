-- florilegium-grapes-bunch.lua -- a bunch of grapes: its branched stalks and its grapes, packed,
-- ripened and painted from the back to the front.
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE or florilegium-grapes.sty.

local ink = require("florilegium-grapes-ink")
local COLORS = require("florilegium-grapes-palette")
local M = {}

local sin, cos, sqrt, exp, pi, floor = math.sin, math.cos, math.sqrt, math.exp, math.pi, math.floor
local max, min = math.max, math.min
local radians, lerp, clamp, heading_vector = ink.radians, ink.lerp, ink.clamp, ink.heading_vector
local mix_colors, scale_color = ink.mix_colors, ink.scale_color

-- A bunch is a panicle seen from the side: a bare peduncle, then the rachis, a main axis
-- that bends a little as the bunch hangs, with a spiral of branches off it, the longest at
-- the shoulders. Each branch arches down under the weight it carries and ends in a small
-- cluster of grapes that hangs below its tip, each grape on its pedicel. The bunch's outline
-- (an inverted pear, or a cylinder) is as wide as the variety's grapes need to cover it,
-- closely for a compact bunch and with gaps for a loose one; in a compact bunch the grapes
-- are drawn toward that outline, so it has no hollows between its clusters. A winged bunch
-- has a second, smaller panicle, the outer arm, splitting off the peduncle. Grapes that
-- collide are pushed apart. Grapes vary in size, a few stay small and green (shot berries),
-- and as the bunch ripens they color one by one. Painted from the back: stalks, then grapes,
-- nearer ones lighter. The stalks are drawn as thick as real ones, on the bunch's scale.
local BP_PER_CM = 28.3465
local STALK_COLOR = mix_colors(COLORS.green_shoot, COLORS.cane, 0.45)
local GOLDEN_ANGLE = 137.508
local GRAPE_COVER_BY_COMPACTNESS = { 0.55, 0.85, 0.92 }
local GRAPES_PER_BRANCH_BY_COMPACTNESS = { 3.5, 4.5, 5.5 }
local PULL_TO_OUTLINE_BY_COMPACTNESS = { 0, 0.55, 0.7 }
local GRAPE_SPACING_BY_COMPACTNESS = { 1.0, 0.95, 0.9 }
local GRAPE_ASPECT_BY_SHAPE = { round = 1, oval = 1.16, long = 1.42 }

local function bunch_width_share(bunch_shape, t)
  if bunch_shape == "cylindrical" then
    return (t < 0.08 and 0.6 + 5 * t or 1) * (t > 0.8 and max(0.2, 1 - (t - 0.8) * 4) or 1)
  end
  -- an inverted pear: full, almost square shoulders at the top, then tapering steadily
  -- to a narrow, rounded tip
  if t < 0.12 then return 0.8 + 0.2 * sin(radians(t / 0.12 * 90)) end
  return 1 - 0.75 * ((t - 0.12) / 0.88) ^ 1.1
end

-- the rachis, tilted, bending as it hangs
local function rachis_of(rng, panicle)
  local length = 0.78 * panicle.length
  local bend_x, bend_z = rng.plus_or_minus(0.15), rng.plus_or_minus(0.15)
  local cos_tilt, sin_tilt = cos(radians(panicle.tilt)), sin(radians(panicle.tilt))
  local function point_at(t)
    local x, y = bend_x * t * t * length, -t * length
    return panicle.x + x * cos_tilt - y * sin_tilt, panicle.y + x * sin_tilt + y * cos_tilt,
      panicle.z + bend_z * t * t * length
  end
  return { length = length, point_at = point_at }
end

-- the outline's radius at its widest: its surface (2 pi R H on average) covered as closely
-- as the bunch is compact by its grapes
local function widest_outline_radius(vine, rachis_length, grape_radius, grape_count)
  local mean_width_share = 0
  for i = 1, 40 do mean_width_share = mean_width_share + bunch_width_share(vine.bunch_shape, (i - 0.5) / 40) / 40 end
  local cover = GRAPE_COVER_BY_COMPACTNESS[vine.compactness]
  return grape_count * grape_radius * grape_radius / (2 * rachis_length * cover * mean_width_share)
end

-- how many branches and where, after Shavrukov, Dry & Thomas (2004): 20 to 22 branches
-- (nodes) on a tight bunch's rachis, 33 to 38 on a loose one's, each carrying a group of 6 to
-- 8 flowers; the internodes between them longest at the top (a pair about 20 mm there, 5 mm
-- by the middle), long and short by turns
local function branch_positions(rng, branch_count)
  local positions, total = {}, 0
  for i = 1, branch_count do
    local internode = (0.25 + 0.75 * exp(-(i - 1) / 2.6)) * (i % 2 == 1 and 1.35 or 0.65) * rng.between(0.85, 1.15)
    total = total + internode
    positions[i] = total
  end
  return positions
end

local function new_grape(rng, x, y, z, grape_radius, size)
  local grape = { x = x, y = y, z = z, radius = grape_radius * size, is_shot_berry = size < 0.7 }
  grape.ripening_lag = rng.uniform()
  grape.tint = rng.uniform()
  grape.bloom_variation = rng.uniform()
  grape.rub_roll = rng.uniform()
  grape.rub_angle = rng.between(0, 360)
  grape.grown_at = { x, y, z }
  return grape
end

-- its cluster about the branch's tip, a little below it, each grape on its pedicel and
-- hanging from it: its long axis that way, and down
local function hang_cluster(rng, bunch, branch, grape_count, cluster_radius)
  local tip = branch.tip
  local center_x, center_y, center_z = tip[1], tip[2] - 0.45 * cluster_radius, tip[3]
  for k = 1, grape_count do
    local height = 1 - 2 * (k - 0.5) / grape_count
    local ring = sqrt(max(0, 1 - height * height))
    local around = k * GOLDEN_ANGLE + rng.plus_or_minus(20)
    local unit_x, unit_y, unit_z = ring * cos(radians(around)), height, ring * sin(radians(around))
    local x = center_x + unit_x * cluster_radius * 0.9
    local y = center_y + unit_y * cluster_radius * 1.2
    local z = center_z + unit_z * cluster_radius * 0.9
    local size = rng.chance(0.04) and rng.between(0.45, 0.6) or rng.between(0.88, 1.08)
    local grape = new_grape(rng, x, y, z, bunch.grape_radius, size)
    local hang_x, hang_y, hang_z = x - tip[1], y - tip[2] - 0.6 * cluster_radius, z - tip[3]
    local hang_length = sqrt(hang_x * hang_x + hang_y * hang_y + hang_z * hang_z)
    grape.hang_x, grape.hang_y = hang_x / hang_length, hang_y / hang_length
    bunch.grapes[#bunch.grapes + 1] = grape
    branch.grapes[#branch.grapes + 1] = grape
  end
end

-- a compact bunch has no hollows between its clusters: its grapes are drawn out (or in)
-- toward the outline's surface, a medium one part way, a loose one not at all
local function pull_grapes_toward_outline(bunch, panicle, rachis, outline_radius_at)
  local pull = PULL_TO_OUTLINE_BY_COMPACTNESS[bunch.vine.compactness]
  if pull <= 0 then return end
  for _, grape in ipairs(bunch.grapes) do
    local t = clamp((panicle.y - grape.y) / rachis.length, 0, 1)
    local axis_x, _, axis_z = rachis.point_at(t)
    local dx, dz = grape.x - axis_x, grape.z - axis_z
    local distance = sqrt(dx * dx + dz * dz)
    if distance > 1e-6 then
      local k = lerp(distance, max(0, outline_radius_at(t) - 0.3 * bunch.grape_radius), pull) / distance
      grape.x, grape.z = axis_x + dx * k, axis_z + dz * k
    end
  end
end

-- a panicle hanging down -y from its top (panicle.x, y, z), panicle.length long and tilted by
-- panicle.tilt degrees, its stalks, branches and grapes added to the bunch's
local function grow_panicle(rng, bunch, panicle)
  local vine, grape_radius, grape_count = bunch.vine, bunch.grape_radius, panicle.grape_count
  local rachis = rachis_of(rng, panicle)
  local widest = widest_outline_radius(vine, rachis.length, grape_radius, grape_count)
  local function width_share(t) return bunch_width_share(vine.bunch_shape, t) end
  local function outline_radius_at(t) return widest * width_share(t) end
  local function add_stalk(from, to, thickness_mm)
    bunch.stalks[#bunch.stalks + 1] = { from = from, to = to, width = thickness_mm * bunch.real_mm * BP_PER_CM }
  end
  -- the rachis, about 4 mm thick at its top, thinning to 1.5 mm at its tip
  local previous = { rachis.point_at(0) }
  for i = 1, 12 do
    local point = { rachis.point_at(i / 12) }
    add_stalk(previous, point, lerp(4, 1.5, (i - 0.5) / 12))
    previous = point
  end
  -- a spiral of branches off the rachis, the longest at the shoulders, each ending in a
  -- small cluster of grapes on short pedicels: a sphere of them about the branch's tip
  local spiral_angle = rng.between(0, 360)
  local branch_count = clamp(floor(grape_count / GRAPES_PER_BRANCH_BY_COMPACTNESS[vine.compactness] + 0.5), 8, 38)
  local positions = branch_positions(rng, branch_count)
  local rachis_span = positions[branch_count]
  local shares, share_total = {}, 0
  for i = 1, branch_count do
    shares[i] = width_share(positions[i] / rachis_span) * rng.between(0.7, 1.3)
    share_total = share_total + shares[i]
  end
  for i = 1, branch_count do
    local t = clamp(positions[i] / rachis_span * 0.97, 0, 1)
    spiral_angle = spiral_angle + GOLDEN_ANGLE + rng.plus_or_minus(15)
    local toward_x, toward_z = cos(radians(spiral_angle)), sin(radians(spiral_angle))
    local cluster_size = max(1, floor(grape_count * shares[i] / share_total + 0.5))
    local cluster_radius = grape_radius * sqrt(1.15 * cluster_size / 4)
    local reach = max(0, outline_radius_at(t) - cluster_radius + grape_radius) * rng.between(0.85, 1.1)
    local base_x, base_y, base_z = rachis.point_at(t)
    -- the branch is stiff: about 2 mm thick, it stands out from the rachis at an angle from
    -- the straight down, nearly level at the shoulders (68 degrees) and steeper lower down
    -- (38), bowing only a little. Real ones are long: the first 4 to 5 cm, a third of the rachis
    local drop = reach / math.tan(radians(lerp(68, 38, t)))
    local middle = { base_x + toward_x * 0.5 * reach, base_y - 0.4 * drop, base_z + toward_z * 0.5 * reach }
    local tip = { base_x + toward_x * reach, base_y - drop, base_z + toward_z * reach }
    add_stalk({ base_x, base_y, base_z }, middle, 2.0)
    add_stalk(middle, tip, 1.5)
    local branch = { tip = tip, grapes = {} }
    bunch.branches[#bunch.branches + 1] = branch
    hang_cluster(rng, bunch, branch, cluster_size, cluster_radius)
  end
  pull_grapes_toward_outline(bunch, panicle, rachis, outline_radius_at)
end

-- the peduncle, bare from the node to the first branch: 16 to 17 mm on a tight bunch of
-- 8 to 12 cm (Shavrukov et al. 2004), a little under a fifth of it; 5 to 6 mm thick.
-- It is stiff, and the bunch's weight bends it over gradually: it carries on outward from
-- the node, starting a quarter of the way down from level, and is still leaning out a little
-- where the branches begin; the bunch hangs on along that lean
local function peduncle_of(rng, bunch_length, outward)
  local length = 0.18 * bunch_length * rng.between(0.75, 1.35)
  local leaving_x, leaving_y = heading_vector(-25)
  local arriving_x, arriving_y = heading_vector(-70)
  return { length = length, bezier = {
    { 0, 0 },
    { outward * 0.45 * length * leaving_x, 0.45 * length * leaving_y },
    { outward * (0.55 - 0.3 * arriving_x) * length, (-0.8 - 0.3 * arriving_y) * length },
    { outward * 0.55 * length, -0.8 * length },
  } }
end

local function bezier_point(control, t)
  local u = 1 - t
  local a, b, c, d = u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t
  return a * control[1][1] + b * control[2][1] + c * control[3][1] + d * control[4][1],
    a * control[1][2] + b * control[2][2] + c * control[3][2] + d * control[4][2]
end

-- push apart grapes that collide, as they press in a tight bunch
local function press_grapes_apart(grapes, compactness)
  local spacing = GRAPE_SPACING_BY_COMPACTNESS[compactness]
  for _ = 1, 5 do
    for i = 1, #grapes do
      local a = grapes[i]
      for j = i + 1, #grapes do
        local b = grapes[j]
        local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
        local distance, touching = sqrt(dx * dx + dy * dy + dz * dz), spacing * (a.radius + b.radius)
        if distance < touching and distance > 1e-6 then
          local k = 0.5 * (touching - distance) / distance
          a.x, a.y, a.z = a.x - dx * k, a.y - dy * k, a.z - dz * k
          b.x, b.y, b.z = b.x + dx * k, b.y + dy * k, b.z + dz * k
        end
      end
    end
  end
end

-- each branch's tip follows its grapes as they were pressed apart, and their pedicels run
-- from it to them
local function attach_pedicels(bunch)
  local real_mm_bp, stalks = bunch.real_mm * BP_PER_CM, bunch.stalks
  for _, branch in ipairs(bunch.branches) do
    local tip, count = branch.tip, #branch.grapes
    for _, grape in ipairs(branch.grapes) do
      tip[1] = tip[1] + (grape.x - grape.grown_at[1]) / count
      tip[2] = tip[2] + (grape.y - grape.grown_at[2]) / count
      tip[3] = tip[3] + (grape.z - grape.grown_at[3]) / count
    end
    local tip_x, tip_y, tip_z = tip[1], tip[2], tip[3]
    for _, grape in ipairs(branch.grapes) do
      local joint = { lerp(tip_x, grape.x, 0.45), lerp(tip_y, grape.y, 0.45) + 0.1 * bunch.grape_radius,
        lerp(tip_z, grape.z, 0.45) }
      stalks[#stalks + 1] = { from = { tip_x, tip_y, tip_z }, to = joint, width = 1.1 * real_mm_bp }
      stalks[#stalks + 1] = { from = joint, to = { grape.x, grape.y, grape.z }, width = 0.9 * real_mm_bp }
    end
  end
end

-- the stalks: the peduncle from the node, the wing's arm or a tendril, then the bunch's own.
-- A bunch is a tendril that flowers, and its peduncle often forks: the fork grows into a
-- wing, a small bunch of its own, or stays a bare tendril, curving out and up
local function paint_bunch_stalks(bunch)
  local real_mm_bp, stalks = bunch.real_mm * BP_PER_CM, bunch.stalks
  local bezier, fork, length, outward = bunch.peduncle.bezier, bunch.fork, bunch.length, bunch.outward
  ink.move_to(0, 0)
  ink.curve_to(bezier[2][1], bezier[2][2], bezier[3][1], bezier[3][2], bezier[4][1], bezier[4][2])
  ink.stroke(STALK_COLOR, 5.5 * real_mm_bp, 1)
  ink.move_to(fork[1], fork[2])
  if bunch.vine.bunch_shape == "winged" then
    ink.line_to(bunch.wing[1], bunch.wing[2])
  else
    local rise = bunch.peduncle.length
    ink.curve_to(fork[1] + outward * 0.06 * length, fork[2] + 0.05 * rise, fork[1] + outward * 0.1 * length,
      fork[2] + 0.15 * rise, fork[1] + outward * 0.11 * length, fork[2] + 0.3 * rise)
  end
  ink.stroke(STALK_COLOR, 3 * real_mm_bp, 1)
  table.sort(stalks, function(a, b) return a.from[3] + a.to[3] < b.from[3] + b.to[3] end)
  for _, stalk in ipairs(stalks) do
    ink.move_to(stalk.from[1], stalk.from[2]) ink.line_to(stalk.to[1], stalk.to[2])
    ink.stroke(STALK_COLOR, stalk.width, 0.95)
  end
end

local function grape_bounds(grapes)
  local z_min, z_max, y_top, y_bottom = math.huge, -math.huge, -math.huge, math.huge
  for _, grape in ipairs(grapes) do
    z_min, z_max = min(z_min, grape.z), max(z_max, grape.z)
    y_top, y_bottom = max(y_top, grape.y), min(y_bottom, grape.y)
  end
  return z_min, z_max, y_top, y_bottom
end

-- occlusion: a grape lies under the grapes painted after it, each taken as a circle a
-- little smaller than it is. Points around and inside a circle a little larger than the
-- grape are tested, and one wholly under them is not drawn at all
local function is_wholly_covered(grapes, index, aspect)
  local grape = grapes[index]
  local reach = grape.radius * aspect * 1.05
  local function is_covered(x, y)
    for j = index + 1, #grapes do
      local above = grapes[j]
      local cover_radius = 0.9 * above.radius
      if (x - above.x) ^ 2 + (y - above.y) ^ 2 < cover_radius * cover_radius then return true end
    end
    return false
  end
  if not is_covered(grape.x, grape.y) then return false end
  for s = 1, 24 do
    if not is_covered(grape.x + reach * cos(s * pi / 12), grape.y + reach * sin(s * pi / 12)) then return false end
  end
  for s = 1, 8 do
    if not is_covered(grape.x + 0.55 * reach * cos(s * pi / 4), grape.y + 0.55 * reach * sin(s * pi / 4)) then return false end
  end
  return true
end

-- each grape ripens in its own time, and a shot berry never does
local function grape_ripeness(grape, bunch_ripeness)
  if grape.is_shot_berry then return 0 end
  return clamp((bunch_ripeness - 0.6 * grape.ripening_lag) / 0.4 + (bunch_ripeness >= 1 and 1 or 0), 0, 1)
end

-- a grape's skin goes from green through veraison to its ripe color, a dark grape's by way of
-- a red blush; grapes of one bunch differ in shade (gewurztraminer's from gold to red-brown)
local function skin_color(appearance, ripeness, tint)
  local variety, color = appearance.variety, nil
  if appearance.berry_tone == "pale" then
    color = mix_colors(COLORS.unripe_grape, variety.grape_color, ripeness)
  elseif ripeness < 0.5 then
    color = mix_colors(COLORS.unripe_grape, COLORS.veraison_blush, 2 * ripeness)
  else
    color = mix_colors(COLORS.veraison_blush, variety.grape_color, 2 * ripeness - 1)
  end
  if variety.alternate_grape_color then
    local alternate = mix_colors(COLORS.unripe_grape, variety.alternate_grape_color, ripeness)
    color = mix_colors(color, alternate, variety.grape_color_variation * tint)
  end
  return color
end

-- its outline: its length along the way it hangs, foreshortened as that way turns toward the
-- reader
local function grape_oval(grape, aspect)
  local foreshortening = sqrt(grape.hang_x * grape.hang_x + grape.hang_y * grape.hang_y)
  local along_x, along_y = grape.hang_x / max(foreshortening, 1e-6), grape.hang_y / max(foreshortening, 1e-6)
  local length = grape.radius * (1 + (aspect - 1) * foreshortening)
  return { length = length, long_x = length * along_x, long_y = length * along_y,
    wide_x = -grape.radius * along_y, wide_y = grape.radius * along_x }
end

local OVAL_HANDLE = 0.55228475
local function trace_oval(x, y, oval, size)
  local k = OVAL_HANDLE
  local ax, ay, bx, by = size * oval.long_x, size * oval.long_y, size * oval.wide_x, size * oval.wide_y
  ink.move_to(x + ax, y + ay)
  ink.curve_to(x + ax + k * bx, y + ay + k * by, x + bx + k * ax, y + by + k * ay, x + bx, y + by)
  ink.curve_to(x + bx - k * ax, y + by - k * ay, x - ax + k * bx, y - ay + k * by, x - ax, y - ay)
  ink.curve_to(x - ax - k * bx, y - ay - k * by, x - bx - k * ax, y - by - k * ay, x - bx, y - by)
  ink.curve_to(x - bx + k * ax, y - by + k * ay, x + ax - k * bx, y + ay - k * by, x + ax, y + ay)
  ink.close_path()
end

-- the bloom is a powder, not a film: clipped to the grape, three irregular drifts of it
-- overlapping, thicker where they cross; on a rubbed grape they lie off to one side,
-- leaving the skin bare along the other. It is palest at the rim, fading inward
local function paint_bloom(rng, grape, oval, bloom_color, wax, rubbed)
  local x, y, radius = grape.x, grape.y, grape.radius
  trace_oval(x, y, oval, 1) ink.clip()
  local rub_angle = radians(grape.rub_angle)
  local offset_x, offset_y = rubbed and -0.3 * radius * cos(rub_angle) or 0, rubbed and -0.3 * radius * sin(rub_angle) or 0
  for _ = 1, 3 do
    ink.trace_smooth_curve(ink.wobbly_ellipse(rng, x + offset_x + rng.plus_or_minus(0.35) * radius,
      y + offset_y + rng.plus_or_minus(0.35) * radius, radius * rng.between(0.6, 1.0), oval.length * rng.between(0.6, 1.0),
      0.35, 9), true)
    ink.fill(bloom_color, 0.5 * wax)
  end
  ink.end_clip()
  trace_oval(x, y, oval, 0.95) ink.stroke(bloom_color, 0.9, min(0.18, 0.35 * wax))
  trace_oval(x, y, oval, 0.97) ink.stroke(bloom_color, 0.4, min(0.28, 0.5 * wax))
end

-- where the bloom is rubbed off, a patch of glossy skin with its own small sharp highlight,
-- and elsewhere the soft broad highlight that the wax scatters
local function paint_highlight(grape, appearance, bloom_color, wax, rubbed, shade)
  local x, y, radius, light_side = grape.x, grape.y, grape.radius, appearance.light_side
  if appearance.is_dark then
    -- a dark grape has no hard glint: a soft sheen, discs fading outward, in a pale tint of
    -- its bloom
    local sheen = mix_colors(bloom_color, COLORS.white, 0.45)
    local sheen_x, sheen_y = x - 0.3 * radius * light_side, y + 0.3 * radius
    for _, size in ipairs({ 0.42, 0.3, 0.18 }) do
      ink.trace_circle(sheen_x, sheen_y, size * radius) ink.fill(sheen, 0.09 * shade)
    end
  elseif rubbed then
    local rub_angle = radians(grape.rub_angle)
    ink.trace_circle(x + 0.55 * radius * cos(rub_angle), y + 0.55 * radius * sin(rub_angle), 0.07 * radius)
    ink.fill(COLORS.white, 0.35)
  elseif wax > 0.12 then
    ink.trace_circle(x - 0.3 * radius * light_side, y + 0.3 * radius, 0.38 * radius) ink.fill(COLORS.white, 0.16 * shade)
  else
    ink.trace_circle(x - 0.36 * radius * light_side, y + 0.36 * radius, 0.15 * radius) ink.fill(COLORS.white, 0.65 * shade)
  end
end

-- rusty flecks on a ripe white grape
local function paint_rust_flecks(grape)
  local x, y, radius = grape.x, grape.y, grape.radius
  local angle = grape.tint * 2 * pi * 7
  ink.trace_circle(x + 0.45 * radius * cos(angle), y - 0.3 * radius * sin(angle), 0.07 * radius)
  ink.trace_circle(x - 0.2 * radius * sin(angle), y - 0.5 * radius * cos(angle), 0.05 * radius)
  ink.fill(COLORS.rust, 0.7)
end

-- Each grape is its skin, darker the further back and the lower in the bunch's shade it
-- hangs; then its bloom, the powdery wax over it, thicker on some grapes than others and
-- palest at the rim, where the skin is seen edge on; then its highlight
local function paint_grape(grape, appearance)
  local radius, variety = grape.radius, appearance.variety
  local ripeness = grape_ripeness(grape, appearance.ripeness)
  local skin = skin_color(appearance, ripeness, grape.tint)
  local nearness = (grape.z - appearance.z_min) / max(1e-6, appearance.z_max - appearance.z_min)
  local lowness = (appearance.y_top - grape.y) / max(1e-6, appearance.y_top - appearance.y_bottom)
  local shade = (0.55 + 0.45 * nearness) * (1 - 0.2 * lowness)
  local oval = grape_oval(grape, appearance.aspect)
  trace_oval(grape.x, grape.y, oval, 1) ink.fill(scale_color(skin, shade))
  trace_oval(grape.x + 0.12 * radius * appearance.light_side, grape.y - 0.1 * radius, oval, 0.82)
  ink.fill(scale_color(skin, min(1.2, shade * 1.1)), 0.45)
  local bloom_color = mix_colors(COLORS.unripe_grape, appearance.bloom_color, ripeness)
  local wax = variety.bloom_thickness * (0.45 + 1.1 * grape.bloom_variation) * ripeness
  local rubbed = wax > 0.12 and grape.rub_roll < 0.4
  if wax > 0.06 then paint_bloom(grape.rng, grape, oval, bloom_color, wax, rubbed) end
  paint_highlight(grape, appearance, bloom_color, wax, rubbed, shade)
  if variety.rusty_spots and ripeness > 0.8 and grape.tint > 0.4 then paint_rust_flecks(grape) end
  trace_oval(grape.x, grape.y, oval, 1)
  ink.stroke(scale_color(skin, appearance.is_dark and 0.7 or 0.42), 0.18, appearance.is_dark and 0.4 or 0.8)
end

-- the grapes, the furthest first. Each draws from a stream of its own, so those drawn look
-- as they would with the hidden ones left in
local function paint_grapes(rng, bunch, spec)
  local grapes, berry_tone = bunch.grapes, spec.vine.berry_tone
  local appearance = { variety = spec.variety, berry_tone = berry_tone, is_dark = berry_tone == "dark",
    bloom_color = COLORS.bloom_by_berry_tone[berry_tone], ripeness = spec.ripeness, light_side = spec.light_side,
    aspect = GRAPE_ASPECT_BY_SHAPE[spec.vine.berry_shape] }
  appearance.z_min, appearance.z_max, appearance.y_top, appearance.y_bottom = grape_bounds(grapes)
  table.sort(grapes, function(a, b) return a.z < b.z end)
  for i, grape in ipairs(grapes) do
    grape.rng = rng.fork()
    grape.is_hidden = is_wholly_covered(grapes, i, appearance.aspect)
  end
  for _, grape in ipairs(grapes) do
    if not grape.is_hidden then paint_grape(grape, appearance) end
  end
end

-- a bunch hanging from the origin down -y: spec.length long, its grapes spec.grape_radius in
-- radius, its stalk reaching out to spec.outward's side (1 right, -1 left) from the shoot
function M.draw(rng, spec)
  local vine, variety, length, outward = spec.vine, spec.variety, spec.length, spec.outward
  local peduncle = peduncle_of(rng, length, outward)
  local bunch = { vine = vine, grape_radius = spec.grape_radius, real_mm = 2 * spec.grape_radius / variety.grape_diameter_mm,
    length = length, outward = outward, peduncle = peduncle, stalks = {}, grapes = {}, branches = {} }
  local top = peduncle.bezier[4]
  local tilt = outward * (12 + rng.plus_or_minus(8))
  grow_panicle(rng, bunch, { x = top[1], y = top[2], z = 0, length = length, tilt = tilt,
    grape_count = variety.grapes_per_bunch })
  local wing_side = rng.random_sign()
  local fork_x, fork_y = bezier_point(peduncle.bezier, 0.55)
  bunch.fork = { fork_x, fork_y }
  bunch.wing = { fork_x + wing_side * 0.22 * length, fork_y - 0.05 * length }
  if vine.bunch_shape == "winged" then
    local wing_z = rng.plus_or_minus(0.1) * length
    local wing_tilt = wing_side * rng.between(15, 30)
    grow_panicle(rng, bunch, { x = bunch.wing[1], y = bunch.wing[2], z = wing_z, length = 0.45 * length, tilt = wing_tilt,
      grape_count = floor(0.3 * variety.grapes_per_bunch) })
  end
  press_grapes_apart(bunch.grapes, vine.compactness)
  attach_pedicels(bunch)
  paint_bunch_stalks(bunch)
  paint_grapes(rng, bunch, spec)
end

-- out from the node, then bending a little down into the bunch's own stalk, as thick as it
-- (5.5 mm, on the bunch's scale)
function M.draw_stalk_from_node(node, stalk_end, outward, grape_radius, grape_diameter_mm)
  local bend_x, bend_y = heading_vector(-20)
  ink.move_to(node[1], node[2])
  ink.curve_to(lerp(node[1], stalk_end[1], 0.4), lerp(node[2], stalk_end[2], 0.4), stalk_end[1] - outward * 0.06 * bend_x,
    stalk_end[2] - 0.06 * bend_y, stalk_end[1], stalk_end[2])
  ink.stroke(STALK_COLOR, 5.5 * 2 * grape_radius / grape_diameter_mm * BP_PER_CM, 1)
end

return M
