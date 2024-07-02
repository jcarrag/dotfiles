-- Utils
local M = {}

-- Join spaceless
function M.join_spaceless()
  vim.api.nvim_exec2("normal gJ<cr>", {})
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local char = vim.api.nvim_get_current_line():sub(col+1,col+1)
  if char:match('%s') ~= nil then
    vim.api.nvim_exec2("normal dw<cr>", {})
  end
end

-- Only close other windows other than this one and NERDTree
function M.onlyAndNeotree()
  local currentWindowId = vim.api.nvim_get_current_win()
  for _,windowId in pairs(vim.api.nvim_tabpage_list_wins(0)) do
    if windowId ~= currentWindowId and vim.api.nvim_get_option_value("filetype", { win = windowId }) ~= "neo-tree" then
      vim.api.nvim_win_call(windowId, function() vim.cmd("silent! close") end)
    end
  end
end

return M
