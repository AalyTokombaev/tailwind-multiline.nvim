# tailwind-multiline.nvim

Transform inline Tailwind `className` strings into multi-line template literals and back.

> 100% vibe coded

## The Problem

You write this:

```jsx
<section className="flex flex-col border-3 border-yellow-400 max-w-60 h-auto perspective-origin-top skew-x-4 skew-y-6">
```

But you want this:

```jsx
<section className={
  `flex
  flex-col
  border-3
  border-yellow-400
  max-w-60
  h-auto
  perspective-origin-top
  skew-x-4
  skew-y-6
  `
}>
```

## Features

- **Expand** inline className to multi-line template literal
- **Collapse** multi-line back to inline
- **Smart indentation** when adding new classes with `o`, `O`, or `Enter`

## Installation

### lazy.nvim

```lua
{
  "alexanderiversen/tailwind-multiline.nvim",
  ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" },
  opts = {},
}
```

## Configuration

```lua
{
  "alexanderiversen/tailwind-multiline.nvim",
  ft = { "javascriptreact", "typescriptreact" },
  opts = {
    keymaps = {
      expand = "<leader>xs",   -- Set to false to disable
      collapse = "<leader>xS", -- Set to false to disable
    },
    auto_indent = true, -- Smart indent for o, O, and Enter in className blocks
  },
}
```

### Custom Keymaps

```lua
{
  "alexanderiversen/tailwind-multiline.nvim",
  ft = { "typescriptreact", "javascriptreact" },
  opts = {
    keymaps = {
      expand = "<leader>te",
      collapse = "<leader>tc",
    },
  },
}
```

### DIY Keymaps

```lua
{
  "alexanderiversen/tailwind-multiline.nvim",
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
```

## Commands

- `:TailwindMultiline` - Expand inline className to multi-line
- `:TailwindInline` - Collapse multi-line className to inline

## Usage

1. Put your cursor on a line with `className="..."`
2. Hit `<leader>xs` (or your custom keymap)
3. Classes are now multi-line
4. Add new classes with proper indentation using `o`, `O`, or `Enter`
5. Hit `<leader>xS` to collapse back to inline when needed

## Why?

Because `cn()` is great but sometimes your boss says no. This gives you readable multi-line classes without any runtime dependencies.
