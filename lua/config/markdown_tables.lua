-- Retain builtin rendering, then add display-only body-row rules.
-- Internal parser/context APIs keep widths consistent with wrapped cells and
-- concealed links. Recheck this adapter when updating render-markdown.
local M = {}

function M.parse(ctx)
  local marks = require('render-markdown.handler.markdown').parse(ctx)
  local Context = require('render-markdown.request.context')
  local Marks = require('render-markdown.lib.marks')
  local Parser = require('render-markdown.parser.table')
  local Indent = require('render-markdown.lib.indent')
  local context = Context.get(ctx.buf)
  local config = context.config.pipe_table
  if not config.enabled or not vim.tbl_contains({ 'padded', 'trimmed' }, config.cell) then return marks end

  local scratch = Marks.new(context, false)
  vim.list_extend(scratch:get(), marks)
  local query = vim.treesitter.query.parse('markdown', '(pipe_table) @table')
  context.view:nodes(ctx.root, query, function(_, node)
    local data = Parser.new(context, config):parse(node, scratch)
    if not data or not data.layout.valid then return end

    local parts = {}
    for _, col in ipairs(data.cols) do parts[#parts + 1] = string.rep('─', col.width) end
    -- Mixed-weight junctions meet heavy outside edges and thin column rules.
    local text = '┠' .. table.concat(parts, '┼') .. '┨'
    for i = 1, #data.rows - 1 do
      local row, following = data.rows[i].node, data.rows[i + 1].node
      if row.type == 'pipe_table_row' and following.type == 'pipe_table_row' then
        local line = context.config:line()
        if data.layout.wrap then
          line:extend(data.prefixes[row.start_row])
        else
          line:extend(Indent.new(context, node):line(true)):pad(data.layout.col)
        end
        line:text(text, config.row)

        -- Append to wrapped rows' synthetic lines, avoiding a competing mark.
        local replacement
        for _, mark in ipairs(marks) do
          if mark.start_row == row.start_row and mark.replace then
            replacement = mark.replace
            break
          end
        end
        if replacement then
          replacement[#replacement + 1] = line:get()
        else
          marks[#marks + 1] = {
            conceal = 'virtual_lines',
            modes = config.render_modes,
            start_row = row.start_row,
            start_col = 0,
            opts = { virt_lines = { line:get() }, virt_lines_above = false },
          }
        end
      end
    end
  end)
  return marks
end

return M
