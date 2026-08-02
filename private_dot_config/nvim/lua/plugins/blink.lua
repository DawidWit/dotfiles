-- Completion ranking, tuned for Tailwind.
--
-- tailwindcss-language-server answers with its entire class list (~13.6k items)
-- and leaves filtering to the client. With blink's defaults that means typing
-- `text-re` puts fuzzy/typo matches and nearby buffer words (`text-white`,
-- `text-gold-500`) above the exact prefix match `text-red-500`.
--
-- `exact` first ranks true prefix matches above everything else, and dropping
-- the proximity boost stops words that merely appear nearby from outranking
-- what was actually typed.

return {
  "saghen/blink.cmp",
  opts = {
    fuzzy = {
      sorts = { "exact", "score", "sort_text" },
      use_proximity = false,
    },
  },
}
