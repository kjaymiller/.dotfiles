--- linkfinder: finds [url] / [text](url) links and appends a Links
--- section at the bottom of the current file (or the whole project with `!`).

local M = {}

-- matches a rendered list entry: "- https://..." or "- [text](url)"
-- matches a rendered list entry: "- https://..." or "- [text](url)"
local LINK_PATTERNS = {
  "^%- (https?://%S+)$",
  "^%- %[[^%]]*%]%(([^%s)]+)%)$",
}

local function is_link_line(line)
  for _, pat in ipairs(LINK_PATTERNS) do
    if line:match(pat) then
      return true
    end
  end
  return false
end

-- Extract unique links from a chunk of text.
-- Supports markdown [text](url) and bare bracketed [https://...] forms.
local function extract(content, links, seen)
  -- [text](url)
  for label, url in content:gmatch("%[([^%]]*)%]%(([^%s)]+)%)") do
    local key = label .. "|" .. url
    if not seen[key] then
      seen[key] = true
      table.insert(links, { label = label ~= "" and label or url, url = url })
    end
  end

  -- bare [https://...]
  for url in content:gmatch("%[(https?://[^%]]+)%]") do
    local key = "|" .. url
    if not seen[key] then
      seen[key] = true
      table.insert(links, { label = url, url = url })
    end
  end

  return links
end

local function collect_from_buffer(bufnr)
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  return extract(content, {}, {})
end

local function collect_from_project()
  local links, seen = {}, {}

  -- prefer git-tracked files, fall back to everything on disk
  local files = vim.fn.systemlist("git ls-files 2>/dev/null")
  if vim.v.shell_error ~= 0 or #files == 0 then
    files = vim.fn.globpath(vim.fn.getcwd(), "**/*", false, true)
  end

  for _, file in ipairs(files) do
    -- only text-ish files, skip big/binary ones
    if vim.fn.isdirectory(file) == 0 and vim.fn.getfsize(file) < 512 * 1024 then
      local ok, content = pcall(vim.fn.readfile, file)
      if ok then
        extract(table.concat(content, "\n"), links, seen)
      end
    end
  end

  return links
end

--- Remove links previously appended by this plugin from the bottom of the
--- lines list, so re-running doesn't stack duplicates.
local function strip_appended_links(lines)
  while #lines > 0 do
    local last = lines[#lines]
    if last == "" or is_link_line(last) then
      table.remove(lines)
    else
      break
    end
  end
  return lines
end

local function render(links)
  local out = { "" }
  for _, link in ipairs(links) do
    if link.label == link.url then
      table.insert(out, "- " .. link.url)
    else
      table.insert(out, "- [" .. link.label .. "](" .. link.url .. ")")
    end
  end
  return out
end

function M.collect(project_wide)
  local links = project_wide and collect_from_project() or collect_from_buffer(0)

  if #links == 0 then
    vim.notify("linkfinder: no links found", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  lines = strip_appended_links(lines)
  vim.list_extend(lines, render(links))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  vim.notify(("linkfinder: wrote %d link(s)"):format(#links), vim.log.levels.INFO)
end

return M
