local specs = require('themizzi.plugins').specs()
for _, spec in ipairs(specs) do assert(#spec.commit == 40) end
local formats
for _, spec in ipairs(require('themizzi.plugins.editor')) do
  if spec[1] == 'stevearc/conform.nvim' then formats = spec.opts.formatters_by_ft end
end
assert(formats.python.stop_after_first and formats.javascript.stop_after_first)
