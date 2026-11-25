-- florilegium-grapes.lua -- the glue between florilegium-grapes.sty and the vine: the page's layout, its
-- seed and season, and the vine drawn into its margin as the page ships out.
-- Copyright (c) 2026 Kevin Raymond, 2026 Jack Bracewell. MIT License: see LICENSE or
-- florilegium-grapes.sty.

local vine = require("florilegium-grapes-vine")
local M = {}

local CM_PER_SCALED_POINT = 2.54 / (72.27 * 65536)
local CM_PER_INCH = 2.54
local NARROWEST_COLUMN_CM = 4.4
local MARGIN_EDGE_CM = 0.3

local function dimension_cm(name) return tex.dimen[name] * CM_PER_SCALED_POINT end

local function warn(message)
  if luatexbase and luatexbase.module_warning then luatexbase.module_warning("florilegium-grapes", message) end
end

M.two_sided = false   -- \if@twoside, set at each shipout
M.column_width_cm = nil   -- width=, \florilegiumgrapeswidth: from the text out; nil for the whole margin
M.variety = "pinot"   -- vine=, \florilegiumgrapesvine
M.pruning = "spur"   -- pruning=, \florilegiumgrapespruning
M.season = nil   -- \florilegiumgrapesage, or the aging option: 0 spring, 0.5 summer, 1 autumn; nil late summer

local text_end = nil
local has_warned_of_narrow_column = false

-- \florilegiumgrapestextend: the page the text ends on, and how far down it the text reaches
function M.mark_text_end(page_number, depth_sp) text_end = { page_number = page_number, depth_sp = depth_sp } end

local function text_left_edge(page_number)
  local is_even_page = M.two_sided and page_number % 2 == 0
  return CM_PER_INCH + tex.hoffset * CM_PER_SCALED_POINT + dimension_cm(is_even_page and "evensidemargin" or "oddsidemargin")
end

local function text_top(paper_height)
  return paper_height - CM_PER_INCH - tex.voffset * CM_PER_SCALED_POINT - dimension_cm("topmargin")
    - dimension_cm("headheight") - dimension_cm("headsep")
end

local function warn_once_if_narrow(column_width)
  if column_width < NARROWEST_COLUMN_CM and not has_warned_of_narrow_column then
    has_warned_of_narrow_column = true
    warn(string.format("the vine's column is %.1f cm wide; below %.1f cm its leaves and bunches overhang it", column_width,
      NARROWEST_COLUMN_CM))
  end
end

-- the page layout, in cm from the lower-left corner of the paper. The vine grows in the
-- wider side margin: when that is the right one (the outer margin of a right-hand page in a
-- two-sided document), the layout is made for the mirrored page and drawn reflected
local function page_layout(page_number)
  local layout = { paper_width = dimension_cm("paperwidth"), paper_height = dimension_cm("paperheight"),
    text_left = text_left_edge(page_number) }
  layout.text_right = layout.text_left + dimension_cm("textwidth")
  if layout.paper_width - layout.text_right > layout.text_left + 0.05 then
    layout.mirrored = true
    layout.text_left, layout.text_right = layout.paper_width - layout.text_right, layout.paper_width - layout.text_left
  end
  layout.column_right = layout.text_left - 0.4
  if text_end and text_end.page_number == page_number then
    layout.text_end_y = text_top(layout.paper_height) - text_end.depth_sp * CM_PER_SCALED_POINT
  end
  layout.column_left = M.column_width_cm and math.max(MARGIN_EDGE_CM, layout.column_right - M.column_width_cm)
    or MARGIN_EDGE_CM
  warn_once_if_narrow(layout.column_right - layout.column_left)
  return layout
end

local function is_finite(value) return value - value == 0 end

-- a number the user wrote (\florilegiumgrapesseed, \florilegiumgrapesage): its value, or nil,
-- with a warning in the log, when it is not a finite number
function M.parse_number(command, text)
  local value = tonumber(text)
  if value and is_finite(value) then return value end
  warn(string.format("%s{%s} is not a number; ignored", command, text))
  return nil
end

-- the page's seed: from the page number, and the document's seed if it has one
function M.page_seed(page_number, document_seed)
  if document_seed then return math.floor(document_seed) * 7919 + page_number * 131 end
  return page_number * 97 + 1030
end

-- the aging option: spring on the first sheet to autumn on the last, by the sheet count of the
-- run before
function M.set_season_from_sheet(sheet_number, sheet_count)
  M.season = sheet_count > 1 and math.min(1, (sheet_number - 1) / (sheet_count - 1)) or 0.5
end

-- the vine for this page, drawn into the shipout picture; an error stops this page's vine,
-- not the document. document_seed: \florilegiumgrapesseed, or nil
function M.draw_vine_on_page(page_number, document_seed)
  local ok, err = pcall(function()
    local settings = page_layout(page_number)
    settings.seed = M.page_seed(page_number, document_seed)
    settings.document_seed = document_seed and math.floor(document_seed) or 0
    settings.season, settings.variety, settings.pruning = M.season, M.variety, M.pruning
    vine.draw_page(settings)
  end)
  if not ok then
    err = tostring(err)
    tex.error(err:find("^florilegium%-grapes") and err or "florilegium-grapes: " .. err)
  end
end

return M
