-- blink.cmp colors tailwind class completions automatically (it special-cases the
-- `tailwindcss` client). This just swaps the generic Color icon for a solid swatch,
-- the way VSCode's Tailwind IntelliSense renders it.
return {
  "saghen/blink.cmp",
  opts = {
    sources = {
      providers = {
        lsp = {
          opts = { tailwind_color_icon = "██" },
        },
      },
    },
  },
}
