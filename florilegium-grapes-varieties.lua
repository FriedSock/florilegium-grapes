-- florilegium-grapes-varieties.lua -- the grape varieties a vine can be: each one's leaf, bunch
-- and grape, and the traits a vine of it may take.
-- Copyright (c) 2026 Jack Bracewell. MIT License: see LICENSE or florilegium-grapes.sty.

local ink = require("florilegium-grapes-ink")
local M = {}

-- each variety's leaf: its leaf_size, how far its basal lobes close the stalk's sinus (its
-- basal_lobe_angle: 140 an open U, 170 nearly closed), its tooth_spacing; the bunch as the
-- vineyard has it, its length in cm, its grape's diameter in mm and how many grapes it holds;
-- the grape's own color, a second color its grapes may be any shade toward (and how far), how
-- thick its waxy bloom (saperavi's dusts it blue-grey), and white_wine_grape for a white wine
-- grape whose tone is not pale (its leaves turn yellow, not red).
-- Pinot noir's petiolar sinus is a V, open; regent's lyre-shaped, open to overlapping;
-- johanniter's an open U (German Wikipedia's ampelography); rkatsiteli's bunch is 12 to 24
-- cm long, about 160 g, its grapes golden with bronze spots (Georgian descriptions). The
-- other figures are typical values, and the colors and shapes were checked against photos
-- of bunches on Wikimedia Commons (pinot noir in Burgundy blue-black under a dusty bloom;
-- gewurztraminer's grapes each a shade from gold to red-brown; rkatsiteli's and johanniter's
-- flecked with rust; regent's round and larger, about 155 g a bunch).
-- Touriga nacional's leaf is small, its petiolar sinus an open U; its bunch small, 100 to 250
-- g, of medium density, its grapes blue-black, 0.9 to 1.8 g (Vine to Wine Circle's
-- ampelography). Vidiano's bunch is medium to large and fairly dense, its grapes yellow-green
-- and thick-skinned (Yiannis Karakasis MW); no description of its leaf was found, so its
-- leaf's figures are typical values.
-- leaf_hairiness: how hairy its leaves' undersides are (0..1); its young leaves near the tips
-- are hairy on top too. Rkatsiteli's leaves are known for their down, regent's young leaves
-- are white-woolly (German Wikipedia); the others typical
local VARIETIES = {
  pinot = { leaf_size = 0.92, basal_lobe_angle = 150, tooth_spacing = 0.06, bunch_length_cm = 13,
    grape_diameter_mm = 13, grapes_per_bunch = 110, grape_color = { 0.14, 0.13, 0.25 }, bloom_thickness = 0.3,
    leaf_hairiness = 0.3 },
  saperavi = { leaf_size = 1.1, basal_lobe_angle = 150, tooth_spacing = 0.075, bunch_length_cm = 15,
    grape_diameter_mm = 15, grapes_per_bunch = 100, grape_color = { 0.16, 0.15, 0.3 }, bloom_thickness = 0.42,
    leaf_hairiness = 0.6 },
  gewurztraminer = { leaf_size = 0.85, basal_lobe_angle = 142, tooth_spacing = 0.06, bunch_length_cm = 12,
    grape_diameter_mm = 12, grapes_per_bunch = 90, grape_color = { 0.66, 0.36, 0.34 },
    alternate_grape_color = { 0.86, 0.64, 0.38 }, grape_color_variation = 0.8, bloom_thickness = 0.12,
    white_wine_grape = true, leaf_hairiness = 0.4 },
  rkatsiteli = { leaf_size = 1.1, basal_lobe_angle = 150, tooth_spacing = 0.08, bunch_length_cm = 17,
    grape_diameter_mm = 16, grapes_per_bunch = 95, grape_color = { 0.8, 0.79, 0.5 },
    alternate_grape_color = { 0.86, 0.76, 0.44 }, grape_color_variation = 0.5, bloom_thickness = 0.14,
    rusty_spots = true, leaf_hairiness = 0.75 },
  regent = { leaf_size = 1.0, basal_lobe_angle = 162, tooth_spacing = 0.07, bunch_length_cm = 13,
    grape_diameter_mm = 15, grapes_per_bunch = 85, grape_color = { 0.12, 0.11, 0.2 }, bloom_thickness = 0.2,
    leaf_hairiness = 0.55 },
  johanniter = { leaf_size = 1.0, basal_lobe_angle = 140, tooth_spacing = 0.07, bunch_length_cm = 13,
    grape_diameter_mm = 14, grapes_per_bunch = 100, grape_color = { 0.9, 0.8, 0.52 },
    alternate_grape_color = { 0.84, 0.84, 0.58 }, grape_color_variation = 0.4, bloom_thickness = 0.14,
    rusty_spots = true, leaf_hairiness = 0.15 },
  touriga = { leaf_size = 0.85, basal_lobe_angle = 140, tooth_spacing = 0.07, bunch_length_cm = 12,
    grape_diameter_mm = 13, grapes_per_bunch = 100, grape_color = { 0.13, 0.12, 0.24 }, bloom_thickness = 0.35,
    leaf_hairiness = 0.35 },
  vidiano = { leaf_size = 1.0, basal_lobe_angle = 150, tooth_spacing = 0.07, bunch_length_cm = 16,
    grape_diameter_mm = 15, grapes_per_bunch = 110, grape_color = { 0.76, 0.8, 0.46 },
    alternate_grape_color = { 0.82, 0.8, 0.48 }, grape_color_variation = 0.3, bloom_thickness = 0.14,
    leaf_hairiness = 0.4 },
}
-- and the traits a vine of the variety may take, one each drawn for the document: lobe_counts
-- (3 or 5, as many as the leaf is cut into, any one of the list), sinus_depth (how deep its
-- sinuses cut, a range), berry_tone (dark, red or pale grapes), berry_shapes (round, oval),
-- bunch_shapes (cylindrical, conical, winged) and compactness (2 fairly dense, 3 dense). Pinot
-- noir's leaf is slightly lobed, three to five; saperavi's three-lobed; regent's three-lobed,
-- rarely five, cut medium-deep; johanniter's and rkatsiteli's five-lobed (Wikipedia's
-- ampelography); touriga nacional's five-lobed with pronounced sinuses, its bunch cylindrical
-- to conical; vidiano's bunch conical, its grapes round or a little oval (its leaf's lobes
-- and depth typical)
local VARIETY_TRAITS = {
  pinot = { lobe_counts = { 3, 5 }, sinus_depth = { 0.15, 0.3 }, berry_tone = "dark",
    berry_shapes = { "round", "round", "oval" }, bunch_shapes = { "cylindrical" }, compactness = 3 },
  saperavi = { lobe_counts = { 3 }, sinus_depth = { 0.25, 0.4 }, berry_tone = "dark",
    berry_shapes = { "oval", "round" }, bunch_shapes = { "conical" }, compactness = 2 },
  gewurztraminer = { lobe_counts = { 3, 3, 3, 5 }, sinus_depth = { 0.08, 0.2 }, berry_tone = "red",
    berry_shapes = { "oval" }, bunch_shapes = { "conical" }, compactness = 3 },
  rkatsiteli = { lobe_counts = { 5 }, sinus_depth = { 0.35, 0.55 }, berry_tone = "pale",
    berry_shapes = { "oval", "round" }, bunch_shapes = { "conical", "conical", "winged" }, compactness = 2 },
  regent = { lobe_counts = { 3, 3, 3, 3, 5 }, sinus_depth = { 0.4, 0.55 }, berry_tone = "dark",
    berry_shapes = { "round", "round", "oval" }, bunch_shapes = { "cylindrical", "cylindrical", "conical" },
    compactness = 3 },
  johanniter = { lobe_counts = { 5 }, sinus_depth = { 0.35, 0.5 }, berry_tone = "pale",
    berry_shapes = { "round" }, bunch_shapes = { "cylindrical" }, compactness = 3 },
  touriga = { lobe_counts = { 5 }, sinus_depth = { 0.35, 0.5 }, berry_tone = "dark",
    berry_shapes = { "round" }, bunch_shapes = { "cylindrical", "conical" }, compactness = 2 },
  vidiano = { lobe_counts = { 5 }, sinus_depth = { 0.25, 0.4 }, berry_tone = "pale",
    berry_shapes = { "round", "round", "oval" }, bunch_shapes = { "conical" }, compactness = 3 },
}

local function fail_for_unknown_variety(variety_name)
  local known = {}
  for name in pairs(VARIETY_TRAITS) do known[#known + 1] = name end
  table.sort(known)
  error("florilegium-grapes: vine=" .. tostring(variety_name) .. "? a grape's variety is one of "
    .. table.concat(known, ", "), 0)
end

-- the document's vine of a variety (document_seed: \florilegiumgrapesseed, or 0), the same on
-- every page
function M.document_vine(variety_name, document_seed)
  local traits = VARIETY_TRAITS[variety_name]
  if not traits then fail_for_unknown_variety(variety_name) end
  local rng = ink.random_stream(document_seed * 104729 + 809)
  local lobe_count = rng.pick(traits.lobe_counts)
  local sinus_depth = rng.between(traits.sinus_depth[1], traits.sinus_depth[2])
  local berry_shape = rng.pick(traits.berry_shapes)
  local bunch_shape = rng.pick(traits.bunch_shapes)
  return { variety_name = variety_name, variety = VARIETIES[variety_name], lobe_count = lobe_count,
    sinus_depth = sinus_depth, berry_tone = traits.berry_tone, berry_shape = berry_shape, bunch_shape = bunch_shape,
    compactness = traits.compactness }
end

return M
