-- tools/bytes.lua -- how much a vine page's drawing takes, and how much of it each part
-- takes, without TeX: the PDF path operators a page writes, before compression, averaged
-- over three pages (pinot noir, saperavi and gewurztraminer, late summer). Each part is
-- switched off in turn by patching its function in its module's source as it loads, so a
-- patch whose text the module no longer has stops the run: change the patch to match.
--   texlua tools/bytes.lua          (from the repository root)
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE.
package.path = "./?.lua;" .. package.path
local written = 0
tex = { sprint = function() end }
texio = nil
luatexbase = { registernumber = function() return 0 end }
node = { new = function() return {} end, write = function(literal) written = written + #literal.data end }

local MODULES = { "florilegium-grapes-ink", "florilegium-grapes-palette", "florilegium-grapes-varieties",
  "florilegium-grapes-leaf", "florilegium-grapes-bunch", "florilegium-grapes-shoot", "florilegium-grapes-wood",
  "florilegium-grapes-vine" }
local PAGES = { { variety = "pinot", page_number = 1 }, { variety = "saperavi", page_number = 2 },
  { variety = "gewurztraminer", page_number = 3 } }

local function source_of(module) return io.open(module .. ".lua"):read("a") end

-- each patch { module, a function's first line } makes that function return at once
local function load_vine(patches)
  for _, module in ipairs(MODULES) do package.loaded[module] = nil end
  local sources = {}
  for _, patch in ipairs(patches) do
    local module, first_line = patch[1], patch[2] .. "\n"
    local source = sources[module] or source_of(module)
    local at = source:find(first_line, 1, true)
    assert(at, first_line)
    sources[module] = source:sub(1, at - 1) .. patch[2] .. " do return end\n" .. source:sub(at + #first_line)
  end
  for module, source in pairs(sources) do package.loaded[module] = load(source, "=" .. module)() end
  return require("florilegium-grapes-vine")
end

local function average_bytes_a_page(patches)
  local vine = load_vine(patches or {})
  local total = 0
  for _, page in ipairs(PAGES) do
    written = 0
    vine.draw_page({ paper_width = 21, paper_height = 29.7, column_left = 0.3, column_right = 6.4,
      seed = page.page_number * 97 + 1030, document_seed = 0, season = 0.8, variety = page.variety, pruning = "spur" })
    total = total + written
  end
  return total / #PAGES
end

local PARTS = {
  { "leaves (all)", { { "florilegium-grapes-leaf", "function M.draw(rng, leaf)" } } },
  { "  of which hairs", { { "florilegium-grapes-leaf", "local function paint_hairs(rng, plan, edge, project_all, hairiness)" },
    { "florilegium-grapes-leaf", "local function paint_edge_fringe(rng, edge, project_all, hairiness)" } } },
  { "  of which side veins",
    { { "florilegium-grapes-leaf", "local function paint_side_veins(rng, plan, project_all, color, underside)" } } },
  { "bunches (all)", { { "florilegium-grapes-bunch", "function M.draw(rng, spec)" } } },
  { "  of which bloom powder",
    { { "florilegium-grapes-bunch", "local function paint_bloom(rng, grape, oval, bloom_color, wax, rubbed)" } } },
  { "trunk and cordon", { { "florilegium-grapes-wood", "function M.draw_old_wood(rng, centerline, start_width, end_width)" } } },
  { "tendrils", { { "florilegium-grapes-shoot", "function M.draw_tendril(rng, length, color)" } } },
}

local everything = average_bytes_a_page()
print(string.format("%-34s %6.0f KB a page", "everything", everything / 1024))
for _, part in ipairs(PARTS) do
  local without = average_bytes_a_page(part[2])
  print(string.format("%-34s %6.0f KB  (%2.0f%%)", part[1], (everything - without) / 1024, 100 * (everything - without) / everything))
end
