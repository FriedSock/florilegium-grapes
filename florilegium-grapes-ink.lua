-- florilegium-grapes-ink.lua -- the drawing core: geometry in Lua, raw PDF out.
-- Copyright (c) 2026 Kevin Raymond. MIT License: see LICENSE or florilegium-grapes.sty.
--
-- Everything is computed here and written as PDF path operators into a literal node, so
-- TeX does no arithmetic at all. A drawing is made in a local frame (centimeters) under an
-- affine transform that maps it to the page (big points); strokes are absolute widths in bp.
-- A color is a table {r, g, b} in 0..1.

local M = {}

local fmt, floor, sin, cos, pi = string.format, math.floor, math.sin, math.cos, math.pi
local concat = table.concat
local rad = pi / 180
local CM = 72 / 2.54                       -- bp per cm

-- ---------------------------------------------------------------- random
-- mulberry32 (Tommy Ettinger, 2017, public domain): small, fast, identical on
-- every platform (math.random is not)
function M.rng(seed)
  local s = floor(seed) & 0xffffffff
  local r = {}
  function r.u()
    s = (s + 0x6D2B79F5) & 0xffffffff
    local t = s
    t = ((t ~ (t >> 15)) * (t | 1)) & 0xffffffff
    t = (t ~ (t + (((t ~ (t >> 7)) * (t | 61)) & 0xffffffff))) & 0xffffffff
    return ((t ~ (t >> 14)) & 0xffffffff) / 4294967296
  end
  function r.range(a, b) return a + (b - a) * r.u() end
  function r.sym(a) return a * (2 * r.u() - 1) end
  function r.chance(p) return r.u() < p end
  function r.fork() return M.rng(floor(r.u() * 4294967295)) end   -- an independent stream
  return r
end

M.white = { 1, 1, 1 }

-- ---------------------------------------------------------------- transforms
-- an affine map {a,b,c,d,e,f}: x' = a x + c y + e,  y' = b x + d y + f
local T = { CM, 0, 0, CM, 0, 0 }           -- current transform: local cm -> page bp
local stack = {}

function M.set_transform(t) T = t end
-- the page: cm from the lower-left corner of the paper -> bp. With `mirror` (the paper
-- width in cm) x becomes mirror - x: a vine laid out in the left margin is drawn,
-- reflected, in the right one
function M.page_transform(mirror)
  if mirror then return { -CM, 0, 0, CM, mirror * CM, 0 } end
  return { CM, 0, 0, CM, 0, 0 }
end
function M.push() stack[#stack + 1] = T end
function M.pop() T = table.remove(stack) end
function M.translate(x, y) T = { T[1], T[2], T[3], T[4], T[1] * x + T[3] * y + T[5], T[2] * x + T[4] * y + T[6] } end
function M.rotate(deg)
  local c, s = cos(deg * rad), sin(deg * rad)
  T = { T[1] * c + T[3] * s, T[2] * c + T[4] * s, -T[1] * s + T[3] * c, -T[2] * s + T[4] * c, T[5], T[6] }
end
function M.scale(sx, sy) sy = sy or sx T = { T[1] * sx, T[2] * sx, T[3] * sy, T[4] * sy, T[5], T[6] } end

-- ---------------------------------------------------------------- output
-- Output goes into numbered layers; flush() writes them in order as one literal.
-- ExtGState resources for opacity and blending are registered with pgf.
local layers, cur = {}, 5
local function put(s)
  local b = layers[cur]
  if not b then b = {} layers[cur] = b end
  b[#b + 1] = s
end
function M.layer(n) local old = cur cur = n return old end

local gs_known = {}
local function gs(op, mult)
  op = floor(op * 100 + 0.5)
  if op >= 100 and not mult then return nil end
  local name = fmt("flogr%s%d", mult and "m" or "a", op)
  if not gs_known[name] then
    gs_known[name] = true
    tex.sprint(luatexbase.registernumber("catcodetable@atletter"),
      fmt("\\pgfutil@addpdfresource@extgs{/%s << /ca %.2f /CA %.2f%s >>}", name, op / 100, op / 100, mult and " /BM /Multiply" or ""))
  end
  return name
end

-- 0.1 bp (0.035 mm) is finer than any printer resolves. A coordinate that is not a finite
-- number (a division by zero somewhere in a drawing) would be written as nan or inf, which
-- no PDF reader parses: it stops the drawing with an error instead
local HUGE = math.huge
local function P(x, y)
  local px, py = T[1] * x + T[3] * y + T[5], T[2] * x + T[4] * y + T[6]
  if px ~= px or py ~= py or px == HUGE or px == -HUGE or py == HUGE or py == -HUGE then
    error(fmt("florilegium-grapes: a drawing produced a coordinate that is not a number (%s, %s)", px, py), 0)
  end
  return fmt("%.1f %.1f", px, py)
end

-- path construction: polyline or smooth (Catmull-Rom as Béziers) through points {{x,y},...}
local path = {}
function M.moveto(x, y) path[#path + 1] = P(x, y) .. " m" end
function M.lineto(x, y) path[#path + 1] = P(x, y) .. " l" end
function M.curveto(x1, y1, x2, y2, x3, y3) path[#path + 1] = P(x1, y1) .. " " .. P(x2, y2) .. " " .. P(x3, y3) .. " c" end
function M.close() path[#path + 1] = "h" end
function M.poly(pts, closed)
  path[#path + 1] = P(pts[1][1], pts[1][2]) .. " m"
  for i = 2, #pts do path[#path + 1] = P(pts[i][1], pts[i][2]) .. " l" end
  if closed then path[#path + 1] = "h" end
end
function M.smooth(pts, closed, tension)
  local n = #pts
  if n < 3 then return M.poly(pts, closed) end
  local k = (tension or 1) / 6
  local function at(i)
    if closed then return pts[(i - 1) % n + 1] end
    return pts[math.max(1, math.min(n, i))]
  end
  path[#path + 1] = P(pts[1][1], pts[1][2]) .. " m"
  local last = closed and n or n - 1
  for i = 1, last do
    local p0, p1, p2, p3 = at(i - 1), at(i), at(i + 1), at(i + 2)
    path[#path + 1] = P(p1[1] + (p2[1] - p0[1]) * k, p1[2] + (p2[2] - p0[2]) * k) .. " " ..
      P(p2[1] - (p3[1] - p1[1]) * k, p2[2] - (p3[2] - p1[2]) * k) .. " " .. P(p2[1], p2[2]) .. " c"
  end
  if closed then path[#path + 1] = "h" end
end
function M.circle(x, y, r)
  local k = 0.5523 * r
  path[#path + 1] = P(x + r, y) .. " m " .. P(x + r, y + k) .. " " .. P(x + k, y + r) .. " " .. P(x, y + r) .. " c " ..
    P(x - k, y + r) .. " " .. P(x - r, y + k) .. " " .. P(x - r, y) .. " c " ..
    P(x - r, y - k) .. " " .. P(x - k, y - r) .. " " .. P(x, y - r) .. " c " ..
    P(x + k, y - r) .. " " .. P(x + r, y - k) .. " " .. P(x + r, y) .. " c h"
end
local function take() local s = concat(path, " ") path = {} return s end

local function rgb(c, stroke) return fmt(stroke and "%.3f %.3f %.3f RG" or "%.3f %.3f %.3f rg", c[1], c[2], c[3]) end

-- paint the current path. opacity < 1 or mult=true wraps it in its own graphics state
function M.fill(c, op, mult)
  local g = gs(op or 1, mult)
  if g then put("q /" .. g .. " gs " .. rgb(c) .. " " .. take() .. " f Q")
  else put(rgb(c) .. " " .. take() .. " f") end
end
function M.stroke(c, w, op, mult)
  local g = gs(op or 1, mult)
  local s = rgb(c, true) .. fmt(" %.2f w ", w) .. take() .. " S"
  if g then put("q /" .. g .. " gs " .. s .. " Q") else put("q " .. s .. " Q") end
end
-- clip to the current path until the matching unclip()
function M.clip(evenodd) put("q " .. take() .. (evenodd and " W* n" or " W n")) end
function M.unclip() put("Q") end

-- write all layers, in order, as one literal node at the current position
function M.flush()
  local keys = {}
  for k in pairs(layers) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = concat(layers[k], "\n") end
  layers = {}
  if #parts == 0 then return end
  local n = node.new("whatsit", "pdf_literal")
  n.mode = 0
  n.data = "q 1 J 1 j\n" .. concat(parts, "\n") .. "\nQ"
  node.write(n)
end

-- ---------------------------------------------------------------- geometry
-- the cumulative length along a polyline, and its total
function M.arclen(pts)
  local s, acc = { 0 }, 0
  for i = 2, #pts do acc = acc + math.sqrt((pts[i][1] - pts[i - 1][1]) ^ 2 + (pts[i][2] - pts[i - 1][2]) ^ 2) s[i] = acc end
  return s, acc
end

-- an irregular blob: a circle of radius r whose radius wobbles by `rough`
function M.blob(rng, x, y, rx, ry, rough, n)
  n = n or 9
  local ph, ph2, rot = rng.range(0, 2 * pi), rng.range(0, 2 * pi), rng.range(0, 2 * pi)
  local out = {}
  for i = 0, n - 1 do
    local a = 2 * pi * i / n
    local k = 1 + rough * (0.6 * sin(2 * a + ph) + 0.4 * sin(3 * a + ph2)) + rough * 0.5 * rng.sym(1)
    local px, py = rx * k * cos(a), ry * k * sin(a)
    out[#out + 1] = { x + px * cos(rot) - py * sin(rot), y + px * sin(rot) + py * cos(rot) }
  end
  return out
end

return M
