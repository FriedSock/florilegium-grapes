-- florilegium-grapes-ink.lua -- the drawing core: geometry in Lua, raw PDF out.
-- Copyright (c) 2026 Kevin Raymond, 2026 Jack Bracewell. MIT License: see LICENSE or
-- florilegium-grapes.sty.
--
-- Everything is computed here and written as PDF path operators into a literal node, so
-- TeX does no arithmetic at all. A drawing is made in a local frame (centimeters) under an
-- affine transform that maps it to the page (big points); strokes are absolute widths in bp.
-- A color is a table {r, g, b} in 0..1.

local M = {}

local format, floor, sin, cos, pi = string.format, math.floor, math.sin, math.cos, math.pi
local concat = table.concat
local RADIANS_PER_DEGREE = pi / 180
local BP_PER_CM = 72 / 2.54

-- ---------------------------------------------------------------- random numbers
-- mulberry32 (Tommy Ettinger, 2017, public domain): small, fast, identical on
-- every platform (math.random is not)
function M.random_stream(seed)
  local state = floor(seed) & 0xffffffff
  local stream = {}
  function stream.uniform()
    state = (state + 0x6D2B79F5) & 0xffffffff
    local t = state
    t = ((t ~ (t >> 15)) * (t | 1)) & 0xffffffff
    t = (t ~ (t + (((t ~ (t >> 7)) * (t | 61)) & 0xffffffff))) & 0xffffffff
    return ((t ~ (t >> 14)) & 0xffffffff) / 4294967296
  end
  function stream.between(low, high) return low + (high - low) * stream.uniform() end
  function stream.plus_or_minus(spread) return spread * (2 * stream.uniform() - 1) end
  function stream.chance(probability) return stream.uniform() < probability end
  function stream.random_sign() return stream.chance(0.5) and 1 or -1 end
  function stream.pick(list) return list[1 + floor(#list * stream.uniform())] end
  function stream.fork() return M.random_stream(floor(stream.uniform() * 4294967295)) end
  return stream
end

-- ---------------------------------------------------------------- math
function M.radians(degrees) return degrees * RADIANS_PER_DEGREE end
function M.lerp(from, to, t) return from + (to - from) * t end
function M.clamp(value, low, high) return math.max(low, math.min(high, value)) end
function M.heading_vector(degrees) return cos(degrees * RADIANS_PER_DEGREE), sin(degrees * RADIANS_PER_DEGREE) end
function M.heading_of(dx, dy) return math.atan(dy, dx) / RADIANS_PER_DEGREE end
function M.mix_colors(a, b, t) return { M.lerp(a[1], b[1], t), M.lerp(a[2], b[2], t), M.lerp(a[3], b[3], t) } end
function M.scale_color(color, factor) return { color[1] * factor, color[2] * factor, color[3] * factor } end
function M.append_all(list, more) for _, item in ipairs(more) do list[#list + 1] = item end end

-- ---------------------------------------------------------------- transforms
-- an affine map {a, b, c, d, e, f}: x' = a x + c y + e,  y' = b x + d y + f
local current_transform = { BP_PER_CM, 0, 0, BP_PER_CM, 0, 0 }
local saved_transforms = {}

-- the page: cm from the lower-left corner of the paper -> bp. With `mirrored_paper_width` (the
-- paper's width in cm) x becomes that width - x: a vine laid out in the left margin is drawn,
-- reflected, in the right one
function M.set_page_transform(mirrored_paper_width)
  if mirrored_paper_width then
    current_transform = { -BP_PER_CM, 0, 0, BP_PER_CM, mirrored_paper_width * BP_PER_CM, 0 }
  else
    current_transform = { BP_PER_CM, 0, 0, BP_PER_CM, 0, 0 }
  end
end
function M.save_transform() saved_transforms[#saved_transforms + 1] = current_transform end
function M.restore_transform() current_transform = table.remove(saved_transforms) end
function M.translate(dx, dy)
  local t = current_transform
  current_transform = { t[1], t[2], t[3], t[4], t[1] * dx + t[3] * dy + t[5], t[2] * dx + t[4] * dy + t[6] }
end
function M.rotate(degrees)
  local t = current_transform
  local c, s = cos(degrees * RADIANS_PER_DEGREE), sin(degrees * RADIANS_PER_DEGREE)
  current_transform = { t[1] * c + t[3] * s, t[2] * c + t[4] * s, -t[1] * s + t[3] * c, -t[2] * s + t[4] * c, t[5], t[6] }
end
function M.scale(factor)
  local t = current_transform
  current_transform = { t[1] * factor, t[2] * factor, t[3] * factor, t[4] * factor, t[5], t[6] }
end

-- ---------------------------------------------------------------- output
-- Output goes into numbered layers; write_layers_to_page() writes them in order as one literal.
-- ExtGState resources for opacity and blending are registered with pgf.
local layers, current_layer = {}, 5
local function emit(operators)
  local layer = layers[current_layer]
  if not layer then layer = {} layers[current_layer] = layer end
  layer[#layer + 1] = operators
end
function M.select_layer(layer) current_layer = layer end

local registered_graphics_states = {}
local function graphics_state_for(opacity, multiply)
  local percent = floor(opacity * 100 + 0.5)
  if percent >= 100 and not multiply then return nil end
  local name = format("flogr%s%d", multiply and "m" or "a", percent)
  if not registered_graphics_states[name] then
    registered_graphics_states[name] = true
    tex.sprint(luatexbase.registernumber("catcodetable@atletter"),
      format("\\pgfutil@addpdfresource@extgs{/%s << /ca %.2f /CA %.2f%s >>}", name, percent / 100, percent / 100,
        multiply and " /BM /Multiply" or ""))
  end
  return name
end

-- 0.1 bp (0.035 mm) is finer than any printer resolves. A coordinate that is not a finite
-- number (a division by zero somewhere in a drawing) would be written as nan or inf, which
-- no PDF reader parses: it stops the drawing with an error instead
local HUGE = math.huge
local function is_finite(value) return value == value and value ~= HUGE and value ~= -HUGE end
local function point_on_page(x, y)
  local t = current_transform
  local page_x, page_y = t[1] * x + t[3] * y + t[5], t[2] * x + t[4] * y + t[6]
  if not (is_finite(page_x) and is_finite(page_y)) then
    error(format("florilegium-grapes: a drawing produced a coordinate that is not a number (%s, %s)", page_x, page_y), 0)
  end
  return format("%.1f %.1f", page_x, page_y)
end

local path = {}
local function add_to_path(operators) path[#path + 1] = operators end
local function take_path()
  local operators = concat(path, " ")
  path = {}
  return operators
end

function M.move_to(x, y) add_to_path(point_on_page(x, y) .. " m") end
function M.line_to(x, y) add_to_path(point_on_page(x, y) .. " l") end
function M.curve_to(x1, y1, x2, y2, x3, y3)
  add_to_path(point_on_page(x1, y1) .. " " .. point_on_page(x2, y2) .. " " .. point_on_page(x3, y3) .. " c")
end
function M.close_path() add_to_path("h") end

function M.trace_polyline(points, closed)
  M.move_to(points[1][1], points[1][2])
  for i = 2, #points do M.line_to(points[i][1], points[i][2]) end
  if closed then M.close_path() end
end

-- a smooth curve through the points: Catmull-Rom, as Béziers
local CATMULL_ROM_HANDLE = 1 / 6
function M.trace_smooth_curve(points, closed)
  local count = #points
  if count < 3 then return M.trace_polyline(points, closed) end
  local function point(i)
    if closed then return points[(i - 1) % count + 1] end
    return points[math.max(1, math.min(count, i))]
  end
  local k = CATMULL_ROM_HANDLE
  M.move_to(points[1][1], points[1][2])
  for i = 1, closed and count or count - 1 do
    local before, from, to, after = point(i - 1), point(i), point(i + 1), point(i + 2)
    M.curve_to(from[1] + (to[1] - before[1]) * k, from[2] + (to[2] - before[2]) * k,
      to[1] - (after[1] - from[1]) * k, to[2] - (after[2] - from[2]) * k, to[1], to[2])
  end
  if closed then M.close_path() end
end

local CIRCLE_HANDLE = 0.5523
function M.trace_circle(x, y, radius)
  local handle = CIRCLE_HANDLE * radius
  M.move_to(x + radius, y)
  M.curve_to(x + radius, y + handle, x + handle, y + radius, x, y + radius)
  M.curve_to(x - handle, y + radius, x - radius, y + handle, x - radius, y)
  M.curve_to(x - radius, y - handle, x - handle, y - radius, x, y - radius)
  M.curve_to(x + handle, y - radius, x + radius, y - handle, x + radius, y)
  M.close_path()
end

local function color_operator(color, for_stroke)
  return format(for_stroke and "%.3f %.3f %.3f RG" or "%.3f %.3f %.3f rg", color[1], color[2], color[3])
end

-- paint the current path. An opacity under 1, or the multiply blend, wraps it in its own
-- graphics state
function M.fill(color, opacity, multiply)
  local state = graphics_state_for(opacity or 1, multiply)
  if state then
    emit("q /" .. state .. " gs " .. color_operator(color) .. " " .. take_path() .. " f Q")
  else
    emit(color_operator(color) .. " " .. take_path() .. " f")
  end
end
function M.stroke(color, width_bp, opacity)
  local state = graphics_state_for(opacity or 1)
  local operators = color_operator(color, true) .. format(" %.2f w ", width_bp) .. take_path() .. " S"
  if state then emit("q /" .. state .. " gs " .. operators .. " Q") else emit("q " .. operators .. " Q") end
end
-- clip to the current path until the matching end_clip()
function M.clip(even_odd) emit("q " .. take_path() .. (even_odd and " W* n" or " W n")) end
function M.end_clip() emit("Q") end

-- write all layers, in order, as one literal node at the current position, and start afresh
function M.write_layers_to_page()
  local layer_numbers = {}
  for number in pairs(layers) do layer_numbers[#layer_numbers + 1] = number end
  table.sort(layer_numbers)
  local contents = {}
  for _, number in ipairs(layer_numbers) do contents[#contents + 1] = concat(layers[number], "\n") end
  layers = {}
  if #contents == 0 then return end
  local literal = node.new("whatsit", "pdf_literal")
  literal.mode = 0
  literal.data = "q 1 J 1 j\n" .. concat(contents, "\n") .. "\nQ"
  node.write(literal)
end

-- ---------------------------------------------------------------- geometry
-- how far along a polyline each of its points is, and its whole length
function M.distances_along(points)
  local distances, total = { 0 }, 0
  for i = 2, #points do
    total = total + math.sqrt((points[i][1] - points[i - 1][1]) ^ 2 + (points[i][2] - points[i - 1][2]) ^ 2)
    distances[i] = total
  end
  return distances, total
end

function M.left_normal_at(points, i)
  local before, after = points[math.max(1, i - 1)], points[math.min(#points, i + 1)]
  local tx, ty = after[1] - before[1], after[2] - before[2]
  local length = math.max(1e-9, math.sqrt(tx * tx + ty * ty))
  return -ty / length, tx / length
end

function M.band_outline(left_edge, right_edge)
  local outline = {}
  M.append_all(outline, left_edge)
  for i = #right_edge, 1, -1 do outline[#outline + 1] = right_edge[i] end
  return outline
end

-- the points of an irregular ellipse about x, y, whose radii wobble by `roughness`
function M.wobbly_ellipse(rng, x, y, radius_x, radius_y, roughness, point_count)
  local phase2, phase3, rotation = rng.between(0, 2 * pi), rng.between(0, 2 * pi), rng.between(0, 2 * pi)
  local points = {}
  for i = 0, point_count - 1 do
    local angle = 2 * pi * i / point_count
    local wobble = 1 + roughness * (0.6 * sin(2 * angle + phase2) + 0.4 * sin(3 * angle + phase3))
      + roughness * 0.5 * rng.plus_or_minus(1)
    local px, py = radius_x * wobble * cos(angle), radius_y * wobble * sin(angle)
    points[#points + 1] = { x + px * cos(rotation) - py * sin(rotation), y + px * sin(rotation) + py * cos(rotation) }
  end
  return points
end

return M
