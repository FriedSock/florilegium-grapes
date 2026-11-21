# TODOs

A temporary list of outstanding work. Remove an item when it is done, and the file when it is empty.

- Trim the data each bunch of grapes takes up (`florilegium-theme-vine.lua`). With the powdery bloom (three clipped drifts, a grain of specks and a soft rim on each grape) the bunches are about 59% of a vine page's path operators (about 1.77 MB of 3 MB a page before compression, measured 2026-11-21, with the old shell style of bunch; measure again with the clusters style). Draw the powder only on grapes that can be seen (the front of the bunch, `d` high), and a single fill on those behind. Skip grapes that the grapes in front hide completely. Gather the outlines into one path per bunch and depth.

## Leaves (`florilegium-theme-vine.lua`)

- Older, drier leaves: in progress, not yet checked by eye. Each leaf has an age (`old`, highest low on the cane, growing with the season) that dulls and yellows it, browns its edge and lobe tips, and spots it. The first try was too faint, as the oldest leaves are plucked from the fruit zone; the range was widened but the result has not been looked at.
- Side shoots: laterals growing from the leaf axils, with their own small leaves and tendrils, are missing. (The code grows a short lateral at about one node in six above the fruit zone, but they are too small and few to be seen.)
- The ends of the canes are always drawn trimmed (hedged). That is right at veraison and harvest but not in spring or early summer, when the shoots are still growing and end in their soft, unfolding tips.

### Handled, could be improved

- Leaf size by age: done (largest low on the cane, shrinking toward the tip, the first one or two a little small). The curve is a guess and could be checked against measurements of leaf area by node; the few leaves left in the plucked fruit zone could be the largest.
- Pubescence: done (a pale felt, fine hairs and an edge fringe on undersides, by variety, and on young leaves near the tips). The hairiness values are mostly typical rather than sourced; the hairs are cobweb-like on a real young leaf, gathering along the veins, where ours are spread evenly; and they add about 0.7 MB to the ten-page showcase, so small or far-back leaves could go without them.
