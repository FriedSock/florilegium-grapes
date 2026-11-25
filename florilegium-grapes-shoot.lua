-- florilegium-grapes-shoot.lua -- the green parts of a shoot: its round stem, its tendrils and
-- its growing tip.
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE or florilegium-grapes.sty.

local ink = require("florilegium-grapes-ink")
local COLORS = require("florilegium-grapes-palette")
local M = {}

local sin, cos, pi, floor, max, min = math.sin, math.cos, math.pi, math.floor, math.max, math.min
local radians, lerp, heading_vector, mix_colors = ink.radians, ink.lerp, ink.heading_vector, ink.mix_colors
local scale_color, append_all = ink.scale_color, ink.append_all

-- a stem along the centerline, start_width wide at its start to end_width at its end (cm),
-- lit along its left side and shaded along its right, as a round stem is
function M.draw_round_stem(centerline, start_width, end_width, color)
  local distances, total = ink.distances_along(centerline)
  local left_edge, right_edge, highlight = {}, {}, {}
  for i, point in ipairs(centerline) do
    local nx, ny = ink.left_normal_at(centerline, i)
    local half_width = lerp(start_width, end_width, distances[i] / max(total, 1e-9)) / 2
    left_edge[i] = { point[1] + nx * half_width, point[2] + ny * half_width }
    right_edge[i] = { point[1] - nx * half_width, point[2] - ny * half_width }
    highlight[i] = { point[1] + nx * half_width * 0.45, point[2] + ny * half_width * 0.45 }
  end
  local outline = ink.band_outline(left_edge, right_edge)
  ink.trace_smooth_curve(outline, true) ink.fill(color)
  local shadow = {}
  append_all(shadow, right_edge)
  for i = #centerline, 1, -1 do
    shadow[#shadow + 1] = { lerp(right_edge[i][1], centerline[i][1], 0.7), lerp(right_edge[i][2], centerline[i][2], 0.7) }
  end
  ink.trace_smooth_curve(shadow, true) ink.fill(scale_color(color, 0.72), 0.7)
  ink.trace_smooth_curve(highlight, false) ink.stroke(mix_colors(color, COLORS.white, 0.35), 0.35, 0.6)
  ink.trace_smooth_curve(outline, true) ink.stroke(scale_color(color, 0.5), 0.25, 0.8)
end

local function draw_tendril_arm(rng, x, y, heading, length, width, color)
  local points, hand = { { x, y } }, rng.random_sign()
  local steps = 10
  for _ = 1, steps do
    heading = heading + hand * rng.between(2, 6)
    x, y = x + length * 0.55 / steps * cos(radians(heading)), y + length * 0.55 / steps * sin(radians(heading))
    points[#points + 1] = { x, y }
  end
  local coil_radius, turns = length * rng.between(0.09, 0.14), rng.between(1.4, 2.6)
  local coil_steps = floor(turns * 18)
  for i = 1, coil_steps do
    heading = heading + hand * 360 / 18
    local radius = coil_radius * (1 - 0.7 * i / coil_steps)
    x, y = x + 2 * pi * radius / 18 * cos(radians(heading)), y + 2 * pi * radius / 18 * sin(radians(heading))
    points[#points + 1] = { x, y }
  end
  ink.trace_smooth_curve(points, false) ink.stroke(color, width, 1)
end

-- along +x from the origin, `length` long: it forks, and each arm ends in a coil
function M.draw_tendril(rng, length, color)
  local fork_x, fork_y = 0.4 * length, rng.plus_or_minus(0.05) * length
  ink.move_to(0, 0) ink.curve_to(0.15 * length, 0.02 * length, 0.3 * length, fork_y, fork_x, fork_y)
  ink.stroke(color, 0.45, 1)
  draw_tendril_arm(rng, fork_x, fork_y, rng.between(15, 35), 0.65 * length, 0.32, color)
  draw_tendril_arm(rng, fork_x, fork_y, -rng.between(15, 35), 0.5 * length, 0.28, color)
end

-- a tendril that reaches a catch wire grips it, coiling round it
function M.draw_tendril_gripping_wire(rng, node, wire_y, scale, color)
  local grip_x = node[1] + rng.plus_or_minus(0.35) * scale
  ink.move_to(node[1], node[2])
  ink.curve_to(lerp(node[1], grip_x, 0.3), node[2] + 0.1, lerp(node[1], grip_x, 0.8), wire_y + 0.12, grip_x, wire_y)
  ink.stroke(color, 0.45, 1)
  local coil, turns = {}, floor(rng.between(3, 6))
  for k = 0, turns * 12 do
    local t = k / 12 * 2 * pi
    coil[#coil + 1] = { grip_x + 0.035 * scale * k / 12 * 1.4 + 0.05 * scale * cos(t) * 0.3, wire_y + 0.05 * scale * sin(t) }
  end
  ink.trace_smooth_curve(coil, false) ink.stroke(color, 0.35, 1)
end

local function folded_leaf_outline(base, heading, length, side)
  local dx, dy = heading_vector(heading)
  local outline = {}
  for k = 0, 8 do
    local s = k / 8
    local half_width = 0.32 * length * sin(pi * s) ^ 0.6 * (1 - 0.3 * s)
    outline[#outline + 1] = { base[1] + s * length * dx - side * half_width * dy,
      base[2] + s * length * dy + side * half_width * dx }
  end
  for k = 7, 1, -1 do
    local s = k / 8
    local half_width = 0.14 * length * sin(pi * s)
    outline[#outline + 1] = { base[1] + s * length * dx + side * half_width * dy,
      base[2] + s * length * dy - side * half_width * dx }
  end
  return outline
end

-- along +x from the origin, `length` long, the stem stem_width thick where it starts: a shoot
-- that is still growing ends in a soft tip, not a cut. Its last few centimetres nod over in a
-- hook, and the newest leaves, too young to have opened, stay folded along their midribs,
-- clasped round it one inside the next, the smallest at the very end. They are downy, the
-- more so in a hairy variety, and flushed bronze-red until they open and green up
function M.draw_growing_tip(rng, length, stem_width, stem_color, leaf_color, hairiness)
  local hand, bow = rng.random_sign(), rng.between(80, 130)
  local function heading_at(t) return hand * bow * t ^ 1.6 end
  local steps = 10
  local stem, x, y = { { 0, 0 } }, 0, 0
  for i = 1, steps do
    local dx, dy = heading_vector(heading_at(i / steps))
    x, y = x + length / steps * dx, y + length / steps * dy
    stem[#stem + 1] = { x, y }
  end
  M.draw_round_stem(stem, stem_width, 0.25 * stem_width, stem_color)
  -- each folded leaf a narrow blade from its node toward the tip, off to its own side; the
  -- outer ones longer, and the last a bud of them at the end
  local hair_color = mix_colors(leaf_color, COLORS.hair, 0.5 + 0.4 * hairiness)
  local side = rng.random_sign()
  for _, along in ipairs({ 0.3, 0.55, 0.78, 1 }) do
    side = -side
    local base = stem[min(1 + floor(along * steps + 0.5), #stem)]
    local heading = heading_at(along) + side * rng.between(6, 16)
    local leaf_length = length * lerp(0.6, 0.3, along) * rng.between(0.85, 1.1)
    local blade = folded_leaf_outline(base, heading, leaf_length, side)
    local dx, dy = heading_vector(heading)
    ink.trace_smooth_curve(blade, true) ink.fill(scale_color(leaf_color, lerp(0.85, 1.05, along)))
    ink.move_to(base[1], base[2]) ink.line_to(base[1] + 0.9 * leaf_length * dx, base[2] + 0.9 * leaf_length * dy)
    ink.stroke(scale_color(leaf_color, 0.7), 0.2, 0.7)
    ink.trace_smooth_curve(blade, true) ink.stroke(hair_color, 0.25 + 0.35 * hairiness, 0.85)
  end
end

return M
