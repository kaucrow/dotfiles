-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Transparent background
local function transparent_back()
  local groups = { "Normal", "NormalNC", "LineNr", "Folded", "NonText", "SpecialKey", "VertSplit", "SignColumn", "EndOfBuffer" }
  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
  end
end

transparent_back()
