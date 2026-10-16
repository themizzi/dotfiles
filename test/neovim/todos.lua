local calls = {}
local function record(name) return function() table.insert(calls, name) end end
package.loaded['todo-comments'] = {jump_next = record('next'), jump_prev = record('prev')}
for _, name in ipairs({'TodoLocList', 'TodoQuickFix', 'TodoFzfLua'}) do vim.api.nvim_create_user_command(name, record(name), {}) end
for _, key in ipairs({'tn', 'tp', 'tl', 'tq', 'tf'}) do vim.fn.maparg(' ' .. key, 'n', false, true).callback() end
assert(table.concat(calls, ',') == 'next,prev,TodoLocList,TodoQuickFix,TodoFzfLua')
vim.ui.input = function(opts, callback)
  assert(opts.default == [[\vTODO|FIXME|HACK|NOTE]])
  callback(nil)
end
vim.fn.maparg(' ts', 'n', false, true).callback()
