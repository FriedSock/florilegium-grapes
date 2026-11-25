-- florilegium-grapes-leaf.lua -- a vine leaf: its lobed and toothed outline, its blade bent,
-- posed and lit, its veins and its hairs.
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE or florilegium-grapes.sty.

local ink = require("florilegium-grapes-ink")
local COLORS = require("florilegium-grapes-palette")
local M = {}

local sin, cos, sqrt, pi, floor, max = math.sin, math.cos, math.sqrt, math.pi, math.floor, math.max
local min, abs = math.min, math.abs
local radians, lerp, clamp, mix_colors = ink.radians, ink.lerp, ink.clamp, ink.mix_colors
local scale_color, append_all = ink.scale_color, ink.append_all

local function lobe_tip(angle, length) return { angle = angle, length = length } end
local function radians_from_midrib(x, y) return math.atan(x, y) end

-- The outline in polar form about the point where the stalk meets the blade (the origin),
-- the midrib along +y, length 1: the lobe tips (angle from the midrib, length) and the
-- sinus between each and the next as a share of the shorter one cut away; the stalk's sinus
-- runs between the basal lobes through 180 degrees, down to the origin
local function leaf_plan(rng, lobe_count, sinus_depth, basal_lobe_angle)
  local basal = basal_lobe_angle + rng.plus_or_minus(4)
  if lobe_count >= 5 then
    local upper, lower = 54 + rng.plus_or_minus(4), 106 + rng.plus_or_minus(5)
    return {
      tips = { lobe_tip(-basal, 0.62), lobe_tip(-lower, 0.82), lobe_tip(-upper, 0.95), lobe_tip(0, 1),
        lobe_tip(upper, 0.95), lobe_tip(lower, 0.82), lobe_tip(basal, 0.62) },
      sinus_depths = { 0.1 + 0.2 * sinus_depth, 0.6 * sinus_depth, sinus_depth, sinus_depth, 0.6 * sinus_depth,
        0.1 + 0.2 * sinus_depth },
    }
  end
  local side = 62 + rng.plus_or_minus(4)
  return {
    tips = { lobe_tip(-basal, 0.64), lobe_tip(-side, 0.95), lobe_tip(0, 1), lobe_tip(side, 0.95), lobe_tip(basal, 0.64) },
    sinus_depths = { 0.12, sinus_depth, sinus_depth, 0.12 },
  }
end

-- a lobe is broad, round-shouldered, with a short point at its tip, and drops steeply into a
-- narrow sinus
local function ease_from_tip_into_sinus(tip_radius, sinus_radius, u)
  return tip_radius + (sinus_radius - tip_radius) * u ^ 2.6 + tip_radius * 0.07 * max(0, 1 - 5 * u) ^ 2
end

local STALK_SINUS_RADIUS = 0.03
local function radius_in_stalk_sinus(tips, angle)
  local last, first = tips[#tips], tips[1]
  local around = angle < 0 and angle + 360 or angle
  if around <= 180 then
    return ease_from_tip_into_sinus(last.length, STALK_SINUS_RADIUS, (around - last.angle) / (180 - last.angle))
  end
  return ease_from_tip_into_sinus(first.length, STALK_SINUS_RADIUS, (first.angle + 360 - around) / (first.angle + 360 - 180))
end

local function outline_radius(plan, angle)
  local tips = plan.tips
  for k = 1, #tips - 1 do
    local this_tip, next_tip = tips[k], tips[k + 1]
    if angle >= this_tip.angle and angle <= next_tip.angle then
      local sinus_angle = (this_tip.angle + next_tip.angle) / 2
      local sinus_radius = min(this_tip.length, next_tip.length) * (1 - plan.sinus_depths[k])
      if angle <= sinus_angle then
        return ease_from_tip_into_sinus(this_tip.length, sinus_radius, (angle - this_tip.angle) / (sinus_angle - this_tip.angle))
      end
      return ease_from_tip_into_sinus(next_tip.length, sinus_radius, (next_tip.angle - angle) / (next_tip.angle - sinus_angle))
    end
  end
  return radius_in_stalk_sinus(tips, angle)
end

local function outline_point(plan, angle, fraction_of_radius)
  local radius = outline_radius(plan, angle) * (fraction_of_radius or 1)
  return radius * sin(radians(angle)), radius * cos(radians(angle))
end

local function sampled_outline(plan)
  local points = {}
  for i = 0, 240 do points[#points + 1] = { outline_point(plan, -180 + 1.5 * i) } end
  return points
end

local function distance_walker(points, distances)
  local segment = 1
  return function(distance)
    while segment < #points - 1 and distances[segment + 1] < distance do segment = segment + 1 end
    local u = (distance - distances[segment]) / max(1e-9, distances[segment + 1] - distances[segment])
    return lerp(points[segment][1], points[segment + 1][1], u), lerp(points[segment][2], points[segment + 1][2], u)
  end
end

-- the edge with its teeth: the outline walked by arc length, a tooth every tooth_spacing, its
-- point toward the lobe tip it climbs to and none deep in a sinus
local function toothed_edge(plan, tooth_spacing)
  local outline = sampled_outline(plan)
  local distances, perimeter = ink.distances_along(outline)
  local point_at = distance_walker(outline, distances)
  local tooth_count = max(8, floor(perimeter / tooth_spacing))
  local step = perimeter / tooth_count
  local edge = {}
  for k = 0, tooth_count - 1 do
    local start = k * step
    local start_x, start_y = point_at(start)
    local middle_x, middle_y = point_at(min(perimeter, start + 0.5 * step))
    local climbing_toward_tip = middle_x * middle_x + middle_y * middle_y > start_x * start_x + start_y * start_y
    local tooth_x, tooth_y = point_at(start + (climbing_toward_tip and 0.72 or 0.28) * step)
    local tooth_radius = sqrt(tooth_x * tooth_x + tooth_y * tooth_y)
    local tooth_height = 0.45 * step * clamp((tooth_radius - 0.2) / 0.3, 0, 1)
    edge[#edge + 1] = { start_x, start_y }
    edge[#edge + 1] = { tooth_x + tooth_height * tooth_x / tooth_radius, tooth_y + tooth_height * tooth_y / tooth_radius }
  end
  return edge
end

-- rips in an old leaf's edge: now and then a tear cut into the outline (the toothed edge in
-- the leaf's plane). Each takes out a short stretch of the edge, so it opens as wide as a
-- tooth or two, and runs crooked and ragged in toward the stalk to a point; none by the stalk
local function tear_positions(rng, edge, wear)
  local count = floor(wear * 2 * rng.between(0.3, 1.2) + 0.4)
  local positions = {}
  for _ = 1, count do
    local i = 6 + floor(rng.uniform() * (#edge - 12))
    if abs(radians_from_midrib(edge[i][1], edge[i][2])) < 2.3 then positions[#positions + 1] = i end
  end
  table.sort(positions, function(a, b) return a > b end)
  return positions
end

local function ragged_side_of_tear(rng, mouth, point_x, point_y, depth)
  local steps = {}
  for k = 1, 3 do
    local f = k / 4
    local jitter_x, jitter_y = rng.plus_or_minus(0.18) * depth, rng.plus_or_minus(0.18) * depth
    steps[k] = { lerp(mouth[1], point_x, f) + jitter_x * 0.3, lerp(mouth[2], point_y, f) + jitter_y * 0.3 }
  end
  return steps
end

local function tear_outline(rng, left_mouth, right_mouth, middle, wear)
  local radius = sqrt(middle[1] * middle[1] + middle[2] * middle[2])
  local inward_x, inward_y = -middle[1] / radius, -middle[2] / radius
  local depth = radius * rng.between(0.12, 0.26) * wear
  local point_x = (left_mouth[1] + right_mouth[1]) / 2 + depth * inward_x + rng.plus_or_minus(0.25) * depth * inward_y
  local point_y = (left_mouth[2] + right_mouth[2]) / 2 + depth * inward_y - rng.plus_or_minus(0.25) * depth * inward_x
  local left_side = ragged_side_of_tear(rng, left_mouth, point_x, point_y, depth)
  local right_side = ragged_side_of_tear(rng, right_mouth, point_x, point_y, depth)
  local tear = { left_mouth }
  append_all(tear, left_side)
  tear[#tear + 1] = { point_x, point_y }
  for k = #right_side, 1, -1 do tear[#tear + 1] = right_side[k] end
  tear[#tear + 1] = right_mouth
  return tear
end

local function replace_range(list, first, last, replacement)
  for _ = first, last do table.remove(list, first) end
  for k = #replacement, 1, -1 do table.insert(list, first, replacement[k]) end
end

local function torn_edge(rng, edge, wear)
  local torn = {}
  for i, point in ipairs(edge) do torn[i] = point end
  local last_tear_start
  for _, i in ipairs(tear_positions(rng, edge, wear)) do
    if not last_tear_start or last_tear_start - i > 10 then
      local half_width = rng.chance(0.5) and 1 or 2
      local tear = tear_outline(rng, torn[i - half_width], torn[i + half_width], torn[i], wear)
      replace_range(torn, i - half_width, i + half_width, tear)
      last_tear_start = i - half_width
    end
  end
  return torn
end

-- The blade is a surface, not a plane: it cups about its midrib, its tip droops or arches,
-- its edge ripples between the lobes and it twists a little along its length; then it is
-- turned about its midrib (yaw) and tipped toward or away from the reader (pitch), and seen
-- from the front
local function bent_blade_surface(pose, tip_count)
  local cos_yaw, sin_yaw = cos(radians(pose.yaw)), sin(radians(pose.yaw))
  local cos_pitch, sin_pitch = cos(radians(pose.pitch)), sin(radians(pose.pitch))
  local ripples = tip_count + 2
  return function(x, y)
    local around = radians_from_midrib(x, y)
    local lift = pose.cup * x * x + pose.droop * y * y
      + pose.wave * (x * x + y * y) * sin(ripples * around + pose.wave_phase) + pose.twist * x * y
    local yawed_x, yawed_lift = x * cos_yaw + lift * sin_yaw, -x * sin_yaw + lift * cos_yaw
    return yawed_x, y * cos_pitch - yawed_lift * sin_pitch, y * sin_pitch + yawed_lift * cos_pitch
  end
end

local function projections_through(surface)
  local function project(x, y)
    local page_x, page_y = surface(x, y)
    return { page_x, page_y }
  end
  local function project_all(points)
    local projected = {}
    for i, point in ipairs(points) do projected[i] = project(point[1], point[2]) end
    return projected
  end
  return project, project_all
end

local function normal_facing_reader(surface, x, y)
  local step = 0.02
  local ax, ay, az = surface(x, y)
  local bx, by, bz = surface(x + step, y)
  local cx, cy, cz = surface(x, y + step)
  local ux, uy, uz = bx - ax, by - ay, bz - az
  local vx, vy, vz = cx - ax, cy - ay, cz - az
  local nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
  if nz < 0 then nx, ny, nz = -nx, -ny, -nz end
  return nx, ny, nz, sqrt(nx * nx + ny * ny + nz * nz)
end

-- Each patch of the blade is lit by how it faces the light, up and to the left of the page;
-- blade_rotation (radians) is the blade's angle on the page, to find that light in its frame
local function brightness_function(surface, light_side, blade_rotation)
  local light_x, light_y, light_z = -0.45 * light_side, 0.55, 0.7
  local blade_light_x = light_x * cos(-blade_rotation) - light_y * sin(-blade_rotation)
  local blade_light_y = light_x * sin(-blade_rotation) + light_y * cos(-blade_rotation)
  local light_length = sqrt(light_x * light_x + light_y * light_y + light_z * light_z)
  return function(x, y)
    local nx, ny, nz, normal_length = normal_facing_reader(surface, x, y)
    if normal_length < 1e-9 then return 0.6 end
    return (nx * blade_light_x + ny * blade_light_y + nz * light_z) / normal_length / light_length
  end
end

local function neighbouring_tip_angle(tips, k, toward)
  if toward > 0 then return k < #tips and tips[k + 1].angle or 180 end
  return k > 1 and tips[k - 1].angle or -180
end

-- each half lobe, lighter or darker by how its patch faces the light
local function shade_half_lobes(plan, project, brightness_at)
  local tips = plan.tips
  for k = 1, #tips do
    for _, toward in ipairs({ -1, 1 }) do
      local tip_angle = tips[k].angle
      local sinus_angle = (tip_angle + neighbouring_tip_angle(tips, k, toward)) / 2
      local patch = { project(0, 0) }
      for i = 0, 8 do patch[#patch + 1] = project(outline_point(plan, lerp(tip_angle, sinus_angle, i / 8), 0.97)) end
      local brightness = brightness_at(outline_point(plan, lerp(tip_angle, sinus_angle, 0.5), 0.55))
      ink.trace_polyline(patch, true)
      if brightness < 0.62 then
        ink.fill(COLORS.leaf_dark, clamp((0.62 - brightness) * 0.7, 0, 0.32), true)
      else
        ink.fill(COLORS.sunlit, clamp((brightness - 0.62) * 0.45, 0, 0.16))
      end
    end
  end
end

-- the hairs: a pale felt over the blade, and fine hairs lying every way across it, which
-- follow its surface
local function paint_hairs(rng, plan, edge, project_all, hairiness)
  ink.trace_polyline(edge, true) ink.fill(COLORS.hair, 0.28 * hairiness)
  for _ = 1, floor(180 * hairiness) do
    local angle, reach = rng.between(-170, 170), 0.92 * sqrt(rng.uniform())
    local x, y = outline_point(plan, angle, reach)
    local direction, length = rng.between(0, 2 * pi), rng.between(0.012, 0.028)
    local bend_x = x + 0.5 * length * cos(direction) + rng.plus_or_minus(0.01)
    local bend_y = y + 0.5 * length * sin(direction) + rng.plus_or_minus(0.01)
    local hair = { { x, y }, { bend_x, bend_y }, { x + length * cos(direction), y + length * sin(direction) } }
    ink.trace_smooth_curve(project_all(hair), false)
  end
  ink.stroke(COLORS.hair, 0.1, 0.4)
end

-- the main veins, each from the stalk to its lobe's tip
local function paint_main_veins(rng, plan, project, color, underside)
  for _, tip in ipairs(plan.tips) do
    local tip_x, tip_y = outline_point(plan, tip.angle, 0.95)
    local bow = rng.plus_or_minus(0.04)
    local vein = {}
    for i = 0, 8 do
      local u = i / 8
      vein[#vein + 1] = project(u * tip_x - bow * tip_y * 4 * u * (1 - u), u * tip_y + bow * tip_x * 4 * u * (1 - u))
    end
    ink.trace_smooth_curve(vein, false)
  end
  ink.stroke(color, underside and 0.65 or 0.45, 0.9)
end

-- the side veins off each main vein toward the edge; a basal lobe's only on its side away
-- from the stalk
local function paint_side_veins(rng, plan, project_all, color, underside)
  for _, tip in ipairs(plan.tips) do
    local sides = abs(tip.angle) > 120 and { tip.angle > 0 and -1 or 1 } or { -1, 1 }
    for _, along in ipairs({ 0.32, 0.52, 0.72 }) do
      for _, side in ipairs(sides) do
        local start_x, start_y = along * tip.length * sin(radians(tip.angle)), along * tip.length * cos(radians(tip.angle))
        local end_x, end_y = outline_point(plan, tip.angle + side * (30 - 18 * along + rng.plus_or_minus(4)), 0.9)
        local vein = { { start_x, start_y }, { lerp(start_x, end_x, 0.55) + rng.plus_or_minus(0.02), lerp(start_y, end_y, 0.55) },
          { end_x, end_y } }
        ink.trace_polyline(project_all(vein), false)
      end
    end
  end
  ink.stroke(color, underside and 0.32 or 0.22, 0.75)
end

-- a hairy leaf's edge is soft: a fringe of short hairs standing out from it
local function paint_edge_fringe(rng, edge, project_all, hairiness)
  for i = 1, #edge, 2 do
    local x, y = edge[i][1], edge[i][2]
    if sqrt(x * x + y * y) > 0.25 then
      local length = rng.between(0.015, 0.035) * hairiness
      local direction = math.atan(y, x) + rng.plus_or_minus(0.6)
      ink.trace_polyline(project_all({ { x, y }, { x + length * cos(direction), y + length * sin(direction) } }), false)
    end
  end
  ink.stroke(COLORS.hair, 0.15, 0.6)
end

-- a leaf of the vine, the midrib along +y from the origin, length 1 (the caller scales it).
-- leaf.color is its green (or its autumn color, or its old leaf's darker green); its blade is
-- bent and posed by leaf.pose (yaw, pitch in degrees; cup, droop, wave, wave_phase, twist)
-- and lit from leaf.light_side, its angle on the page being leaf.rotation (radians).
-- leaf.hairiness (0..1): how hairy the side seen is, a pale felt over it, fine hairs lying
-- across it and a fringe of them along its edge. leaf.wear (0..1): how worn the leaf is,
-- its edge torn here and there
function M.draw(rng, leaf)
  local plan = leaf_plan(rng, leaf.lobe_count, leaf.sinus_depth, leaf.basal_lobe_angle)
  local surface = bent_blade_surface(leaf.pose, #plan.tips)
  local project, project_all = projections_through(surface)
  local flat_edge = toothed_edge(plan, leaf.tooth_spacing)
  if leaf.wear > 0.35 then flat_edge = torn_edge(rng, flat_edge, leaf.wear) end
  local edge = project_all(flat_edge)
  ink.trace_polyline(edge, true) ink.fill(leaf.color)
  ink.trace_polyline(edge, true) ink.clip()
  shade_half_lobes(plan, project, brightness_function(surface, leaf.light_side, leaf.rotation))
  if leaf.hairiness > 0.05 then paint_hairs(rng, plan, edge, project_all, leaf.hairiness) end
  local vein_color = leaf.underside and mix_colors(leaf.color, COLORS.underside_vein, 0.6)
    or mix_colors(leaf.color, COLORS.vein, 0.55)
  paint_main_veins(rng, plan, project, vein_color, leaf.underside)
  paint_side_veins(rng, plan, project_all, vein_color, leaf.underside)
  ink.end_clip()
  ink.trace_polyline(edge, true) ink.stroke(scale_color(leaf.color, 0.6), 0.25, 0.8)
  if leaf.hairiness > 0.25 then paint_edge_fringe(rng, flat_edge, project_all, leaf.hairiness) end
end

return M
