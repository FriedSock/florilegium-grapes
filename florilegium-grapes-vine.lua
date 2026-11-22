-- florilegium-grapes-vine.lua -- one grapevine of a chosen variety, trained up the page's margin
-- as a vineyard's is, in its own colors.
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE or florilegium-grapes.sty.
--
-- A spur-pruned vine on a vertical shoot positioned trellis (see M.page for how it is laid
-- out), and its organs:
--   - a leaf is round, cut into five lobes (or three) by sinuses as deep as its variety cuts
--     them, with a sinus where the stalk joins, saw teeth that point to the lobe tips, five main
--     veins from the stalk and side veins off them;
--   - a bunch hangs from its node on a short stalk, its grapes packed round a branched stalk
--     in a cone, a cylinder or a cone with a wing, painted from the back to the front;
-- The season (g.age) ripens the grapes from green through veraison, and in autumn turns the
-- leaves red (a black grape's) or yellow (a white one's).
-- Use: \usepackage[vine=pinot]{florilegium-grapes} (or saperavi, gewurztraminer, rkatsiteli,
-- regent, johanniter).

local ink = require("florilegium-grapes-ink")
local M = {}

local sin, cos, sqrt, pi, floor, max, min, abs = math.sin, math.cos, math.sqrt, math.pi, math.floor, math.max,
  math.min, math.abs
local RAD = pi / 180
local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(v, a, b) return max(a, min(b, v)) end
local function mix(a, b, t) return { lerp(a[1], b[1], t), lerp(a[2], b[2], t), lerp(a[3], b[3], t) } end
local function scale(c, k) return { c[1] * k, c[2] * k, c[3] * k } end
local function dir(a) return cos(a * RAD), sin(a * RAD) end
local function deg(x, y) return math.atan(y, x) / RAD end
local function dist(x1, y1, x2, y2) return sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end

-- ---------------------------------------------------------------- colors
local C = {
  bark = { 0.37, 0.28, 0.2 }, barkdark = { 0.2, 0.14, 0.1 }, barklight = { 0.58, 0.48, 0.37 },
  shoot = { 0.4, 0.54, 0.2 }, cane = { 0.55, 0.4, 0.25 }, petiole = { 0.5, 0.46, 0.2 },
  leaf = { 0.25, 0.43, 0.14 }, leaflight = { 0.4, 0.58, 0.22 }, leafdark = { 0.13, 0.26, 0.08 },
  vein = { 0.72, 0.8, 0.5 }, red = { 0.6, 0.14, 0.12 }, yellow = { 0.84, 0.68, 0.2 },
  tendril = { 0.47, 0.6, 0.24 }, unripe = { 0.52, 0.66, 0.3 }, blush = { 0.58, 0.24, 0.32 },
}
local BERRY = { dark = { 0.16, 0.1, 0.21 }, red = { 0.52, 0.13, 0.2 }, pale = { 0.75, 0.78, 0.4 } }
local BLOOM = { dark = { 0.6, 0.64, 0.78 }, red = { 0.82, 0.66, 0.72 }, pale = { 0.94, 0.94, 0.78 } }

-- ---------------------------------------------------------------- the varieties
-- each variety's leaf: its size, how far its basal lobes close the stalk's sinus (its angle: 140
-- an open U, 170 nearly closed), its teeth; the bunch as the vineyard has it, its length in
-- cm, its grape's diameter in mm and how many grapes it holds; the grape's own color where
-- its tone's is not it, how thick its waxy bloom (saperavi's dusts it blue-grey), and white for
-- a white wine grape (its leaves turn yellow, not red).
-- Pinot noir's petiolar sinus is a V, open; regent's lyre-shaped, open to overlapping;
-- johanniter's an open U (German Wikipedia's ampelography); rkatsiteli's bunch is 12 to 24
-- cm long, about 160 g, its grapes golden with bronze spots (Georgian descriptions). The
-- other figures are typical values, and the colors and shapes were checked against photos
-- of bunches on Wikimedia Commons (pinot noir in Burgundy blue-black under a dusty bloom;
-- gewurztraminer's grapes each a shade from gold to red-brown; rkatsiteli's and johanniter's
-- flecked with rust; regent's round and larger, about 155 g a bunch).
-- hair: how hairy its leaves' undersides are (0..1); its young leaves near the tips are
-- hairy on top too. Rkatsiteli's leaves are known for their down, regent's young leaves are
-- white-woolly (German Wikipedia); the others typical
local VAR = {
  pinot = { leaf = 0.92, basal = 150, teeth = 0.06, cm = 13, mm = 13, n = 110, ink = { 0.14, 0.13, 0.25 }, bloom = 0.3,
    hair = 0.3 },
  saperavi = { leaf = 1.1, basal = 150, teeth = 0.075, cm = 15, mm = 15, n = 100, ink = { 0.16, 0.15, 0.3 }, bloom = 0.42,
    hair = 0.6 },
  gewurztraminer = { leaf = 0.85, basal = 142, teeth = 0.06, cm = 12, mm = 12, n = 90, ink = { 0.66, 0.36, 0.34 },
    alt = { 0.86, 0.64, 0.38 }, vary = 0.8, bloom = 0.12, white = true, hair = 0.4 },
  rkatsiteli = { leaf = 1.1, basal = 150, teeth = 0.08, cm = 17, mm = 16, n = 95, ink = { 0.8, 0.79, 0.5 },
    alt = { 0.86, 0.76, 0.44 }, vary = 0.5, spots = true, hair = 0.75 },
  regent = { leaf = 1.0, basal = 162, teeth = 0.07, cm = 13, mm = 15, n = 85, ink = { 0.12, 0.11, 0.2 }, bloom = 0.2,
    hair = 0.55 },
  johanniter = { leaf = 1.0, basal = 140, teeth = 0.07, cm = 13, mm = 14, n = 100, ink = { 0.9, 0.8, 0.52 },
    alt = { 0.84, 0.84, 0.58 }, vary = 0.4, spots = true, hair = 0.15 },
}
-- and the traits a vine of the variety may take, one each drawn for the document: lobes (3
-- or 5, as many as the leaf is cut into, any one of the list), depth (how deep its sinuses
-- cut, a range), tone (dark, red or pale grapes), berry (round, oval), bunch (cylindrical,
-- conical, winged) and compact (2 fairly dense, 3 dense). Pinot noir's leaf is slightly
-- lobed, three to five; saperavi's three-lobed; regent's three-lobed, rarely five, cut
-- medium-deep; johanniter's and rkatsiteli's five-lobed (Wikipedia's ampelography)
local TRAITS = {
  pinot = { lobes = { 3, 5 }, depth = { 0.15, 0.3 }, tone = "dark", berry = { "round", "round", "oval" },
    bunch = { "cylindrical" }, compact = 3 },
  saperavi = { lobes = { 3 }, depth = { 0.25, 0.4 }, tone = "dark", berry = { "oval", "round" }, bunch = { "conical" },
    compact = 2 },
  gewurztraminer = { lobes = { 3, 3, 3, 5 }, depth = { 0.08, 0.2 }, tone = "red", berry = { "oval" }, bunch = { "conical" },
    compact = 3 },
  rkatsiteli = { lobes = { 5 }, depth = { 0.35, 0.55 }, tone = "pale", berry = { "oval", "round" },
    bunch = { "conical", "conical", "winged" }, compact = 2 },
  regent = { lobes = { 3, 3, 3, 3, 5 }, depth = { 0.4, 0.55 }, tone = "dark", berry = { "round", "round", "oval" },
    bunch = { "cylindrical", "cylindrical", "conical" }, compact = 3 },
  johanniter = { lobes = { 5 }, depth = { 0.35, 0.5 }, tone = "pale", berry = { "round" }, bunch = { "cylindrical" },
    compact = 3 },
}
-- the document's vine of a variety (docseed: \florilegiumgrapesseed, or 0), the same on every page
local function vine(variety, docseed)
  local t = TRAITS[variety]
  if not t then
    local known = {}
    for k in pairs(TRAITS) do known[#known + 1] = k end
    table.sort(known)
    error("florilegium-grapes: vine=" .. tostring(variety) .. "? a grape's variety is one of " .. table.concat(known, ", "), 0)
  end
  local r = ink.rng(docseed * 104729 + 809)
  local function pick(list) return list[1 + floor(#list * r.u())] end
  return { variety = variety, teeth = pick(t.lobes), dissection = r.range(t.depth[1], t.depth[2]), berrytone = t.tone,
    berryshape = pick(t.berry), bunch = pick(t.bunch), compact = t.compact }
end
-- the bunches drawn a little larger than life, as an illustrator enlarges the fruit
local FRUIT = 1.3
local BRAID_LOOSENESS = 0.6

-- ---------------------------------------------------------------- the leaf
-- The outline in polar form about the point where the stalk meets the blade (the origin),
-- the midrib along +y, length 1: the lobe tips (angle from the midrib, length) and the
-- sinus between each and the next as a share of the shorter one cut away; the stalk's sinus
-- runs between the basal lobes through 180 degrees, down to the origin
local function leafplan(r, lobes, depth, basal)
  local ab = basal + r.sym(4)
  if lobes >= 5 then
    local as, ai = 54 + r.sym(4), 106 + r.sym(5)
    return { { -ab, 0.62 }, { -ai, 0.82 }, { -as, 0.95 }, { 0, 1 }, { as, 0.95 }, { ai, 0.82 }, { ab, 0.62 } },
      { 0.1 + 0.2 * depth, 0.6 * depth, depth, depth, 0.6 * depth, 0.1 + 0.2 * depth }
  end
  local as = 62 + r.sym(4)
  return { { -ab, 0.64 }, { -as, 0.95 }, { 0, 1 }, { as, 0.95 }, { ab, 0.64 } }, { 0.12, depth, depth, 0.12 }
end
-- the radius at angle th (degrees, -180..180): a lobe is broad, round-shouldered, with a
-- short point at its tip, and drops steeply into a narrow sinus
local function radius(tips, sd, th)
  local function ease(R0, Rm, u) return R0 + (Rm - R0) * u ^ 2.6 + R0 * 0.07 * max(0, 1 - 5 * u) ^ 2 end
  local n = #tips
  for k = 1, n - 1 do
    local a, b = tips[k], tips[k + 1]
    if th >= a[1] and th <= b[1] then
      local m = (a[1] + b[1]) / 2
      local Rm = min(a[2], b[2]) * (1 - sd[k])
      if th <= m then return ease(a[2], Rm, (th - a[1]) / (m - a[1])) end
      return ease(b[2], Rm, (b[1] - th) / (b[1] - m))
    end
  end
  local a, b = tips[n], tips[1]
  local t = th < 0 and th + 360 or th
  local rp = 0.03
  if t <= 180 then return ease(a[2], rp, (t - a[1]) / (180 - a[1])) end
  return ease(b[2], rp, (b[1] + 360 - t) / (b[1] + 360 - 180))
end
local function polar(tips, sd, th, k)
  local rr = radius(tips, sd, th) * (k or 1)
  return rr * sin(th * RAD), rr * cos(th * RAD)
end
-- the edge with its teeth: the outline walked by arc length, a tooth every ts, its point
-- toward the lobe tip it climbs to and none deep in a sinus
local function toothed(tips, sd, ts)
  local pts = {}
  for i = 0, 240 do pts[#pts + 1] = { polar(tips, sd, -180 + 1.5 * i) } end
  local s = { 0 }
  for i = 2, #pts do s[i] = s[i - 1] + dist(pts[i - 1][1], pts[i - 1][2], pts[i][1], pts[i][2]) end
  local total, j = s[#pts], 1
  local function at(d)
    while j < #pts - 1 and s[j + 1] < d do j = j + 1 end
    local u = (d - s[j]) / max(1e-9, s[j + 1] - s[j])
    return lerp(pts[j][1], pts[j + 1][1], u), lerp(pts[j][2], pts[j + 1][2], u)
  end
  local nt = max(8, floor(total / ts))
  local step = total / nt
  local out = {}
  for k = 0, nt - 1 do
    local d0 = k * step
    local x0, y0 = at(d0)
    local x1, y1 = at(min(total, d0 + 0.5 * step))
    local up = x1 * x1 + y1 * y1 > x0 * x0 + y0 * y0
    local xk, yk = at(d0 + (up and 0.72 or 0.28) * step)
    local rk = sqrt(xk * xk + yk * yk)
    local h = 0.45 * step * clamp((rk - 0.2) / 0.3, 0, 1)
    out[#out + 1] = { x0, y0 }
    out[#out + 1] = { xk + h * xk / rk, yk + h * yk / rk }
  end
  return out
end
-- a leaf of the vine, the midrib along +y from the origin, length 1 (the caller scales it):
-- c its green (or its autumn color), v its variety's numbers, lobes and depth its genome's.
-- The blade is a surface, not a plane: it cups about its midrib, its tip droops or arches,
-- its edge ripples between the lobes and it twists a little along its length; then it is
-- turned about its midrib (yaw) and tipped toward or away from the reader (pitch), and seen
-- from the front. Each half lobe is lit by how its own patch faces the light, up and to the
-- left of the page; rot is the blade's angle on the page (radians), to find that light.
-- pose: yaw, pitch (degrees), cup, droop, wave, wph, twist; nil is a flat leaf face on.
-- fuzz (0..1): how hairy the side seen is, a pale felt over it, fine hairs lying across it
-- and a fringe of them along its edge
local FLAT = { yaw = 0, pitch = 0, cup = 0, droop = 0, wave = 0, wph = 0, twist = 0 }
local HAIR = { 0.95, 0.96, 0.92 }
-- rips in an old leaf's edge: now and then a tear cut into the outline (raw, the toothed edge
-- in the leaf's plane). Each takes out a short stretch of the edge, so it opens as wide as a
-- tooth or two, and runs crooked and ragged in toward the stalk to a point; none by the stalk
local function tear(r, raw, old)
  local n = floor(old * 2 * r.range(0.3, 1.2) + 0.4)
  local at = {}
  for _ = 1, n do
    local i = 6 + floor(r.u() * (#raw - 12))
    if abs(math.atan(raw[i][1], raw[i][2])) < 2.3 then at[#at + 1] = i end
  end
  table.sort(at, function(a, b) return a > b end)
  local out, last = {}, nil
  for i, q in ipairs(raw) do out[i] = q end
  for _, i in ipairs(at) do
    if not last or last - i > 10 then
      local span = r.chance(0.5) and 1 or 2              -- edge points the tear takes out each side
      local qa, qb, q = out[i - span], out[i + span], out[i]
      local l = sqrt(q[1] * q[1] + q[2] * q[2])
      local ux, uy = -q[1] / l, -q[2] / l                -- inward, toward the stalk
      local d = l * r.range(0.12, 0.26) * old
      local tx = (qa[1] + qb[1]) / 2 + d * ux + r.sym(0.25) * d * uy
      local ty = (qa[2] + qb[2]) / 2 + d * uy - r.sym(0.25) * d * ux
      -- each side of the tear, from the mouth to the point, stepping raggedly
      local function side(p0)
        local pts = {}
        for k = 1, 3 do
          local f = k / 4
          local jx, jy = r.sym(0.18) * d, r.sym(0.18) * d
          pts[k] = { lerp(p0[1], tx, f) + jx * 0.3, lerp(p0[2], ty, f) + jy * 0.3 }
        end
        return pts
      end
      local left, right = side(qa), side(qb)
      local crack = { qa }
      for _, p in ipairs(left) do crack[#crack + 1] = p end
      crack[#crack + 1] = { tx, ty }
      for k = #right, 1, -1 do crack[#crack + 1] = right[k] end
      crack[#crack + 1] = qb
      for _ = i - span, i + span do table.remove(out, i - span) end
      for k = #crack, 1, -1 do table.insert(out, i - span, crack[k]) end
      last = i - span
    end
  end
  return out
end
-- old (0..1): how worn the leaf is: its edge torn here and there (its darker green is the
-- caller's, in c)
local function leaf(r, c, v, lobes, depth, lx, under, pose, rot, fuzz, old)
  pose, rot, fuzz, old = pose or FLAT, rot or 0, fuzz or 0, old or 0
  local tips, sd = leafplan(r, lobes, depth, v.basal)
  local cy, sy = cos(pose.yaw * RAD), sin(pose.yaw * RAD)
  local cp, sp_ = cos(pose.pitch * RAD), sin(pose.pitch * RAD)
  local nl = #tips + 2
  local function surf(x, y)
    local th = math.atan(x, y)
    local z = pose.cup * x * x + pose.droop * y * y + pose.wave * (x * x + y * y) * sin(nl * th + pose.wph)
      + pose.twist * x * y
    local x1, z1 = x * cy + z * sy, -x * sy + z * cy
    return x1, y * cp - z1 * sp_, y * sp_ + z1 * cp
  end
  local function P(x, y) local px, py = surf(x, y) return { px, py } end
  local function map(pts) local out = {} for i, q in ipairs(pts) do out[i] = P(q[1], q[2]) end return out end
  -- the light, in the blade's frame on the page
  local lpx, lpy, lpz = -0.45 * lx, 0.55, 0.7
  local lfx, lfy = lpx * cos(-rot) - lpy * sin(-rot), lpx * sin(-rot) + lpy * cos(-rot)
  local function lit(x, y)
    local h = 0.02
    local ax, ay, az = surf(x, y)
    local bx, by, bz = surf(x + h, y)
    local qx, qy, qz = surf(x, y + h)
    local ux, uy, uz = bx - ax, by - ay, bz - az
    local vx, vy, vz = qx - ax, qy - ay, qz - az
    local nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    local l = sqrt(nx * nx + ny * ny + nz * nz)
    if l < 1e-9 then return 0.6 end
    if nz < 0 then nx, ny, nz = -nx, -ny, -nz end
    return (nx * lfx + ny * lfy + nz * lpz) / l / sqrt(lpx * lpx + lpy * lpy + lpz * lpz)
  end
  local raw = toothed(tips, sd, v.teeth)
  if old > 0.35 then raw = tear(r, raw, old) end
  local edge = map(raw)
  ink.poly(edge, true) ink.fill(c)
  ink.poly(edge, true) ink.clip()                -- all that is drawn on the blade stays on it
  -- each half lobe, lighter or darker by how its patch faces the light
  for k = 1, #tips do
    for _, toward in ipairs({ -1, 1 }) do
      local a = tips[k][1]
      local b
      if toward > 0 then b = k < #tips and tips[k + 1][1] or 180 else b = k > 1 and tips[k - 1][1] or -180 end
      local m = (a + b) / 2
      local poly = { P(0, 0) }
      for i = 0, 8 do poly[#poly + 1] = P(polar(tips, sd, lerp(a, m, i / 8), 0.97)) end
      local cx, cy2 = polar(tips, sd, lerp(a, m, 0.5), 0.55)
      local b2 = lit(cx, cy2)
      ink.poly(poly, true)
      if b2 < 0.62 then ink.fill(C.leafdark, clamp((0.62 - b2) * 0.7, 0, 0.32), true)
      else ink.fill({ 1, 1, 0.85 }, clamp((b2 - 0.62) * 0.45, 0, 0.16)) end
    end
  end
  -- the hairs: a pale felt over the blade, and fine hairs lying every way across it, which
  -- follow its surface
  if fuzz > 0.05 then
    ink.poly(edge, true) ink.fill(HAIR, 0.28 * fuzz)
    for _ = 1, floor(180 * fuzz) do
      local th, k = r.range(-170, 170), 0.92 * sqrt(r.u())
      local x, y = polar(tips, sd, th, k)
      local a, l = r.range(0, 2 * pi), r.range(0.012, 0.028)
      local q = map({ { x, y }, { x + 0.5 * l * cos(a) + r.sym(0.01), y + 0.5 * l * sin(a) + r.sym(0.01) },
        { x + l * cos(a), y + l * sin(a) } })
      ink.smooth(q, false)
    end
    ink.stroke(HAIR, 0.1, 0.4)
  end
  -- the main veins, each to its lobe's tip, and the side veins off them toward the edge
  local vc = under and mix(c, { 0.93, 0.95, 0.85 }, 0.6) or mix(c, C.vein, 0.55)
  for _, t in ipairs(tips) do
    local tx, ty = polar(tips, sd, t[1], 0.95)
    local bend = r.sym(0.04)
    local pts = {}
    for i = 0, 8 do
      local u = i / 8
      pts[#pts + 1] = P(u * tx - bend * ty * 4 * u * (1 - u), u * ty + bend * tx * 4 * u * (1 - u))
    end
    ink.smooth(pts, false)
  end
  ink.stroke(vc, under and 0.65 or 0.45, 0.9)
  for _, t in ipairs(tips) do
    local sides = abs(t[1]) > 120 and { t[1] > 0 and -1 or 1 } or { -1, 1 }
    for _, f in ipairs({ 0.32, 0.52, 0.72 }) do
      for _, sg in ipairs(sides) do
        local x0, y0 = f * t[2] * sin(t[1] * RAD), f * t[2] * cos(t[1] * RAD)
        local te = t[1] + sg * (30 - 18 * f + r.sym(4))
        local x1, y1 = polar(tips, sd, te, 0.9)
        ink.poly(map({ { x0, y0 }, { lerp(x0, x1, 0.55) + r.sym(0.02), lerp(y0, y1, 0.55) }, { x1, y1 } }), false)
      end
    end
  end
  ink.stroke(vc, under and 0.32 or 0.22, 0.75)
  ink.unclip()
  ink.poly(edge, true) ink.stroke(scale(c, 0.6), 0.25, 0.8)
  -- a hairy leaf's edge is soft: a fringe of short hairs standing out from it
  if fuzz > 0.25 then
    for i = 1, #raw, 2 do
      local x, y = raw[i][1], raw[i][2]
      local l = sqrt(x * x + y * y)
      if l > 0.25 then
        local h = r.range(0.015, 0.035) * fuzz
        local a = math.atan(y, x) + r.sym(0.6)
        ink.poly(map({ { x, y }, { x + h * cos(a), y + h * sin(a) } }), false)
      end
    end
    ink.stroke(HAIR, 0.15, 0.6)
  end
end

-- ---------------------------------------------------------------- the bunch
-- A bunch is a panicle seen from the side: a bare peduncle, then the rachis, a main axis
-- that bends a little as the bunch hangs, with a spiral of branches off it, the longest at
-- the shoulders. Each branch arches down under the weight it carries and ends in a small
-- cluster of grapes that hangs below its tip, each grape on its pedicel. The bunch's outline
-- (an inverted pear, or a cylinder) is as wide as the variety's grapes need to cover it,
-- closely for a compact bunch and with gaps for a loose one; in a compact bunch the grapes
-- are drawn toward that outline, so it has no hollows between its clusters. A winged bunch
-- has a second, smaller panicle, the outer arm, splitting off the peduncle. Grapes that
-- collide are pushed apart. Grapes vary in size,
-- a few stay small and green (shot berries), and as the bunch ripens they color one by one.
-- Painted from the back: stalks, then grapes, nearer ones lighter.
-- From the origin down -y, L long; rb the grape's half width, want how many grapes
-- mm: cm on the page for a real mm (the stalks are drawn as thick as real ones)
local function panicle(r, sp, L, B, ox, oy, oz, tilt, rb, want, mm)
  local H = 0.78 * L
  local bx, bz = r.sym(0.15), r.sym(0.15)
  local ct, st = cos(tilt * RAD), sin(tilt * RAD)
  local function axis(t)                       -- the rachis, tilted, bending as it hangs
    local x, y = bx * t * t * H, -t * H
    return ox + x * ct - y * st, oy + x * st + y * ct, oz + bz * t * t * H
  end
  local function shape(t)
    if sp.bunch == "cylindrical" then
      return (t < 0.08 and 0.6 + 5 * t or 1) * (t > 0.8 and max(0.2, 1 - (t - 0.8) * 4) or 1)
    end
    -- an inverted pear: full, almost square shoulders at the top, then tapering steadily
    -- to a narrow, rounded tip
    if t < 0.12 then return 0.8 + 0.2 * sin(t / 0.12 * 90 * RAD) end
    return 1 - 0.75 * ((t - 0.12) / 0.88) ^ 1.1
  end
  -- the outline's radius: its surface (2 pi R H on average) covered to `cover` by the grapes
  local cover = ({ 0.55, 0.85, 0.92 })[sp.compact]
  local mean = 0
  for i = 1, 40 do mean = mean + shape((i - 0.5) / 40) / 40 end
  local R0 = want * rb * rb / (2 * H * cover * mean)
  local stalks = {}
  -- a stalk from one point to another, d mm thick (as bp on the page)
  local function stalk(x1, y1, z1, x2, y2, z2, d)
    stalks[#stalks + 1] = { x1, y1, z1, x2, y2, z2, d * mm * 28.3465 }
  end
  -- the rachis, about 4 mm thick at its top, thinning to 1.5 mm at its tip
  local prev = { axis(0) }
  for i = 1, 12 do
    local q = { axis(i / 12) }
    stalk(prev[1], prev[2], prev[3], q[1], q[2], q[3], lerp(4, 1.5, (i - 0.5) / 12))
    prev = q
  end
  local phi = r.range(0, 360)
  local function grape(gx, gy, gz, ax, ay, az, c, s_, size)
    local hx_, hy_ = 0.45 * c, -0.9
    local hl = sqrt(hx_ * hx_ + hy_ * hy_ + (0.45 * s_) ^ 2)
    B[#B + 1] = { gx, gy, gz, rb * size, ax, ay, az, shot = size < 0.7, turn = r.u(), tint = r.u(), thick = r.u(), rub = r.u(),
      rubat = r.range(0, 360), hx = hx_ / hl, hy = hy_ / hl,
      ped = stalks[#stalks] }
  end
  -- a spiral of branches off the rachis, the longest at the shoulders, each ending in a
  -- small cluster of grapes on short pedicels: a sphere of them about the branch's tip
  -- how many and where, after Shavrukov, Dry & Thomas (2004): 20 to 22 branches (nodes) on a
  -- tight bunch's rachis, 33 to 38 on a loose one's, each carrying a group of 6 to 8 flowers;
  -- the internodes between them longest at the top (a pair about 20 mm there, 5 mm by the
  -- middle), long and short by turns
  local nb = clamp(floor(want / ({ 3.5, 4.5, 5.5 })[sp.compact] + 0.5), 8, 38)
  local pos, acc = {}, 0
  for i = 1, nb do
    local len = (0.25 + 0.75 * math.exp(-(i - 1) / 2.6)) * (i % 2 == 1 and 1.35 or 0.65) * r.range(0.85, 1.15)
    acc = acc + len
    pos[i] = acc
  end
  local sum, shares = 0, {}
  for i = 1, nb do shares[i] = shape(pos[i] / acc) * r.range(0.7, 1.3) sum = sum + shares[i] end
  for i = 1, nb do
    local t = clamp(pos[i] / acc * 0.97, 0, 1)
    phi = phi + 137.508 + r.sym(15)
    local c, s_ = cos(phi * RAD), sin(phi * RAD)
    local m = max(1, floor(want * shares[i] / sum + 0.5))
    local rs = rb * sqrt(1.15 * m / 4)                     -- the cluster's sphere
    local R = max(0, R0 * shape(t) - rs + rb) * r.range(0.85, 1.1)
    local x0, y0, z0 = axis(t)
    -- the branch is stiff: about 2 mm thick, it stands out from the rachis at an angle from
    -- the straight down, nearly level at the shoulders (68 degrees) and steeper lower down (38),
    -- bowing only a little. Real ones are long: the first 4 to 5 cm, a third of the rachis
    local ang = lerp(68, 38, t) * RAD
    local drop = R / math.tan(ang)
    local mx, my, mz = x0 + c * 0.5 * R, y0 - 0.4 * drop, z0 + s_ * 0.5 * R
    local tx, ty, tz = x0 + c * R, y0 - drop, z0 + s_ * R
    stalk(x0, y0, z0, mx, my, mz, 2.0)
    stalk(mx, my, mz, tx, ty, tz, 1.5)
    -- its cluster about the tip, a little below it, each grape on its pedicel
    local cx, cy, cz = tx, ty - 0.45 * rs, tz
    for k = 1, m do
      local zz = 1 - 2 * (k - 0.5) / m
      local rr2 = sqrt(max(0, 1 - zz * zz))
      local a = k * 137.508 + r.sym(20)
      local ux, uy, uz = rr2 * cos(a * RAD), zz, rr2 * sin(a * RAD)
      local gx, gy, gz = cx + ux * rs * 0.9, cy + uy * rs * 1.2, cz + uz * rs * 0.9
      local px, py, pz = lerp(tx, gx, 0.45), lerp(ty, gy, 0.45) + 0.1 * rb, lerp(tz, gz, 0.45)
      stalk(tx, ty, tz, px, py, pz, 1.1)                -- the pedicel, about 1 mm thick
      stalk(px, py, pz, gx, gy, gz, 0.9)
      grape(gx, gy, gz, px, py, pz, c, s_, r.chance(0.04) and r.range(0.45, 0.6) or r.range(0.88, 1.08))
      -- it hangs from its pedicel: its long axis that way, and down
      local g = B[#B]
      local hx_, hy_, hz_ = gx - tx, gy - ty - 0.6 * rs, gz - tz
      local hl = sqrt(hx_ * hx_ + hy_ * hy_ + hz_ * hz_)
      if hl > 1e-9 then g.hx, g.hy = hx_ / hl, hy_ / hl end
    end
  end
  -- a compact bunch has no hollows between its clusters: its grapes are drawn out (or in)
  -- toward the outline's surface, a medium one part way, a loose one not at all
  local fill = ({ 0, 0.55, 0.7 })[sp.compact]
  if fill > 0 then
    for _, g in ipairs(B) do
      local tg = clamp((oy - g[2]) / H, 0, 1)
      local ax, _, az = axis(tg)
      local dx, dz = g[1] - ax, g[3] - az
      local d = sqrt(dx * dx + dz * dz)
      if d > 1e-6 then
        local k = lerp(d, max(0, R0 * shape(tg) - 0.3 * rb), fill) / d
        g[1], g[3] = ax + dx * k, az + dz * k
        g.ped[4], g.ped[6] = g[1], g[3]
      end
    end
  end
  return stalks
end
-- rb the grape's half width, want how many grapes the variety's bunch holds
-- v the variety's numbers: bloom, how thick its waxy bloom; alt and vary, a second color
-- its grapes may be any shade toward; spots, rusty flecks on its ripe grapes
local function bunch(r, sp, L, c, bl, lx, ripe, rb, want, v)
  local bloom, alt, vary, spots = v.bloom or 0.14, v.alt, v.vary or 0, v.spots
  local dark = sp.berrytone == "dark"
  local B = {}
  -- the peduncle, bare from the node to the first branch: 16 to 17 mm on a tight bunch of
  -- 8 to 12 cm (Shavrukov et al. 2004), a little under a fifth of it; 5 to 6 mm thick
  local ped = 0.18 * L * r.range(0.75, 1.35)
  local mm = 2 * rb / v.mm                       -- cm on the page for a real mm
  local stalks = {}
  local function add(list) for _, s_ in ipairs(list) do stalks[#stalks + 1] = s_ end end
  local tilt = r.sym(10)
  local main = panicle(r, sp, L, B, 0, -ped, 0, tilt, rb, want, mm)
  add(main)
  local arm = r.chance(0.5) and 1 or -1
  local wx, wy = arm * 0.22 * L, -ped * 0.55
  if sp.bunch == "winged" then
    add((panicle(r, sp, 0.45 * L, B, wx, wy - 0.05 * L, r.sym(0.1) * L, arm * r.range(15, 30), rb, floor(0.3 * want),
      mm)))
  end
  -- push apart grapes that collide, as they press in a tight bunch
  local press = ({ 1.0, 0.95, 0.9 })[sp.compact]
  for _ = 1, 5 do
    for i = 1, #B do
      local p = B[i]
      for j = i + 1, #B do
        local q = B[j]
        local dx, dy, dz = q[1] - p[1], q[2] - p[2], q[3] - p[3]
        local d, m = sqrt(dx * dx + dy * dy + dz * dz), press * (p[4] + q[4])
        if d < m and d > 1e-6 then
          local k = 0.5 * (m - d) / d
          p[1], p[2], p[3] = p[1] - dx * k, p[2] - dy * k, p[3] - dz * k
          q[1], q[2], q[3] = q[1] + dx * k, q[2] + dy * k, q[3] + dz * k
        end
      end
    end
  end
  -- the stalks: the peduncle from the node, the wing's arm, then the bunch's own
  local sc = mix(C.shoot, C.cane, 0.45)
  local BP = mm * 28.3465                        -- bp on the page for a real mm
  ink.moveto(0, 0) ink.curveto(r.sym(0.03) * L, -0.3 * ped, 0, -0.65 * ped, 0, -ped) ink.stroke(sc, 5.5 * BP, 1)
  if sp.bunch == "winged" then
    ink.moveto(0, -0.55 * ped) ink.lineto(wx, wy - 0.05 * L) ink.stroke(sc, 3 * BP, 1)
  end
  table.sort(stalks, function(a, b) return a[3] + a[6] < b[3] + b[6] end)
  for _, s_ in ipairs(stalks) do
    if not s_.gone then ink.moveto(s_[1], s_[2]) ink.lineto(s_[4], s_[5]) ink.stroke(sc, s_[7], 0.95) end
  end
  -- the grapes, the furthest first. Each is its skin, darker the further back and the lower
  -- in the bunch's shade it hangs; then its bloom, the powdery wax over it, thicker on some
  -- grapes than others and palest at the rim, where the skin is seen edge on; where the
  -- bloom is rubbed off, a patch of glossy skin with its own small sharp highlight, and
  -- elsewhere the soft broad highlight that the wax scatters
  local zmin, zmax = math.huge, -math.huge
  local ytop, ybot = -math.huge, math.huge
  for _, p in ipairs(B) do
    zmin, zmax = min(zmin, p[3]), max(zmax, p[3])
    ytop, ybot = max(ytop, p[2]), min(ybot, p[2])
  end
  table.sort(B, function(a, b) return a[3] < b[3] end)
  local asp = ({ round = 1, oval = 1.16, long = 1.42 })[sp.berryshape]
  -- occlusion: a grape lies under the grapes painted after it, each taken as a circle a
  -- little smaller than it is. Points around and inside a circle a little larger than the
  -- grape are tested, and one wholly under them is not drawn at all. Each grape draws from a
  -- stream of its own, so those drawn look as they would with nothing left out
  for i, p in ipairs(B) do
    p.gr = r.fork()
    local R, hit, n = p[4] * asp * 1.05, 0, 0
    local function test(x, y)
      n = n + 1
      for j = i + 1, #B do
        local q = B[j]
        local rq = 0.9 * q[4]
        if (x - q[1]) ^ 2 + (y - q[2]) ^ 2 < rq * rq then hit = hit + 1 return end
      end
    end
    test(p[1], p[2])
    for s = 1, 24 do test(p[1] + R * cos(s * pi / 12), p[2] + R * sin(s * pi / 12)) end
    for s = 1, 8 do test(p[1] + 0.55 * R * cos(s * pi / 4), p[2] + 0.55 * R * sin(s * pi / 4)) end
    p.cover = hit / n
  end
  for _, p in ipairs(B) do
    if p.cover >= 1 then goto hidden end
    local gr = p.gr
    local d = (p[3] - zmin) / max(1e-6, zmax - zmin)
    local rr = p[4]
    local own = p.shot and 0 or clamp((ripe - 0.6 * p.turn) / 0.4 + (ripe >= 1 and 1 or 0), 0, 1)
    local col
    if sp.berrytone == "pale" then col = mix(C.unripe, c, own)
    elseif own < 0.5 then col = mix(C.unripe, C.blush, 2 * own)
    else col = mix(C.blush, c, 2 * own - 1) end
    -- grapes of one bunch differ in shade (gewurztraminer's from gold to red-brown)
    if alt then col = mix(col, mix(C.unripe, alt, own), vary * p.tint) end
    local low = (ytop - p[2]) / max(1e-6, ytop - ybot)
    local k = (0.55 + 0.45 * d) * (1 - 0.2 * low)
    -- its length along the way it hangs, foreshortened as that way turns toward the reader
    local fs = sqrt(p.hx * p.hx + p.hy * p.hy)
    local ca, sa = p.hx / max(fs, 1e-6), p.hy / max(fs, 1e-6)
    local long = rr * (1 + (asp - 1) * fs)
    local hx, hy, wx2, wy2 = long * ca, long * sa, -rr * sa, rr * ca
    local function oval(x, y, f)
      local kk = 0.55228475
      local ax, ay, bx, by = f * hx, f * hy, f * wx2, f * wy2
      ink.moveto(x + ax, y + ay)
      ink.curveto(x + ax + kk * bx, y + ay + kk * by, x + bx + kk * ax, y + by + kk * ay, x + bx, y + by)
      ink.curveto(x + bx - kk * ax, y + by - kk * ay, x - ax + kk * bx, y - ay + kk * by, x - ax, y - ay)
      ink.curveto(x - ax - kk * bx, y - ay - kk * by, x - bx - kk * ax, y - by - kk * ay, x - bx, y - by)
      ink.curveto(x - bx + kk * ax, y - by + kk * ay, x + ax - kk * bx, y + ay - kk * by, x + ax, y + ay)
      ink.close()
    end
    oval(p[1], p[2], 1) ink.fill(scale(col, k))
    oval(p[1] + 0.12 * rr * lx, p[2] - 0.1 * rr, 0.82) ink.fill(scale(col, min(1.2, k * 1.1)), 0.45)
    local bc, wax = mix(C.unripe, bl, own), bloom * (0.45 + 1.1 * p.thick) * own
    local rubbed = wax > 0.12 and p.rub < 0.4
    if wax > 0.06 then
      -- the bloom is a powder, not a film: clipped to the grape, three irregular drifts of it
      -- overlapping, thicker where they cross; on a rubbed grape they lie off to one side,
      -- leaving the skin bare along the other
      oval(p[1], p[2], 1) ink.clip()
      local ra = p.rubat * RAD
      local ox_, oy_ = rubbed and -0.3 * rr * cos(ra) or 0, rubbed and -0.3 * rr * sin(ra) or 0
      for _ = 1, 3 do
        ink.smooth(ink.blob(gr, p[1] + ox_ + gr.sym(0.35) * rr, p[2] + oy_ + gr.sym(0.35) * rr,
          rr * gr.range(0.6, 1.0), long * gr.range(0.6, 1.0), 0.35, 9), true)
        ink.fill(bc, 0.5 * wax)
      end
      ink.unclip()
      -- palest at the rim, fading inward
      oval(p[1], p[2], 0.95) ink.stroke(bc, 0.9, min(0.18, 0.35 * wax))
      oval(p[1], p[2], 0.97) ink.stroke(bc, 0.4, min(0.28, 0.5 * wax))
    end
    if dark then
      -- a dark grape has no hard glint: a soft sheen, discs fading outward, in a pale tint of
      -- its bloom
      local sc2 = mix(bc, ink.white, 0.45)
      local hx2, hy2 = p[1] - 0.3 * rr * lx, p[2] + 0.3 * rr
      for _, f in ipairs({ 0.42, 0.3, 0.18 }) do ink.circle(hx2, hy2, f * rr) ink.fill(sc2, 0.09 * k) end
    elseif rubbed then
      local ra = p.rubat * RAD
      ink.circle(p[1] + 0.55 * rr * cos(ra), p[2] + 0.55 * rr * sin(ra), 0.07 * rr) ink.fill(ink.white, 0.35)
    elseif wax > 0.12 then
      ink.circle(p[1] - 0.3 * rr * lx, p[2] + 0.3 * rr, 0.38 * rr) ink.fill(ink.white, 0.16 * k)
    else
      ink.circle(p[1] - 0.36 * rr * lx, p[2] + 0.36 * rr, 0.15 * rr) ink.fill(ink.white, 0.65 * k)
    end
    if spots and own > 0.8 and p.tint > 0.4 then           -- rusty flecks on a ripe white grape
      local a = p.tint * 2 * pi * 7
      ink.circle(p[1] + 0.45 * rr * cos(a), p[2] - 0.3 * rr * sin(a), 0.07 * rr)
      ink.circle(p[1] - 0.2 * rr * sin(a), p[2] - 0.5 * rr * cos(a), 0.05 * rr)
      ink.fill({ 0.55, 0.32, 0.18 }, 0.7)
    end
    oval(p[1], p[2], 1) ink.stroke(scale(col, dark and 0.7 or 0.42), 0.18, dark and 0.4 or 0.8)
    ::hidden::
  end
  return #B
end

-- ---------------------------------------------------------------- the tendril
-- along +x from the origin, L long: it forks, and each arm ends in a coil
local function tendril(r, L, c)
  local function arm(x, y, a, len, w)
    local pts, hand = { { x, y } }, r.chance(0.5) and 1 or -1
    local n = 10
    for _ = 1, n do
      a = a + hand * r.range(2, 6)
      x, y = x + len * 0.55 / n * cos(a * RAD), y + len * 0.55 / n * sin(a * RAD)
      pts[#pts + 1] = { x, y }
    end
    local rad0, turns = len * r.range(0.09, 0.14), r.range(1.4, 2.6)
    local m = floor(turns * 18)
    for i = 1, m do
      a = a + hand * 360 / 18
      local rr = rad0 * (1 - 0.7 * i / m)
      x, y = x + 2 * pi * rr / 18 * cos(a * RAD), y + 2 * pi * rr / 18 * sin(a * RAD)
      pts[#pts + 1] = { x, y }
    end
    ink.smooth(pts, false) ink.stroke(c, w, 1)
  end
  local fx, fy = 0.4 * L, r.sym(0.05) * L
  ink.moveto(0, 0) ink.curveto(0.15 * L, 0.02 * L, 0.3 * L, fy, fx, fy) ink.stroke(c, 0.45, 1)
  arm(fx, fy, r.range(15, 35), 0.65 * L, 0.32)
  arm(fx, fy, -r.range(15, 35), 0.5 * L, 0.28)
end

-- ---------------------------------------------------------------- wood
-- a trunk or an arm along pts, w0 wide at its start to w1 at its end (cm): a band of bark
-- with long strips of it, lighter and darker, twisting round
local function wood(r, pts, w0, w1)
  local n = #pts
  local s, total = ink.arclen(pts)
  local L, R = {}, {}
  for i = 1, n do
    local a, b = pts[max(1, i - 1)], pts[min(n, i + 1)]
    local tx, ty = b[1] - a[1], b[2] - a[2]
    local l = max(1e-9, sqrt(tx * tx + ty * ty))
    local nx, ny = -ty / l, tx / l
    local w = lerp(w0, w1, s[i] / total) / 2 * (1 + 0.12 * sin(s[i] * 9 + i))
    L[i] = { pts[i][1] + nx * w, pts[i][2] + ny * w, nx, ny, w }
    R[i] = { pts[i][1] - nx * w, pts[i][2] - ny * w }
  end
  local band = {}
  for i = 1, n do band[#band + 1] = { L[i][1], L[i][2] } end
  for i = n, 1, -1 do band[#band + 1] = { R[i][1], R[i][2] } end
  ink.smooth(band, true) ink.fill(C.bark)
  for k = 1, 14 do
    local f0, tw, ph = r.sym(0.85), r.range(1.2, 3.8), r.range(0, 2 * pi)
    local strip = {}
    for i = 1, n do
      local f = clamp(f0 + 0.45 * sin(s[i] * tw + ph), -0.88, 0.88)
      strip[#strip + 1] = { pts[i][1] + L[i][3] * L[i][5] * f, pts[i][2] + L[i][4] * L[i][5] * f }
    end
    ink.smooth(strip, false)
    if k % 2 == 0 then ink.stroke(C.barklight, r.range(0.3, 0.6), 0.55) else ink.stroke(C.barkdark, r.range(0.35, 0.8), 0.7) end
  end
  ink.smooth(band, true) ink.stroke(C.barkdark, 0.35, 0.8)
end
-- a band along pts, w0 wide at its start to w1 at its end (cm), filled with c, lit along its
-- left side and shaded along its right, as a round stem is; returns its sides
local function band(pts, w0, w1, c)
  local n = #pts
  local s, total = ink.arclen(pts)
  local L, R, M_ = {}, {}, {}
  for i = 1, n do
    local a, b = pts[max(1, i - 1)], pts[min(n, i + 1)]
    local tx, ty = b[1] - a[1], b[2] - a[2]
    local l = max(1e-9, sqrt(tx * tx + ty * ty))
    local w = lerp(w0, w1, s[i] / max(total, 1e-9)) / 2
    L[i] = { pts[i][1] - ty / l * w, pts[i][2] + tx / l * w }
    R[i] = { pts[i][1] + ty / l * w, pts[i][2] - tx / l * w }
    M_[i] = { pts[i][1] - ty / l * w * 0.45, pts[i][2] + tx / l * w * 0.45 }
  end
  local shape = {}
  for i = 1, n do shape[#shape + 1] = L[i] end
  for i = n, 1, -1 do shape[#shape + 1] = R[i] end
  ink.smooth(shape, true) ink.fill(c)
  local sh = {}
  for i = 1, n do sh[#sh + 1] = R[i] end
  for i = n, 1, -1 do sh[#sh + 1] = { lerp(R[i][1], pts[i][1], 0.7), lerp(R[i][2], pts[i][2], 0.7) } end
  ink.smooth(sh, true) ink.fill(scale(c, 0.72), 0.7)
  ink.smooth(M_, false) ink.stroke(mix(c, { 1, 1, 1 }, 0.35), 0.35, 0.6)
  ink.smooth(shape, true) ink.stroke(scale(c, 0.5), 0.25, 0.8)
  return L, R, s, total
end
local function braid(r, pts, S)
  local n = #pts
  local s, total = ink.arclen(pts)
  local function at(d)
    local i = 1
    while i < n - 1 and s[i + 1] < d do i = i + 1 end
    local t = clamp((d - s[i]) / max(1e-9, s[i + 1] - s[i]), 0, 1)
    local tx, ty = pts[i + 1][1] - pts[i][1], pts[i + 1][2] - pts[i][2]
    local l = max(1e-9, sqrt(tx * tx + ty * ty))
    return lerp(pts[i][1], pts[i + 1][1], t), lerp(pts[i][2], pts[i + 1][2], t), -ty / l, tx / l
  end
  local canes = {}
  local L = BRAID_LOOSENESS
  for k = 1, floor(r.range(lerp(6, 2, L), lerp(8, 4, L))) do
    local w = r.range(1.8, 4.2) * S
    local base = r.sym(lerp(1.5, 5, L) * S)
    local A = r.range(1, 2.5) * lerp(1, 2, L) * S
    local P, ph, bias = r.range(30, 60) * S, r.range(0, 2 * pi), r.sym(0.3)
    local nodes, d = {}, 0
    while true do
      local x, y, nx, ny = at(d)
      local o = base + A * sin(ph) + r.sym(0.5 * S)
      nodes[#nodes + 1] = { x + nx * o, y + ny * o, w * r.range(0.8, 1.15), clamp(cos(ph) + bias, -1, 1), o }
      if d >= total then break end
      local ds = r.range(4, 9) * S
      d = min(total, d + ds)
      ph = ph + 2 * pi * ds / P * r.range(0.6, 1.4)
    end
    canes[k] = { nodes = nodes, z = bias }
  end
  table.sort(canes, function(a, b) return a.z < b.z end)
  return canes
end
local function drawbraid(r, canes)
  local function side(nodes, i0, i1, k, pad)
    local out = {}
    for i = i0, i1 do
      local p, a, b = nodes[i], nodes[max(1, i - 1)], nodes[min(#nodes, i + 1)]
      local tx, ty = b[1] - a[1], b[2] - a[2]
      local l = max(1e-9, sqrt(tx * tx + ty * ty))
      local o = k * p[3] / 2 + (pad or 0) * k
      out[#out + 1] = { p[1] - ty / l * o, p[2] + tx / l * o }
    end
    return out
  end
  local function run(cn, i0, i1)
    local nodes = cn.nodes
    local L, R = side(nodes, i0, i1, 1), side(nodes, i0, i1, -1)
    local shape = {}
    for i = 1, #L do shape[#shape + 1] = L[i] end
    for i = #R, 1, -1 do shape[#shape + 1] = R[i] end
    ink.poly(shape, true) ink.fill(C.bark)
    for k, st in ipairs(cn.strips) do
      local strip = {}
      for i = i0, i1 do
        local p, a, b = nodes[i], nodes[max(1, i - 1)], nodes[min(#nodes, i + 1)]
        local tx, ty = b[1] - a[1], b[2] - a[2]
        local l = max(1e-9, sqrt(tx * tx + ty * ty))
        local o = clamp(st[1] + 0.45 * sin(cn.s[i] * st[2] + st[3]), -0.88, 0.88) * p[3] / 2
        strip[#strip + 1] = { p[1] - ty / l * o, p[2] + tx / l * o }
      end
      ink.smooth(strip, false)
      if k % 2 == 0 then ink.stroke(C.barklight, st[4], 0.55) else ink.stroke(C.barkdark, st[4], 0.7) end
    end
    ink.poly(L, false) ink.poly(R, false) ink.stroke(C.barkdark, 0.35, 0.8)
  end
  for _, cn in ipairs(canes) do
    cn.s = ink.arclen(cn.nodes)
    cn.strips = {}
    for k = 1, 6 do
      cn.strips[k] = { r.sym(0.85), r.range(1.2, 3.8), r.range(0, 2 * pi), k % 2 == 0 and r.range(0.3, 0.6) or r.range(0.35, 0.8) }
    end
    run(cn, 1, #cn.nodes)
  end
  local function at(cn, x, k)
    local nd = cn.nodes
    for j = 1, #nd - 1 do
      if nd[j][1] <= x and nd[j + 1][1] >= x then
        return lerp(nd[j][k], nd[j + 1][k], (x - nd[j][1]) / max(1e-9, nd[j + 1][1] - nd[j][1]))
      end
    end
  end
  local function outline(nd, i0, i1)
    local L, R = side(nd, i0, i1, 1, 0.012), side(nd, i0, i1, -1, 0.012)
    for i = #R, 1, -1 do L[#L + 1] = R[i] end
    return L
  end
  local function span(nd, lo, hi)
    local i0, i1 = 1, #nd
    while i0 < #nd and nd[i0 + 1][1] < lo do i0 = i0 + 1 end
    while i1 > 1 and nd[i1 - 1][1] > hi do i1 = i1 - 1 end
    return i0, i1
  end
  for ia = 1, #canes - 1 do
    local A = canes[ia]
    for ib = ia + 1, #canes do
      local B = canes[ib].nodes
      local function over(j)
        local p, q = B[j], B[j + 1]
        local xm = (p[1] + q[1]) / 2
        local y, w = at(A, xm, 2), at(A, xm, 3)
        return y and abs(y - (p[2] + q[2]) / 2) < (w + (p[3] + q[3]) / 2) / 2
      end
      local i = 1
      while i < #B do
        if over(i) then
          local j, dz = i, 0
          while j < #B and over(j) do
            dz = dz + at(A, (B[j][1] + B[j + 1][1]) / 2, 4) - (B[j][4] + B[j + 1][4]) / 2
            j = j + 1
          end
          if dz > 0 then
            local lo, hi = B[i][1], B[j][1]
            ink.poly(outline(B, i, j), true) ink.clip()
            for ic = ib + 1, #canes do
              ink.poly({ { lo - 1, -50 }, { hi + 1, -50 }, { hi + 1, 50 }, { lo - 1, 50 } }, true)
              ink.poly(outline(canes[ic].nodes, span(canes[ic].nodes, lo, hi)), true)
              ink.clip(true)
            end
            run(A, span(A.nodes, lo, hi))
            for _ = ib, #canes do ink.unclip() end
          end
          i = j
        else
          i = i + 1
        end
      end
    end
  end
end

-- ---------------------------------------------------------------- the page
-- The vine as a vineyard trains it, spur-pruned on a vertical shoot positioned trellis, seen
-- from the side of the row, the margin's column its panel:
--   - the trunk rises from the ground to the fruiting wire, a third of the way up, and
--     divides into the cordon, two permanent arms laid along the wire, barked and knobbed;
--   - along the cordon, every hand's breadth, a spur: a stub of last year's cane cut back to
--     two buds, its cut end showing, older dead stubs beside it;
--   - from each bud a shoot (a cane once it ripens to brown in autumn), trained straight up
--     between the catch wires, thick at its base, its nodes swollen; hedged flat at the top,
--     where some lean over;
--   - at every node a leaf, alternately left and right, held at a depth of its own so the
--     canopy overlaps, the dormant bud in its axil, and now and then a short lateral shoot;
--   - in the fruit zone just above the cordon, the bunches hang from the third, fourth and
--     fifth nodes, and most leaves there are plucked to let the light and air at them; higher,
--     tendrils opposite the leaves, gripping the catch wires where they reach one;
--   - in spring the shoots are short, in autumn canes with turned leaves.
-- g: the page (florilegium-grapes.lua's geometry, in cm), its seed, docseed, age and variety
function M.page(g)
  local rng = ink.rng(g.seed * 7919 + 811)
  local layout = rng.fork()
  ink.set_transform(ink.page_transform(g.mirror and g.pw))
  local lx = g.mirror and -1 or 1                -- the light's side in layout x: the page's upper left
  local sp = vine(g.vine or "pinot", g.docseed or 0)
  local v = VAR[sp.variety]
  local age = g.age or 0.8                        -- without a season, late summer: ripe grapes
  local ripe = clamp((age - 0.55) / 0.25, 0, 1)   -- green, then veraison, then ripe
  local fall = clamp((age - 0.8) / 0.18, 0, 1)    -- the leaves turn
  local wooded = clamp((age - 0.62) / 0.3, 0, 1)  -- the shoots ripen to canes
  local grown = clamp(0.25 + 1.5 * age, 0.25, 1)  -- how far the shoots have grown
  local white = sp.berrytone == "pale" or v.white
  -- the margin's column, from the paper's edge to the text, from the foot of the page to its top
  local col = { 0.3, 0.45, g.colright, g.ph - 0.5 }
  local x0, x1 = col[1] + 0.15, col[3] - 0.1
  local yg, yt = col[2] + 0.05, col[4] - 0.35
  local cw, H = x1 - x0, yt - yg
  local size = clamp(cw / 5.5, 0.75, 1.15)
  local S = 1.2 * size / 11                       -- cm on the page for a real cm: a leaf's midrib is 11 cm
  local counts = { shoot = 0, leaf = 0, bunch = 0, tendril = 0, grape = 0 }

  local function place(layer, x, y, a, fn)
    ink.layer(layer)
    ink.push() ink.translate(x, y) ink.rotate(a) fn() ink.pop()
  end
  -- depth: the canopy's things are layered by how near they are, -1 behind to 1 in front;
  -- the wood and the shoots sit in the middle
  local function layer(z) return 10 + floor((clamp(z, -1, 1) + 1) * 20) end
  local MID = layer(0)

  local items, wires, hung = {}, {}, {}
  local shootc = mix(C.shoot, C.cane, wooded)
  -- a shoot along pts, w0 thick at its base (a real one is about 1 cm): at its nodes, a leaf at
  -- each, alternately left and right, its bud in the axil; bunches low, tendrils higher, now
  -- and then a lateral
  local function shoot(pts, w0, plucked)
    counts.shoot = counts.shoot + 1
    items[#items + 1] = { kind = "shoot", pts = pts, z = 0, w0 = w0 }
    local ss, tot = ink.arclen(pts)
    local nat, node, side, j = layout.range(0.15, 0.25) * size, 0, layout.chance(0.5) and 1 or -1, 1
    local nodes = {}
    while nat < tot - 0.1 do
      nodes[#nodes + 1] = nat
      nat = nat + layout.range(1.0, 1.35) * size
    end
    local function yat(a)
      local i = 1
      while i < #pts and ss[i] < a do i = i + 1 end
      return pts[i][2]
    end
    local fruit, near = {}, {}
    for _, h in ipairs(hung) do near[#near + 1] = h end
    for _ = 1, layout.chance(0.55) and 2 or 1 do
      local ws, sum, last = {}, 0, min(5, #nodes)
      for n = 3, last do
        local w = fruit[n] and 0 or 1
        local y = yat(nodes[n])
        for _, h in ipairs(near) do w = w * (1 - math.exp(-((y - h) / (0.6 * size)) ^ 2)) end
        ws[n], sum = w, sum + w
      end
      if sum <= 0 then break end
      local pick, n = layout.u() * (sum + 0.1), 3
      if pick >= sum then break end
      while n < last and pick > ws[n] do pick, n = pick - ws[n], n + 1 end
      if fruit[n] then break end
      fruit[n] = true
      near[#near + 1] = yat(nodes[n])
    end
    for _, at in ipairs(nodes) do
      nat = at
      while j < #pts and ss[j] < nat do j = j + 1 end
      local p, pa_, pb = pts[j], pts[max(1, j - 1)], pts[min(#pts, j + 1)]
      local ta = deg(pb[1] - pa_[1], pb[2] - pa_[2])
      node, side = node + 1, -side
      local zone = plucked and plucked(p[2])
      local u = nat / tot
      items[#items + 1] = { kind = "node", p = p, ta = ta, side = side, z = 0.02 }
      if not zone then                                  -- the fruit zone's leaves are plucked
        -- the oldest leaves, low on the cane, are the largest, fully grown; they shrink
        -- toward the young tip, and the first one or two are a little small
        local L = 1.2 * size * v.leaf * (node <= 2 and 0.8 or 1) * (1.25 - 0.75 * u ^ 1.1)
          * layout.range(0.88, 1.08)
        local pa = ta - side * layout.range(55, 85)
        local px, py = dir(pa)
        local bx2, by2 = 0.55 * px, 0.55 * py - 0.6
        local bl = sqrt(bx2 * bx2 + by2 * by2)
        local pl = layout.range(0.75, 1.05) * L
        items[#items + 1] = { kind = "leaf", node = p, j = { p[1] + pl * px, p[2] + pl * py },
          axis = deg(bx2 / bl, by2 / bl) + layout.sym(18), L = L, z = layout.sym(1),
          turn = fall * (layout.u() < 0.75 and 1 or 0.35) * layout.range(0.5, 1), tint = layout.sym(1),
          young = clamp((u - 0.6) / 0.4, 0, 1), old = clamp(1.15 - u / 0.7, 0, 1) }
      end
      local oa = ta + side * layout.range(40, 65)
      if fruit[node] and age >= 0.3 then
        -- the bunch at its real size, on the leaf's scale (a midrib about 11 cm long)
        local young = age < 0.45
        local Lb = FRUIT * v.cm * S * layout.range(0.85, 1.1) * (young and 0.5 or 1)
        local ox, oy = dir(oa)
        local tx, ty = p[1] + 0.18 * ox, p[2] + 0.18 * oy
        -- thinned, as a grower thins them, where it would crowd one already hanging
        local crowded = false
        for _, o in ipairs(items) do
          if o.kind == "bunch" and abs(o.t[1] - tx) < 0.2 * (o.L + Lb)
            and min(o.t[2], ty) - max(o.t[2] - o.L, ty - Lb) > 0.3 * min(o.L, Lb) then crowded = true break end
        end
        if not crowded then
          hung[#hung + 1] = p[2]
          items[#items + 1] = { kind = "bunch", node = p, t = { tx, ty }, L = Lb, z = layout.range(-0.5, 0.9),
            rb = FRUIT * v.mm / 20 * S * (young and 0.6 or 1) }
        end
      elseif node >= 6 and (node - 6) % 3 < 2 then
        local wy
        for _, w in ipairs(wires) do if abs(w - p[2]) < 0.55 * size then wy = w end end
        items[#items + 1] = { kind = "tendril", node = p, a = oa, L = layout.range(0.7, 1.1) * size, wire = wy,
          z = layout.sym(0.6) }
      end
      if node >= 4 and not zone and layout.chance(0.18) then  -- a lateral from the axil
        local la = ta - side * layout.range(30, 45)
        local ll = layout.range(0.6, 1.1) * size
        local lp = { { p[1], p[2] } }
        for k = 1, 6 do
          lp[#lp + 1] = { p[1] + ll * k / 6 * cos((la + side * 4 * k) * RAD), p[2] + ll * k / 6 * sin((la + side * 4 * k) * RAD) }
        end
        items[#items + 1] = { kind = "shoot", pts = lp, z = layout.sym(0.5), w0 = 0.05 * size }
        for k = 1, 2 do
          local q2 = lp[2 + 2 * k]
          local pa2 = la + (k == 1 and side or -side) * 60
          local px2, py2 = dir(pa2)
          local L2 = 0.55 * size * v.leaf * layout.range(0.85, 1.1)
          items[#items + 1] = { kind = "leaf", node = q2, j = { q2[1] + 0.8 * L2 * px2, q2[2] + 0.8 * L2 * py2 },
            axis = pa2 - 20 * (pa2 > 90 and -1 or 1), L = L2, z = layout.sym(1), turn = fall * layout.u(), tint = layout.sym(1),
            young = 0.7 }
        end
      end
    end
  end

  local train = {}
  function train.spur()
    local yc = yg + 0.3 * H                         -- the fruiting wire
    wires = { yc + 0.3 * (yt - yc), yc + 0.58 * (yt - yc), yc + 0.84 * (yt - yc) }
    local function plucked(y) return y < yc + 0.22 * (yt - yc) end
    -- 1. the trunk and the cordon
    local xt = x0 + cw * layout.range(0.38, 0.52)
    local trunk = {}
    local ph = layout.range(0, 360)
    for i = 0, 16 do
      local t = i / 16
      trunk[#trunk + 1] = { xt + 0.25 * size * sin((t * 300 + ph) * RAD) + layout.sym(0.05), lerp(yg, yc - 0.3, t) }
    end
    local top = trunk[#trunk]
    local arms = {}
    for _, side in ipairs({ -1, 1 }) do
      local reach = side < 0 and top[1] - x0 - 0.1 or x1 - top[1] - 0.1
      if reach > 0.8 then
        -- from inside the head, curving out and up onto the wire, then along it, knuckled
        local y0 = top[2] - 0.55 * size
        local pts = { { top[1] - side * 0.1 * size, y0 } }
        local sag = layout.range(0.03, 0.1)
        for i = 1, 18 do
          local t = i / 18
          local u = min(1, t * 2.6)
          pts[#pts + 1] = { top[1] + side * reach * t, lerp(y0, yc, 1 - (1 - u) ^ 2.2) - sag * sin(t * 180 * RAD)
            + 0.05 * size * sin((t * 900 + ph) * RAD) }
        end
        arms[#arms + 1] = { pts = pts, side = side }
      end
    end
    local tw = 1.1 * size
    place(MID - 2, 0, 0, 0, function()
      local r = rng.fork()
      for _, arm in ipairs(arms) do wood(r, arm.pts, 0.8 * size, 0.38 * size) end
      wood(r, trunk, tw, 0.95 * size)
    end)
    -- the wires, the fruiting wire under the cordon and the catch wires above it
    place(MID + 1, 0, 0, 0, function()
      for _, y in ipairs({ yc - 0.08, wires[1], wires[2], wires[3] }) do
        ink.moveto(col[1] - 0.3, y) ink.lineto(col[3] - 0.05, y + 0.01)
      end
      ink.stroke({ 0.52, 0.53, 0.55 }, 0.4, 0.85)
    end)

    -- 2. the spurs, and from each bud a shoot
    for _, arm in ipairs(arms) do
      local s, total = ink.arclen(arm.pts)
      local at, i = layout.range(0.9, 1.4) * size, 1
      while at < total - 0.15 do
        while i < #arm.pts and s[i] < at do i = i + 1 end
        local q = arm.pts[i]
        local sa = 90 + layout.sym(35)
        local sl = layout.range(0.5, 0.8) * size
        local ex, ey = q[1] + sl * cos(sa * RAD), q[2] + sl * sin(sa * RAD)
        local stub = layout.chance(0.5) and layout.sym(1) or nil
        items[#items + 1] = { kind = "spur", q = q, e = { ex, ey }, a = sa, stub = stub, z = 0 }
        -- the spur's two buds: a shoot from each (now and then one is blind)
        for b = 1, 2 do
          if b == 1 or layout.chance(0.85) then
            local f = b == 1 and 0.45 or 0.92
            local bx, by = lerp(q[1], ex, f), lerp(q[2], ey, f)
            local lean = layout.sym(3) + (b == 1 and 7 or -7) * (cos(sa * RAD) >= 0 and 1 or -1)
            local hedge = yt + layout.range(-0.3, 0.25)
            local flop = layout.chance(0.3)
            local pts, x, y, a = { { bx, by } }, bx, by, 90 + lean
            local target = (hedge - by) * grown
            local len, sway = 0, layout.range(0, 360)
            while len < target do
              a = 90 + lean + 4 * sin((len * 60 + sway) * RAD)
              x, y = x + 0.12 * cos(a * RAD), y + 0.12 * sin(a * RAD)
              len = len + 0.12
              pts[#pts + 1] = { clamp(x, col[1] - 0.1, col[3] + 0.1), y }
            end
            if flop and grown >= 1 then                     -- over the top wire and down
              local fa, side = a, layout.chance(0.5) and 1 or -1
              for _ = 1, floor(layout.range(6, 12)) do
                fa = fa + side * 14
                x, y = x + 0.12 * cos(fa * RAD), y + 0.12 * sin(fa * RAD)
                pts[#pts + 1] = { x, y }
              end
            end
            shoot(pts, (b == 1 and 1.05 or 0.95) * S, plucked)
          end
        end
        at = at + layout.range(2.2, 2.9) * size
      end
    end
  end
  function train.trenzado()
    local yb = yg + layout.range(25, 40) * S
    local function plucked(y) return y < yb + 0.12 * (yt - yb) end
    local D = layout.range(40, 65) * S
    local p0 = col[1] - layout.range(0, D)
    local tilt, sag = layout.sym(0.04), layout.range(4, 9) * S
    local function by(x)
      local f = (x - p0) / D
      return yb + tilt * (x - x0) - sag * sin(pi * (f - floor(f)))
    end
    local pts = {}
    for i = 0, 60 do
      local x = lerp(col[1] - 0.6, col[3] + 0.6, i / 60)
      pts[#pts + 1] = { x, by(x) }
    end
    local canes = braid(layout.fork(), pts, S)
    local poles = {}
    for px = p0, col[3] + 0.3, D do
      if px > col[1] - 0.3 then poles[#poles + 1] = { px, by(px) + layout.range(15, 40) * S, layout.sym(0.04) } end
    end
    place(MID, 0, 0, 0, function()
      for _, p in ipairs(poles) do
        local w, c, tx = 0.6 * S, { 0.4, 0.31, 0.26 }, p[1] + p[3] * (p[2] - yg)
        local rod = { { p[1] - w, yg - 0.4 }, { tx - w, p[2] }, { tx + w, p[2] }, { p[1] + w, yg - 0.4 } }
        ink.poly(rod, true) ink.fill(c)
        ink.moveto(p[1] - 0.4 * w, yg - 0.4) ink.lineto(tx - 0.4 * w, p[2]) ink.stroke(mix(c, { 1, 1, 1 }, 0.35), 0.3, 0.7)
        ink.poly(rod, true) ink.stroke(C.barkdark, 0.25, 0.85)
      end
    end)
    place(MID + 1, 0, 0, 0, function()
      drawbraid(rng.fork(), canes)
      for _, p in ipairs(poles) do
        local x, lo, hi = p[1], 1e9, -1e9
        for _, cn in ipairs(canes) do
          local nd = cn.nodes
          for j = 1, #nd - 1 do
            if nd[j][1] <= x and nd[j + 1][1] >= x then
              local t = (x - nd[j][1]) / max(1e-9, nd[j + 1][1] - nd[j][1])
              local y, h = lerp(nd[j][2], nd[j + 1][2], t), lerp(nd[j][3], nd[j + 1][3], t) / 2
              lo, hi = min(lo, y - h), max(hi, y + h)
            end
          end
        end
        for k = 0, 1 do
          local ax, bx = x - 0.9 * S + k * 0.9 * S, x + 0.3 * S + k * 0.9 * S
          ink.moveto(ax, hi + 0.2 * S)
          ink.curveto(ax + 0.8 * S, lerp(hi, lo, 0.3), bx + 0.8 * S, lerp(hi, lo, 0.7), bx, lo - 0.2 * S)
          ink.stroke({ 0.42, 0.36, 0.26 }, 1.4, 1)
          ink.moveto(ax, hi + 0.2 * S)
          ink.curveto(ax + 0.8 * S, lerp(hi, lo, 0.3), bx + 0.8 * S, lerp(hi, lo, 0.7), bx, lo - 0.2 * S)
          ink.stroke({ 0.85, 0.78, 0.6 }, 0.8, 1)
        end
      end
    end)
    local buds = {}
    for _, cn in ipairs(canes) do
      for _, nd in ipairs(cn.nodes) do
        if nd[1] > x0 and nd[1] < x1 and nd[4] > -0.2 then
          buds[#buds + 1] = { nd[1], nd[2] + 0.3 * nd[3] }
        end
      end
    end
    table.sort(buds, function(a, b) return a[1] < b[1] end)
    local last, xm = -1e9, (x0 + x1) / 2
    for _, b in ipairs(buds) do
      if b[1] - last > layout.range(0.7, 1.0) * size then
        last = b[1]
        local lean = clamp((b[1] - xm) / cw * 40, -20, 20) + layout.sym(10)
        local a0, turn = 90 - lean, lean > 0 and 1 or -1
        local arc, target = layout.range(10, 70), (yt - yb) * grown * layout.range(0.75, 1.1)
        local sx, sy = b[1], b[2]
        local spts, len = { { sx, sy } }, 0
        while len < target and sx > col[1] - 0.3 and sx < col[3] + 0.3 do
          local a = a0 - turn * arc * (len / target) ^ 2
          sx, sy = sx + 0.12 * cos(a * RAD), max(yg + 0.3, sy + 0.12 * sin(a * RAD))
          len = len + 0.12
          spts[#spts + 1] = { sx, sy }
        end
        shoot(spts, layout.range(0.9, 1.05) * S, plucked)
      end
    end
  end
  local training = train[g.pruning or "spur"]
  if not training then error("florilegium-grapes: pruning=" .. tostring(g.pruning) .. "? one of spur, trenzado", 0) end
  training()

  -- summer pruning: a leaf whose blade hangs over a bunch is pulled, stalk and all
  local kept = {}
  for _, it in ipairs(items) do
    local pulled = false
    if it.kind == "leaf" then
      local ax, ay = dir(it.axis)
      local cx, cy2 = it.j[1] + 0.45 * it.L * ax, it.j[2] + 0.45 * it.L * ay
      for _, b in ipairs(items) do
        if b.kind == "bunch" then
          local hw, m = 0.35 * b.L, 0.55 * it.L
          if abs(cx - b.t[1]) < hw + m and cy2 < b.t[2] + m and cy2 > b.t[2] - b.L - m then pulled = true break end
        end
      end
    end
    if not pulled then kept[#kept + 1] = it end
  end
  items = kept

  -- 3. paint, from the back of the canopy to the front
  local function green(it)
    local base = it.tint > 0 and mix(C.leaf, C.leaflight, 0.5 * it.tint) or mix(C.leaf, C.leafdark, -0.4 * it.tint)
    local c = mix(base, white and C.yellow or C.red, it.turn)
    return scale(c, 0.8 + 0.2 * (it.z + 1) / 2)
  end
  for _, it in ipairs(items) do
    local k = it.kind
    if k == "spur" then
      place(MID - 1, 0, 0, 0, function()
        local q, e = it.q, it.e
        band({ { q[1], q[2] }, { lerp(q[1], e[1], 0.5), lerp(q[2], e[2], 0.5) + 0.02 }, { e[1], e[2] } }, 0.3 * size,
          0.2 * size, C.cane)
        local mx, my = lerp(q[1], e[1], 0.45), lerp(q[2], e[2], 0.45)        -- the node it was cut above
        ink.circle(mx, my, 0.12 * size) ink.fill(mix(C.cane, C.barkdark, 0.3))
        local ca, sa = dir(it.a)
        local cx, cy, rr = e[1], e[2], 0.1 * size
        ink.moveto(cx + rr * sa, cy - rr * ca)
        ink.curveto(cx + rr * sa + 0.5 * rr * ca, cy - rr * ca + 0.5 * rr * sa, cx - rr * sa + 0.5 * rr * ca,
          cy + rr * ca + 0.5 * rr * sa, cx - rr * sa, cy + rr * ca)
        ink.curveto(cx - rr * sa - 0.3 * rr * ca, cy + rr * ca - 0.3 * rr * sa, cx + rr * sa - 0.3 * rr * ca,
          cy - rr * ca - 0.3 * rr * sa, cx + rr * sa, cy - rr * ca)
        ink.close() ink.fill({ 0.78, 0.68, 0.5 }) ink.stroke(C.barkdark, 0.25, 0.8)
        if it.stub then                                   -- last year's dead stub beside it
          local sx, sy = q[1] + it.stub * 0.35 * size, q[2] + 0.1
          band({ { sx, sy }, { sx + it.stub * 0.08 * size, sy + 0.35 * size } }, 0.18 * size, 0.14 * size, { 0.5, 0.46, 0.42 })
        end
      end)
    elseif k == "shoot" then
      place(layer(it.z) == MID and MID or layer(it.z), 0, 0, 0, function()
        band(it.pts, it.w0, 0.45 * it.w0, shootc)
      end)
    elseif k == "node" then
      place(MID, 0, 0, 0, function()
        local p = it.p
        local ca, sa = dir(it.ta)
        ink.moveto(p[1] - 0.06 * size * sa, p[2] + 0.06 * size * ca) ink.lineto(p[1] + 0.06 * size * sa, p[2] - 0.06 * size * ca)
        ink.stroke(scale(shootc, 0.6), 0.8, 0.8)
        -- the dormant bud in the axil, on the leaf's side, just above the node
        local bx, by = p[1] - it.side * 0.06 * size * sa + 0.05 * size * ca, p[2] + it.side * 0.06 * size * ca + 0.05 * size * sa
        ink.circle(bx, by, 0.035 * size) ink.fill(mix(C.cane, C.shoot, 0.3 * (1 - wooded)))
        ink.circle(bx, by, 0.035 * size) ink.stroke(C.barkdark, 0.2, 0.7)
      end)
    elseif k == "leaf" then
      counts.leaf = counts.leaf + 1
      -- the blade is a plane at an angle of its own: turned about its midrib (yaw) and tipped
      -- toward or away from the reader (pitch), seen foreshortened; now and then turned far
      -- enough to show its paler underside. Lit by how it faces the light, up and to the left
      local under = layout.chance(0.12)
      local pose = { yaw = under and (layout.chance(0.5) and 1 or -1) * layout.range(110, 140) or layout.sym(62),
        pitch = layout.sym(48), cup = layout.range(-0.1, 0.45), droop = layout.range(-0.15, 0.4),
        wave = layout.range(0.03, 0.09), wph = layout.range(0, 2 * pi), twist = layout.sym(0.3) }
      local c = green(it)
      if under then c = mix(c, { 0.66, 0.74, 0.5 }, 0.5) end
      -- its hairs: an underside's felt, the variety's; a young leaf near the tip downy on top
      local fuzz = under and v.hair or (it.young or 0) * (0.35 + 0.6 * v.hair)
      -- the oldest leaves, low on the cane, wear as the season goes on: a darker, deeper green
      -- (and torn here and there, in leaf)
      local old = (it.old or 0) * clamp((age - 0.45) / 0.4, 0, 1)
      c = mix(c, scale(C.leafdark, 0.9), 0.5 * old)
      local pc = mix(C.petiole, C.red, white and 0.1 or 0.35)
      local n, j = it.node, it.j
      place(layer(it.z), 0, 0, 0, function()
        -- the leaf's stalk: out from the node, arching up, the blade hanging from its end;
        -- swollen where it joins the cane and where it meets the blade
        local pl = dist(n[1], n[2], j[1], j[2])
        local mx, my = lerp(n[1], j[1], 0.5), lerp(n[2], j[2], 0.5) + 0.22 * pl
        local stalk = {}
        for i = 0, 10 do
          local u = i / 10
          stalk[#stalk + 1] = { (1 - u) ^ 2 * n[1] + 2 * u * (1 - u) * mx + u * u * j[1],
            (1 - u) ^ 2 * n[2] + 2 * u * (1 - u) * my + u * u * j[2] }
        end
        local w = 0.055 * size * it.L / (1.2 * size)
        band(stalk, 1.5 * w, 0.85 * w, pc)
        ink.circle(n[1], n[2], 0.9 * w) ink.fill(scale(pc, 0.85))
        ink.push() ink.translate(j[1], j[2]) ink.rotate(it.axis - 90) ink.scale(it.L)
        leaf(rng.fork(), c, v, sp.teeth, sp.dissection, lx, under, pose, (it.axis - 90) * RAD, fuzz, old)
        ink.pop()
      end)
    elseif k == "bunch" then
      counts.bunch = counts.bunch + 1
      local n, t = it.node, it.t
      place(layer(it.z), 0, 0, 0, function()
        ink.moveto(n[1], n[2]) ink.curveto(lerp(n[1], t[1], 0.5), lerp(n[2], t[2], 0.5) + 0.05, t[1], t[2] + 0.04, t[1], t[2])
        ink.stroke(mix(C.shoot, C.cane, 0.45), 1.0, 1)
        ink.push() ink.translate(t[1], t[2])
        counts.grape = counts.grape + bunch(rng.fork(), sp, it.L, v.ink or BERRY[sp.berrytone], BLOOM[sp.berrytone], lx,
          ripe, it.rb, v.n, v)
        ink.pop()
      end)
    elseif k == "tendril" then
      counts.tendril = counts.tendril + 1
      local n = it.node
      if it.wire then
        place(layer(it.z), 0, 0, 0, function()
          local r = rng.fork()
          local wxp = n[1] + r.sym(0.35) * size
          ink.moveto(n[1], n[2]) ink.curveto(lerp(n[1], wxp, 0.3), n[2] + 0.1, lerp(n[1], wxp, 0.8), it.wire + 0.12, wxp, it.wire)
          ink.stroke(mix(C.tendril, C.cane, wooded), 0.45, 1)
          local pts, turns = {}, floor(r.range(3, 6))
          for k2 = 0, turns * 12 do
            local t = k2 / 12 * 2 * pi
            pts[#pts + 1] = { wxp + 0.035 * size * k2 / 12 * 1.4 + 0.05 * size * cos(t) * 0.3, it.wire + 0.05 * size * sin(t) }
          end
          ink.smooth(pts, false) ink.stroke(mix(C.tendril, C.cane, wooded), 0.35, 1)
        end)
      else
        place(layer(it.z), n[1], n[2], it.a, function()
          tendril(rng.fork(), it.L, mix(C.tendril, C.cane, wooded))
        end)
      end
    end
  end

  -- assemble: a clip a little outside the column, so nothing strays into the text
  ink.layer(0)
  ink.poly({ { col[1] - 0.25, col[2] - 0.3 }, { col[3] + 0.3, col[2] - 0.3 }, { col[3] + 0.3, col[4] + 0.3 },
    { col[1] - 0.25, col[4] + 0.3 } }, true)
  ink.clip()
  ink.layer(99)
  ink.unclip()

  if texio then
    texio.write_nl(string.format("florilegium-grapes: a %s vine, %d shoots, %d leaves, %d bunches, %d tendrils", sp.variety,
      counts.shoot, counts.leaf, counts.bunch, counts.tendril))
  end
  ink.flush()
end

return M
