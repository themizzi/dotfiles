local mapping = vim.fn.maparg(" e", "n", false, true)
assert(type(mapping.callback) == "function")
mapping.callback()
assert(vim.bo.filetype == "netrw")
