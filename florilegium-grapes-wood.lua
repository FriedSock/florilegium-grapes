-- florilegium-grapes-wood.lua -- the vine's old wood: its barked trunk and arms, the knobs
-- and cut faces that years of pruning leave, and the trenzado's braid of old canes.
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE or florilegium-grapes.sty.

local ink = require("florilegium-grapes-ink")
local COLORS = require("florilegium-grapes-palette")
local shoots = require("florilegium-grapes-shoot")
local M = {}

local sin, cos, sqrt, exp, pi, floor = math.sin, math.cos, math.sqrt, math.exp, math.pi, math.floor
local max, min, abs = math.max, math.min, math.abs
local radians, lerp, clamp, heading_vector = ink.radians, ink.lerp, ink.clamp, ink.heading_vector
local mix_colors, scale_color = ink.mix_colors, ink.scale_color

-- ---------------------------------------------------------------- bark
local function bark_strip_width(rng, index)
  if index % 2 == 0 then return rng.between(0.3, 0.6) end
  return rng.between(0.35, 0.8)
end

-- bark peels in strips, lighter and darker by turns
local function stroke_bark_strip(index, width, light_opacity, dark_opacity)
  if index % 2 == 0 then
    ink.stroke(COLORS.bark_light, width, light_opacity)
  else
    ink.stroke(COLORS.bark_dark, width, dark_opacity)
  end
end

-- a trunk or an arm along the centerline, start_width wide at its start to end_width at its
-- end (cm): a band of bark with long strips of it, lighter and darker, twisting round
function M.draw_old_wood(rng, centerline, start_width, end_width)
  local distances, total = ink.distances_along(centerline)
  local left_edge, right_edge, across = {}, {}, {}
  for i, point in ipairs(centerline) do
    local nx, ny = ink.left_normal_at(centerline, i)
    local half_width = lerp(start_width, end_width, distances[i] / total) / 2 * (1 + 0.12 * sin(distances[i] * 9 + i))
    left_edge[i] = { point[1] + nx * half_width, point[2] + ny * half_width }
    right_edge[i] = { point[1] - nx * half_width, point[2] - ny * half_width }
    across[i] = { nx * half_width, ny * half_width }
  end
  local outline = ink.band_outline(left_edge, right_edge)
  ink.trace_smooth_curve(outline, true) ink.fill(COLORS.bark)
  for k = 1, 14 do
    local offset, twist, phase = rng.plus_or_minus(0.85), rng.between(1.2, 3.8), rng.between(0, 2 * pi)
    local strip = {}
    for i, point in ipairs(centerline) do
      local f = clamp(offset + 0.45 * sin(distances[i] * twist + phase), -0.88, 0.88)
      strip[i] = { point[1] + across[i][1] * f, point[2] + across[i][2] * f }
    end
    ink.trace_smooth_curve(strip, false)
    stroke_bark_strip(k, bark_strip_width(rng, k), 0.55, 0.7)
  end
  ink.trace_smooth_curve(outline, true) ink.stroke(COLORS.bark_dark, 0.35, 0.8)
end

-- ---------------------------------------------------------------- old wood
-- Where a vine has been pruned in the same place year after year (the head of its trunk, each
-- spur position along a cordon, a cordon's end), the wood swells into a knob. Every cut leaves
-- a wound the bark rolls in over: a ring of callus round a face of pale dead wood, which may
-- rot to a hollow. The stubs of old canes and spurs are left standing, dead and grey, a finger's
-- length above the living wood, as growers leave them so that the wood drying out behind a cut
-- (its desiccation cone) stays in the stub. Pruners keep the wounds to one side, so the sap runs
-- on unhindered along the other
local STUB_FACE_COLOR = mix_colors(COLORS.heartwood, COLORS.dead_wood, 0.4)
local SCAR_FACE_COLOR = mix_colors(COLORS.heartwood, COLORS.bark, 0.35)
local CALLUS_COLOR = mix_colors(COLORS.bark, COLORS.bark_light, 0.6)
local LIVE_SPUR_COLOR = mix_colors(COLORS.bark, COLORS.cane, 0.5)

function M.trace_ellipse(x, y, radius_x, radius_y, rotation)
  local points = {}
  for i = 0, 11 do
    local angle = i / 12 * 2 * pi
    local px, py = radius_x * cos(angle), radius_y * sin(angle)
    points[#points + 1] = { x + px * cos(rotation) - py * sin(rotation), y + px * sin(rotation) + py * cos(rotation) }
  end
  ink.trace_smooth_curve(points, true)
end

-- a cut's face, seen at a slant: radius_x across the cut wood (along rotation, in radians),
-- radius_y foreshortened; its growth rings, the callus rolling in round it, now and then
-- rotted hollow
function M.draw_cut_face(rng, x, y, radius_x, radius_y, rotation, rotten, face_color)
  M.trace_ellipse(x, y, 1.25 * radius_x, 1.35 * radius_y, rotation) ink.fill(CALLUS_COLOR)
  M.trace_ellipse(x, y, radius_x, radius_y, rotation) ink.fill(face_color)
  M.trace_ellipse(x, y, 0.55 * radius_x, 0.55 * radius_y, rotation) ink.stroke(scale_color(face_color, 0.8), 0.3, 0.6)
  if rotten then
    M.trace_ellipse(x + rng.plus_or_minus(0.15 * radius_x), y + rng.plus_or_minus(0.15 * radius_y), 0.45 * radius_x,
      0.45 * radius_y, rotation)
    ink.fill(COLORS.bark_dark, 0.85)
  end
  M.trace_ellipse(x, y, radius_x, radius_y, rotation) ink.stroke(COLORS.bark_dark, 0.3, 0.8)
end

-- the knob's edge is lumpy, and bulges toward each stub
local function knob_edge(rng, knob)
  local bumps = {}
  for _, stub in ipairs(knob.stubs) do bumps[#bumps + 1] = { angle = radians(stub.angle), height = 0.25, width = 0.5 } end
  for _ = 1, 5 do
    local angle, height = rng.between(0, 2 * pi), rng.between(0.06, 0.2)
    bumps[#bumps + 1] = { angle = angle, height = height, width = rng.between(0.25, 0.7) }
  end
  local phase3, phase7 = rng.between(0, 2 * pi), rng.between(0, 2 * pi)
  local function radius_at(angle)
    local k = 1 + 0.07 * sin(3 * angle + phase3) + 0.04 * sin(7 * angle + phase7)
    for _, bump in ipairs(bumps) do
      local off = (angle - bump.angle + pi) % (2 * pi) - pi
      k = k + bump.height * exp(-(off / bump.width) ^ 2)
    end
    return knob.radius * k
  end
  return function(angle, fraction)
    local radius = radius_at(angle) * (fraction or 1)
    return knob.x + radius * cos(angle), knob.y + knob.squash * radius * sin(angle)
  end
end

-- a stub standing out of the knob: a dead one weathered and split along its grain, its cut
-- end showing
local function draw_stub(rng, stub, knob, edge_point)
  local dx, dy = heading_vector(stub.angle)
  local start_x, start_y = edge_point(radians(stub.angle))
  local end_x, end_y = start_x + dx * stub.length, start_y + dy * stub.length
  local root_x, root_y = lerp(knob.x, start_x, 0.4), lerp(knob.y, start_y, 0.4)
  shoots.draw_round_stem({ { root_x, root_y }, { lerp(root_x, end_x, 0.5), lerp(root_y, end_y, 0.5) }, { end_x, end_y } },
    1.3 * stub.width, stub.width, stub.live and LIVE_SPUR_COLOR or COLORS.dead_wood)
  if not stub.live then
    ink.move_to(lerp(start_x, end_x, 0.1) - 0.15 * stub.width * dy, lerp(start_y, end_y, 0.1) + 0.15 * stub.width * dx)
    ink.line_to(lerp(start_x, end_x, 0.85) - 0.1 * stub.width * dy, lerp(start_y, end_y, 0.85) + 0.1 * stub.width * dx)
    ink.stroke(scale_color(COLORS.dead_wood, 0.55), 0.3, 0.7)
    M.draw_cut_face(rng, end_x, end_y, 0.5 * stub.width, 0.22 * stub.width, radians(stub.angle + 90 + rng.plus_or_minus(15)),
      rng.chance(0.3), STUB_FACE_COLOR)
  end
  return { end_x, end_y }
end

local function trace_knob_crescent(edge_point, middle, depth)
  local points = {}
  for i = 0, 12 do points[#points + 1] = { edge_point(middle + (i / 12 - 0.5) * 3.2) } end
  for i = 12, 0, -1 do
    local t = i / 12 - 0.5
    points[#points + 1] = { edge_point(middle + t * 3.2, 1 - depth * cos(t * pi)) }
  end
  ink.trace_smooth_curve(points, true)
end

-- rounded, so shaded on the side away from the light and lit on the side toward it
local function shade_knob(edge_point, light_side)
  local away_from_light = math.atan(-1, light_side)
  trace_knob_crescent(edge_point, away_from_light, 0.4) ink.fill(scale_color(COLORS.bark, 0.6), 0.65)
  trace_knob_crescent(edge_point, away_from_light + pi, 0.25) ink.fill(COLORS.bark_light, 0.35)
end

-- its bark in strands, running in from the wood it grows from and on into each stub, or
-- over its top, swinging round its middle as grain swings round a knot
local function draw_knob_strands(rng, knob, edge_point, join)
  local strand_ends = { join + pi }
  for _, stub in ipairs(knob.stubs) do strand_ends[#strand_ends + 1] = radians(stub.angle) end
  for k = 1, max(6, floor(22 * knob.radius / knob.scale)) do
    local from = join + rng.plus_or_minus(1.2)
    local to = rng.pick(strand_ends) + rng.plus_or_minus(0.3)
    local sweep, sag = (to - from + pi) % (2 * pi) - pi, rng.between(0.15, 0.75)
    local strand = {}
    for i = 0, 5 do
      local t = i / 5
      strand[#strand + 1] = { edge_point(from + sweep * t, 0.97 - sag * sin(pi * t)) }
    end
    ink.trace_smooth_curve(strand, false)
    stroke_bark_strip(k, bark_strip_width(rng, k), 0.5, 0.65)
  end
end

-- the flush cuts on its face, toward the wound's side
local function draw_knob_scars(rng, knob, edge_point)
  local count = knob.scar_count
  local wound_angle = knob.wound_side > 0 and 0 or pi
  for j = 1, count do
    local x, y = edge_point(wound_angle + (j - (count + 1) / 2) * 1.1 + rng.plus_or_minus(0.3), rng.between(0.4, 0.7))
    local radius_x = rng.between(0.1, 0.18) * knob.radius
    M.draw_cut_face(rng, x, y, radius_x, radius_x * rng.between(0.45, 0.75), rng.between(0, pi), rng.chance(0.4), SCAR_FACE_COLOR)
  end
end

-- its edge, left open where it grows out of the wood below it
local function draw_knob_rim(knob, edge_point, join)
  local from = knob.rim and radians(knob.rim[1]) or join + 0.35 * pi
  local to = knob.rim and radians(knob.rim[2]) or join + 1.65 * pi
  local rim = {}
  for i = 0, 40 do rim[#rim + 1] = { edge_point(lerp(from, to, i / 40)) } end
  ink.trace_smooth_curve(rim, false) ink.stroke(COLORS.bark_dark, 0.35, 0.8)
end

-- a knob of old wood at knob.x, y, about knob.radius in radius and knob.squash times that
-- high, lit from knob.light_side, knob.scale the page's scale. knob.stubs: what stands out of
-- it, each { angle, length, width, live }: a dead stub of an old cane or spur, cut, or a live
-- one, last year's wood carrying this year's. knob.scar_count: how many flush cuts on its face,
-- toward knob.wound_side. knob.join_angle: the angle the wood it grows from comes in at (below,
-- by default), where it has no edge of its own; knob.rim: from and to which angles it has one
-- (by default, all the way round but there). Returns where each stub ends, and the knob's edge
function M.draw_pruning_knob(rng, knob)
  local edge_point = knob_edge(rng, knob)
  local stub_ends = {}
  for i, stub in ipairs(knob.stubs) do stub_ends[i] = draw_stub(rng, stub, knob, edge_point) end
  local outline = {}
  for i = 0, 23 do outline[#outline + 1] = { edge_point(i / 24 * 2 * pi) } end
  ink.trace_smooth_curve(outline, true) ink.fill(COLORS.bark)
  shade_knob(edge_point, knob.light_side)
  local join = radians(knob.join_angle or -90)
  draw_knob_strands(rng, knob, edge_point, join)
  draw_knob_scars(rng, knob, edge_point)
  draw_knob_rim(knob, edge_point, join)
  return stub_ends, edge_point
end

-- ---------------------------------------------------------------- the braid
-- The cordón trenzado: each year's cane is plaited onto the old ones, so the cordon grows into
-- a loose rope of old canes, each kinked at its nodes and wandering over and under the
-- others, painted from the deepest. BRAID_LOOSENESS: 0 a tight bundle of six to eight canes,
-- 1 two to four spread wide
local BRAID_LOOSENESS = 0.6

local function braided_cane(rng, point_and_normal_at, braid_length, real_cm, looseness)
  local width = rng.between(1.8, 4.2) * real_cm
  local offset = rng.plus_or_minus(lerp(1.5, 5, looseness) * real_cm)
  local amplitude = rng.between(1, 2.5) * lerp(1, 2, looseness) * real_cm
  local wavelength, phase, depth_bias = rng.between(30, 60) * real_cm, rng.between(0, 2 * pi), rng.plus_or_minus(0.3)
  local nodes, distance = {}, 0
  while true do
    local x, y, nx, ny = point_and_normal_at(distance)
    local across = offset + amplitude * sin(phase) + rng.plus_or_minus(0.5 * real_cm)
    nodes[#nodes + 1] = { x + nx * across, y + ny * across, width = width * rng.between(0.8, 1.15),
      depth = clamp(cos(phase) + depth_bias, -1, 1) }
    if distance >= braid_length then break end
    local step = rng.between(4, 9) * real_cm
    distance = min(braid_length, distance + step)
    phase = phase + 2 * pi * step / wavelength * rng.between(0.6, 1.4)
  end
  return { nodes = nodes, depth = depth_bias }
end

function M.braid_canes(rng, centerline, real_cm)
  local count = #centerline
  local distances, braid_length = ink.distances_along(centerline)
  local function point_and_normal_at(distance)
    local i = 1
    while i < count - 1 and distances[i + 1] < distance do i = i + 1 end
    local t = clamp((distance - distances[i]) / max(1e-9, distances[i + 1] - distances[i]), 0, 1)
    local tx, ty = centerline[i + 1][1] - centerline[i][1], centerline[i + 1][2] - centerline[i][2]
    local length = max(1e-9, sqrt(tx * tx + ty * ty))
    return lerp(centerline[i][1], centerline[i + 1][1], t), lerp(centerline[i][2], centerline[i + 1][2], t),
      -ty / length, tx / length
  end
  local canes = {}
  for k = 1, floor(rng.between(lerp(6, 2, BRAID_LOOSENESS), lerp(8, 4, BRAID_LOOSENESS))) do
    canes[k] = braided_cane(rng, point_and_normal_at, braid_length, real_cm, BRAID_LOOSENESS)
  end
  table.sort(canes, function(a, b) return a.depth < b.depth end)
  return canes
end

local function offset_side(nodes, first, last, side, padding)
  local edge = {}
  for i = first, last do
    local node = nodes[i]
    local nx, ny = ink.left_normal_at(nodes, i)
    local offset = side * node.width / 2 + (padding or 0) * side
    edge[#edge + 1] = { node[1] + nx * offset, node[2] + ny * offset }
  end
  return edge
end

local function paint_braided_cane(cane, first, last)
  local nodes = cane.nodes
  local left_edge, right_edge = offset_side(nodes, first, last, 1), offset_side(nodes, first, last, -1)
  ink.trace_polyline(ink.band_outline(left_edge, right_edge), true) ink.fill(COLORS.bark)
  for k, strip in ipairs(cane.bark_strips) do
    local line = {}
    for i = first, last do
      local node = nodes[i]
      local nx, ny = ink.left_normal_at(nodes, i)
      local across = clamp(strip.offset + 0.45 * sin(cane.distances[i] * strip.twist + strip.phase), -0.88, 0.88)
      local offset = across * node.width / 2
      line[#line + 1] = { node[1] + nx * offset, node[2] + ny * offset }
    end
    ink.trace_smooth_curve(line, false)
    stroke_bark_strip(k, strip.width, 0.55, 0.7)
  end
  ink.trace_polyline(left_edge, false) ink.trace_polyline(right_edge, false) ink.stroke(COLORS.bark_dark, 0.35, 0.8)
end

local function cane_value_at_x(cane, x, key)
  local nodes = cane.nodes
  for j = 1, #nodes - 1 do
    if nodes[j][1] <= x and nodes[j + 1][1] >= x then
      return lerp(nodes[j][key], nodes[j + 1][key], (x - nodes[j][1]) / max(1e-9, nodes[j + 1][1] - nodes[j][1]))
    end
  end
end
local function cane_y_at(cane, x) return cane_value_at_x(cane, x, 2) end
local function cane_width_at(cane, x) return cane_value_at_x(cane, x, "width") end
local function cane_depth_at(cane, x) return cane_value_at_x(cane, x, "depth") end

local function padded_outline(nodes, first, last)
  return ink.band_outline(offset_side(nodes, first, last, 1, 0.012), offset_side(nodes, first, last, -1, 0.012))
end

local function nodes_spanning(nodes, low_x, high_x)
  local first, last = 1, #nodes
  while first < #nodes and nodes[first + 1][1] < low_x do first = first + 1 end
  while last > 1 and nodes[last - 1][1] > high_x do last = last - 1 end
  return first, last
end

local function repaint_earlier_cane_over_later(canes, earlier, later_index, low_x, high_x, later_first, later_last)
  ink.trace_polyline(padded_outline(canes[later_index].nodes, later_first, later_last), true) ink.clip()
  for following = later_index + 1, #canes do
    local nodes = canes[following].nodes
    ink.trace_polyline({ { low_x - 1, -50 }, { high_x + 1, -50 }, { high_x + 1, 50 }, { low_x - 1, 50 } }, true)
    ink.trace_polyline(padded_outline(nodes, nodes_spanning(nodes, low_x, high_x)), true)
    ink.clip(true)
  end
  paint_braided_cane(earlier, nodes_spanning(earlier.nodes, low_x, high_x))
  for _ = later_index, #canes do ink.end_clip() end
end

-- where a cane painted earlier crosses in front of one painted later, it is painted again
-- over it, so the canes weave over and under each other
local function weave_crossings(canes)
  for earlier_index = 1, #canes - 1 do
    local earlier = canes[earlier_index]
    for later_index = earlier_index + 1, #canes do
      local later = canes[later_index].nodes
      local function overlaps(j)
        local p, q = later[j], later[j + 1]
        local middle_x = (p[1] + q[1]) / 2
        local y, width = cane_y_at(earlier, middle_x), cane_width_at(earlier, middle_x)
        return y and abs(y - (p[2] + q[2]) / 2) < (width + (p.width + q.width) / 2) / 2
      end
      local i = 1
      while i < #later do
        if overlaps(i) then
          local j, depth_lead = i, 0
          while j < #later and overlaps(j) do
            local middle_x = (later[j][1] + later[j + 1][1]) / 2
            depth_lead = depth_lead + cane_depth_at(earlier, middle_x) - (later[j].depth + later[j + 1].depth) / 2
            j = j + 1
          end
          if depth_lead > 0 then repaint_earlier_cane_over_later(canes, earlier, later_index, later[i][1], later[j][1], i, j) end
          i = j
        else
          i = i + 1
        end
      end
    end
  end
end

function M.draw_braid(rng, canes)
  for _, cane in ipairs(canes) do
    cane.distances = ink.distances_along(cane.nodes)
    cane.bark_strips = {}
    for k = 1, 6 do
      cane.bark_strips[k] = { offset = rng.plus_or_minus(0.85), twist = rng.between(1.2, 3.8), phase = rng.between(0, 2 * pi),
        width = bark_strip_width(rng, k) }
    end
    paint_braided_cane(cane, 1, #cane.nodes)
  end
  weave_crossings(canes)
end

return M
