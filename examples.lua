-- Example lazy.nvim plugin spec (copy to your plugins folder)
--[[

return {
  "yourusername/tailwind-multiline.nvim",
  ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" },
  opts = {
    -- Customize keymaps (set to false to disable)
    keymaps = {
      expand = "<leader>xs",   -- Expand inline className to multi-line
      collapse = "<leader>xS", -- Collapse multi-line className to inline
    },
    auto_indent = true, -- Smart indent for o, O, and Enter in className blocks
  },
}

-- Or with custom keymaps:
return {
  "yourusername/tailwind-multiline.nvim",
  ft = { "typescriptreact", "javascriptreact" },
  opts = {
    keymaps = {
      expand = "<leader>te",
      collapse = "<leader>tc",
    },
  },
}

-- Or disable default keymaps and set your own:
return {
  "yourusername/tailwind-multiline.nvim",
  ft = { "typescriptreact", "javascriptreact" },
  opts = {
    keymaps = {
      expand = false,
      collapse = false,
    },
  },
  keys = {
    { "<leader>tw", function() require("tailwind-multiline").expand() end, desc = "Expand Tailwind classes" },
    { "<leader>tW", function() require("tailwind-multiline").collapse() end, desc = "Collapse Tailwind classes" },
  },
}

]]

return {}
