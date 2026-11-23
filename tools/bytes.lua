-- tools/bytes.lua -- how much a vine page's drawing takes, and how much of it each part
-- takes, without TeX: the PDF path operators a page writes, before compression, averaged
-- over three pages (pinot noir, saperavi and gewurztraminer, late summer). Each part is
-- switched off in turn by patching florilegium-grapes-vine.lua's source as it loads, so a
-- patch whose text the module no longer has stops the run: change the patch to match.
--   texlua tools/bytes.lua          (from the repository root)
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE.
package.path = "./?.lua;" .. package.path
local written = 0
tex = { sprint = function() end }
texio = nil
luatexbase = { registernumber = function() return 0 end }
node = { new = function() return {} end, write = function(n) written = written + #n.data end }
local src = io.open("florilegium-grapes-vine.lua"):read("a")
local function measure(patches)
  local s = src
  for _, p in ipairs(patches or {}) do
    local a, b = s:find(p[1], 1, true)
    assert(a, p[1])
    s = s:sub(1, a - 1) .. p[2] .. s:sub(b + 1)
  end
  local vine = load(s, "=vine")()
  local total = 0
  local pages = { { "pinot", 1 }, { "saperavi", 2 }, { "gewurztraminer", 3 } }
  for _, pg in ipairs(pages) do
    written = 0
    vine.page({ pw = 21, ph = 29.7, colright = 6.4, seed = pg[2] * 97 + 1030, docseed = 0, age = 0.8, vine = pg[1] })
    total = total + written
  end
  return total / #pages
end
local all = measure()
print(string.format("%-34s %6.0f KB a page", "everything", all / 1024))
-- a function that draws nothing: its first line, and the same with a return after it
local function off(line, ret) return { line .. "\n", line .. " do return " .. (ret or "") .. " end\n" } end
local LEAF = "local function leaf(r, c, v, lobes, depth, lx, under, pose, rot, fuzz, old)"
local SIDE = "        ink.poly(map({ { x0, y0 }, { lerp(x0, x1, 0.55) + r.sym(0.02), lerp(y0, y1, 0.55) }, "
  .. "{ x1, y1 } }), false)"
local parts = {
  { "leaves (all)", { off(LEAF) } },
  { "  of which hairs", { { "if fuzz > 0.05 then", "if false then" }, { "if fuzz > 0.25 then", "if false then" } } },
  { "  of which side veins", { { SIDE, "" } } },
  { "bunches (all)", { off("local function bunch(r, sp, L, c, bl, lx, ripe, rb, want, v, out)", "0") } },
  { "  of which bloom powder", { { "if wax > 0.06 then", "if false then" } } },
  { "trunk and cordon", { off("local function wood(r, pts, w0, w1)") } },
  { "tendrils", { off("local function tendril(r, L, c)") } },
}
for _, p in ipairs(parts) do
  local without = measure(p[2])
  print(string.format("%-34s %6.0f KB  (%2.0f%%)", p[1], (all - without) / 1024, 100 * (all - without) / all))
end
