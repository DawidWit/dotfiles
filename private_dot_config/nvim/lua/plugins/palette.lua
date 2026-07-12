-- Custom color overrides layered on top of tokyonight.
--
-- LSP semantic tokens (@lsp.type.*) win over treesitter captures, so any token
-- an LSP also highlights has to be set in both namespaces or it reverts to the
-- theme's color the moment a language server attaches.
local overrides = {
  -- brackets: () [] {}. Neutral gray like VSCode Dark+, so they no longer read
  -- as functions (which keep the yellow below).
  ["#d4d4d4"] = {
    "@punctuation.bracket",
  },
  -- functions (VSCode Dark+), and the comma/semicolon punctuation sharing their color
  ["#dcdcaa"] = {
    "Delimiter",
    "@punctuation.delimiter",
    "@punctuation.special",
    "Function",
    "@function",
    "@function.call",
    "@function.method",
    "@function.method.call",
    "@lsp.type.function",
    "@lsp.type.method",
  },
  -- strings (VSCode Dark+)
  ["#ce9178"] = {
    "String",
    "@string",
    "@string.documentation",
    "@lsp.type.string",
  },
  -- numbers and booleans: a lighter green than the #4ec9b0 class teal
  ["#b5cea8"] = {
    "Boolean",
    "Number",
    "Float",
    "@boolean",
    "@number",
    "@number.float",
    "@constant.builtin", -- NaN, Infinity, and also null / undefined
  },
  -- operators: = => + < ?? === ++ %
  ["#ffffff"] = {
    "Operator",
    "@operator",
    "@lsp.type.operator",
  },
  -- comments (VSCode Dark+)
  ["#6a9955"] = {
    "Comment",
    "@comment",
    "@comment.documentation",
    "@lsp.type.comment",
  },
  -- control-flow keywords: async, await, try, catch, throw, return, if, for, while.
  -- Tokyo Night's orange, matching the wezterm scheme and the tmux status bar.
  ["#ff9e64"] = {
    "Conditional",
    "Repeat",
    "Exception",
    "@keyword.conditional",
    "@keyword.conditional.ternary",
    "@keyword.coroutine",
    "@keyword.debug",
    "@keyword.exception",
    "@keyword.repeat",
    "@keyword.return",
  },
  -- declaration & operator keywords: const, let, function, import, typeof, new.
  -- Midpoint of the control-flow orange (#ff9e64) and the function yellow (#dcdcaa).
  ["#eebd87"] = {
    "Keyword",
    "@keyword",
    "@keyword.function",
    "@keyword.import",
    "@keyword.modifier",
    "@keyword.operator",
    "@keyword.type",
  },
  -- variables, parameters and properties (VSCode Dark+)
  ["#9cdcfe"] = {
    "Identifier",
    "@variable",
    "@variable.member",
    "@variable.parameter",
    "@property",
    "@lsp.type.variable",
    "@lsp.type.parameter",
    "@lsp.type.property",
  },
  -- unused variables, imports and params. VSCode fades these with an opacity
  -- overlay so each token keeps its own hue; nvim can only set one flat color
  -- for the whole span, so this is the variable blue at 50% over the background.
  ["#5f809a"] = {
    "DiagnosticUnnecessary",
  },
  -- classes, interfaces and type names: Promise, Error, User (VSCode Dark+)
  ["#4ec9b0"] = {
    "Type",
    "Structure",
    "@type",
    "@type.definition",
    "@lsp.type.class",
    "@lsp.type.enum",
    "@lsp.type.interface",
    "@lsp.type.type",
    "@lsp.type.typeParameter",
    -- Error, Map, Set: treesitter captures these as @type.builtin alongside the
    -- primitives, so the LSP's class tag is what tells them apart.
    "@lsp.typemod.class.defaultLibrary",
    "@lsp.typemod.interface.defaultLibrary",
  },
  -- primitive types: string, number, boolean, void. VSCode colors these blue
  -- rather than teal, keeping them distinct from class and interface names.
  ["#569cd6"] = {
    "@type.builtin",
  },
}

return {
  "folke/tokyonight.nvim",
  opts = {
    on_highlights = function(hl)
      for color, groups in pairs(overrides) do
        for _, group in ipairs(groups) do
          hl[group] = { fg = color }
        end
      end
    end,
  },
}
