-- Utils
local M = {}

-- Join spaceless
function M.join_spaceless()
	vim.api.nvim_exec2("normal gJ<cr>", {})
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local char = vim.api.nvim_get_current_line():sub(col + 1, col + 1)
	if char:match("%s") ~= nil then
		vim.api.nvim_exec2("normal dw<cr>", {})
	end
end

-- Only close other windows other than this one and NERDTree
function M.onlyAndNeotree()
	local currentWindowId = vim.api.nvim_get_current_win()
	for _, windowId in pairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(windowId)
		if
			windowId ~= currentWindowId
			and vim.api.nvim_get_option_value("filetype", { buf = buf }) ~= "neo-tree"
		then
			vim.api.nvim_win_call(windowId, function()
				vim.cmd("silent! close")
			end)
		end
	end
end

--- Given a delimter split a string into a table.
---@param s string
---@param delimiter string
---@return table of split results
M.split_on = function(s, delimiter)
  local result = {}
  local from = 1
  local delim_from, delim_to = string.find(s, delimiter, from)
  while delim_from do
    table.insert(result, string.sub(s, from, delim_from - 1))
    from = delim_to + 1
    delim_from, delim_to = string.find(s, delimiter, from)
  end
  table.insert(result, string.sub(s, from))
  return result
end

return M
