# Agents

Before starting work, look for a `TODOS.md` in the repository root. If it exists, check it for anything outstanding.

## Running it

The package needs LuaLaTeX (Tectonic is XeTeX and does not work). Build the showcase with
`lualatex showcase.tex`.

The drawing code is Lua 5.3, so the tools run without TeX in Lua 5.3 or later:
`lua tools/bytes.lua`.

The README's images are rebuilt from scratch with `gallery/all.sh`, or one at a time with
`gallery/page.sh`, `gallery/varieties.sh` and the others beside it. They rasterise with
Swift's PDFKit, so they need macOS.
