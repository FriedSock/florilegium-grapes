-- florilegium-grapes.lua -- the glue between florilegium-grapes.sty and the vine: the page's layout, its
-- seed and season, and the vine drawn into its margin as the page ships out.
-- Copyright (c) 2026 Kevin Raymond, 2026 Jack Bracewell. MIT License: see LICENSE or
-- florilegium-grapes.sty.

local vine = require("florilegium-grapes-vine")
local M = {}

local SP_CM = 2.54 / (72.27 * 65536)          -- cm per scaled point
local function cm(name) return tex.dimen[name] * SP_CM end

-- the page layout, in cm from the lower-left corner of the paper. The vine grows in the
-- wider side margin: when that is the right one (the outer margin of a right-hand page in a
-- two-sided document), the layout is made for the mirrored page and drawn reflected
-- (g.mirror; ink.page_transform)
M.twoside = false                             -- \if@twoside, set at each shipout
function M.geometry()
  local inch = 2.54
  local even = M.twoside and tex.count[0] % 2 == 0
  local g = {
    pw = cm("paperwidth"), ph = cm("paperheight"),
    textleft = inch + tex.hoffset * SP_CM + cm(even and "evensidemargin" or "oddsidemargin"),
  }
  g.textright = g.textleft + cm("textwidth")
  if g.pw - g.textright > g.textleft + 0.05 then
    g.mirror = true
    g.textleft, g.textright = g.pw - g.textright, g.pw - g.textleft
  end
  g.colright = g.textleft - 0.4
  return g
end

-- a number the user wrote (\florilegiumgrapesseed, \florilegiumgrapesage): its value, or, when it is not
-- a number, the default, with a warning in the log
function M.number(key, text, default)
  local v = tonumber(text)
  if v and v - v == 0 then return v end         -- a finite number (inf - inf and nan - nan are nan)
  if luatexbase and luatexbase.module_warning then
    luatexbase.module_warning("florilegium-grapes", string.format("%s{%s} is not a number; ignored", key, text))
  end
  return default
end

-- the page's seed: from the page number, and the document's seed if it has one
M.docseed = 0                                 -- \florilegiumgrapesseed, or 0
function M.seed(page, fixed)
  M.docseed = fixed and math.floor(fixed) or 0
  return fixed and (M.docseed * 7919 + page * 131) or (page * 97 + 1030)
end

-- the season: 0 spring, 0.5 summer, 1 autumn; nil is late summer. \florilegiumgrapesage sets it;
-- the option aging spreads it over the document, from the page count of the last run
M.age = nil
function M.auto_age(page, last) M.age = last > 1 and math.min(1, (page - 1) / (last - 1)) or 0.5 end

-- the variety (option vine=...)
M.vine = "pinot"
M.pruning = "spur"

-- the vine for this page, drawn into the shipout picture; an error stops this page's vine,
-- not the document
function M.page(seed)
  local ok, err = pcall(function()
    local g = M.geometry()
    g.seed, g.docseed, g.age, g.vine, g.pruning = seed, M.docseed, M.age, M.vine, M.pruning
    vine.page(g)
  end)
  if not ok then
    err = tostring(err)
    tex.error(err:find("^florilegium%-grapes") and err or "florilegium-grapes: " .. err)
  end
end

return M
