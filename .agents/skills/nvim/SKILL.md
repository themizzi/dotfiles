---
name: nvim
description: Use the Neovim MCP when editing files in an active Neovim session, navigating to changes so the user can follow along and saving completed edits.
---

# Neovim editing

When the Neovim MCP is available and connected to the user's editor:

1. Check the editor state before editing, including the working directory and modified buffers. Connect first if necessary.
2. Open each file in a visible window and navigate to the relevant lines as you work, so the user can follow the changes. If useful, highlight changed lines and clear those highlights afterward.
3. Prefer the MCP buffer-editing tools for files open in Neovim. Read the buffer first: its contents may differ from the file on disk. Make targeted, undoable edits and preserve existing work.
4. Save completed edits through Neovim, for example with `:write`, and verify that the save succeeded. Buffer edits are not saved automatically.

Do not silently save pre-existing unsaved changes: saving a buffer writes all of its changes, not just yours. If a buffer was already modified, preserve its contents and ask before saving it. Never force a reload, overwrite, or discard unsaved changes. If Neovim is unavailable, use the normal file-editing workflow and explain that editor navigation was unavailable.
