vim.env.DOTFILES_NVIM_AI = '1'
vim.env.DOTFILES_NVIM_AI_ENDPOINT = 'https://example.invalid/custom/chat/completions'
vim.env.DOTFILES_NVIM_AI_MODEL = 'test-model'
local all = {}
for _, spec in ipairs(require('themizzi.plugins').specs()) do all[spec[1]] = spec end
for _, repo in ipairs({'olimorris/codecompanion.nvim', 'ravitemer/mcphub.nvim',
  'MeanderingProgrammer/render-markdown.nvim', 'HakonHarnes/img-clip.nvim'}) do
  assert(all[repo] and (not all[repo].commit or #all[repo].commit == 40))
end
local opts = all['olimorris/codecompanion.nvim'].opts()
assert(opts.strategies.chat.adapter == 'lmstudio' and opts.strategies.inline.adapter == 'lmstudio')
assert(opts.strategies.cmd.adapter == 'lmstudio')
package.loaded['codecompanion.adapters'] = {extend = function(base, adapter)
  assert(base == 'openai_compatible'); return adapter
end}
local adapter = opts.adapters.http.lmstudio()
assert(adapter.url == vim.env.DOTFILES_NVIM_AI_ENDPOINT)
assert(adapter.schema.model.default == 'test-model' and adapter.schema.model.choices[1] == 'test-model')
assert(all['ravitemer/mcphub.nvim'].build == nil and all['ravitemer/mcphub.nvim'].opts.use_bundled_binary == false)
assert(vim.fn.exists(':CodeCompanionChat') == 0)
