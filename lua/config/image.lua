-- image.nvim's magick_cli uses -scale (box sampling), which softens diagram
-- lettering when fitting images to terminal cells. Keep its processor, but use
-- Lanczos for the combined resize/crop step. No extra dependencies are needed.
local M = {}

function M.setup(opts)
  local processor = require('image/processors/magick_cli')
  processor.transform = function(path, request, output_path, callback)
    local source = path
    if (request.source_format or ''):lower() == 'gif' then source = source .. '[0]' end

    local args = { 'magick', source }
    if request.target_width and request.target_height then
      vim.list_extend(args, {
        '-filter', 'Lanczos', '-resize',
        string.format('%dx%d', request.target_width, request.target_height),
      })
    end
    if request.crop then
      local crop = request.crop
      vim.list_extend(args, {
        '-crop', string.format('%dx%d+%d+%d', crop.width, crop.height, crop.x, crop.y),
      })
    end
    args[#args + 1] = (request.output_format or 'png') .. ':' .. output_path

    -- Pass an argument vector: file paths never go through a shell.
    local ok, err = pcall(vim.system, args, { text = true }, function(result)
      if result.code == 0 then
        callback({ ok = true, path = output_path })
      else
        callback({ ok = false, error = result.stderr or 'Image resize failed' })
      end
    end)
    if not ok then callback({ ok = false, error = tostring(err) }) end
  end

  require('image').setup(opts)
end

return M
