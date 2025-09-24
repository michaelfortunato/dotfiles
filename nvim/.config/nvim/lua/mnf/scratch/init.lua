-- Scratch Buffer Manager - Quick temporary buffers with proper language detection
-- Provides easy access to named/numbered scratch buffers with intelligent filetype detection

---@class ScratchBuffer
---@field id integer|string
---@field buffer integer
---@field name string
---@field filetype string
---@field window integer?

---@class ScratchConfig
---@field name? string
---@field filetype? string
---@field content? string[]
---@field split? string
---@field focus? boolean

---@class ScratchManager
local M = {}

---@type fun(opts: table, on_confirm: fun(input: string?)): nil
M.input = Snacks.input.input or vim.ui.input
vim.api.nvim_create_autocmd("BufWriteCmd", {
  pattern = "[Scratch:*",
  callback = function()
    vim.notify("Scratch buffers cannot be saved", vim.log.levels.WARN)
  end,
})
-- State management
---@type table<string, ScratchBuffer>
M.scratch_buffers = {}

---@type string?
M.current_scratch = nil

-- Language detection patterns
---@type table<string, string>
M.language_patterns = {
  ["^#!/usr/bin/env python"] = "python",
  ["^#!/usr/bin/python"] = "python",
  ["^#!/usr/bin/env node"] = "javascript",
  ["^#!/usr/bin/env bash"] = "bash",
  ["^#!/bin/bash"] = "bash",
  ["^#!/bin/sh"] = "sh",
  ["^#!/usr/bin/env ruby"] = "ruby",
  ["^#!/usr/bin/ruby"] = "ruby",
  ["^#!.*lua"] = "lua",
  ["^#!.*perl"] = "perl",
  ["^#!.*php"] = "php",
  ["^<%?php"] = "php",
  ["^<html"] = "html",
  ["^<!DOCTYPE html"] = "html",
  ["^<\\?xml"] = "xml",
  ["^import "] = "python",
  ["^from .* import"] = "python",
  ["^def "] = "python",
  ["^class .*:"] = "python",
  ["^const "] = "javascript",
  ["^let "] = "javascript",
  ["^var "] = "javascript",
  ["^function "] = "javascript",
  ["^local "] = "lua",
  ["^function.*%(.*%)"] = "lua",
  ["^#!/usr/bin/env go"] = "go",
  ["^package "] = "go",
  ["^func "] = "go",
  ["^use "] = "rust",
  ["^fn "] = "rust",
  ["^mod "] = "rust",
  ["^#include"] = "c",
  ["^#define"] = "c",
  ["^int main"] = "c",
  ["^SELECT "] = "sql",
  ["^select "] = "sql",
  ["^CREATE TABLE"] = "sql",
  ["^create table"] = "sql",
  ["^INSERT INTO"] = "sql",
  ["^insert into"] = "sql",
}

-- Default filetype extensions
---@type table<string, string>
M.extension_to_filetype = {
  py = "python",
  js = "javascript",
  ts = "typescript",
  lua = "lua",
  rb = "ruby",
  go = "go",
  rs = "rust",
  c = "c",
  cpp = "cpp",
  h = "c",
  hpp = "cpp",
  java = "java",
  sh = "bash",
  bash = "bash",
  zsh = "zsh",
  fish = "fish",
  vim = "vim",
  sql = "sql",
  html = "html",
  css = "css",
  json = "json",
  xml = "xml",
  yaml = "yaml",
  yml = "yaml",
  toml = "toml",
  md = "markdown",
  tex = "tex",
  r = "r",
  pl = "perl",
  php = "php",
  swift = "swift",
  kt = "kotlin",
  scala = "scala",
  clj = "clojure",
  hs = "haskell",
  elm = "elm",
  dart = "dart",
  nix = "nix",
}

---@type table<string, string>
local filetype_to_extension = {
  python = "py",
  javascript = "js",
  typescript = "ts",
  lua = "lua",
  rust = "rs",
  go = "go",
  c = "c",
  cpp = "cpp",
  markdown = "md",
  tex = "tex",
  sh = "sh",
  bash = "sh",
  zsh = "zsh",
  yaml = "yml",
  json = "json",
}

-- Detect filetype from content
---@param lines string[]
---@return string?
local function detect_filetype_from_content(lines)
  if not lines or #lines == 0 then
    return nil
  end

  -- Check first few lines for patterns
  for i = 1, math.min(5, #lines) do
    local line = lines[i]
    if line and line ~= "" then
      for pattern, filetype in pairs(M.language_patterns) do
        if string.match(line, pattern) then
          return filetype
        end
      end
    end
  end

  return nil
end

-- Extract extension from name
---@param name string
---@return string?
local function get_extension(name)
  return string.match(name, "%.([^%.]+)$")
end

-- Get or create a scratch buffer
---@param config ScratchConfig
---@return ScratchBuffer
function M.get_or_create_scratch(config)
  --FIXME:  This id/name logic is broken still. Usuable but the buffer
  -- name looks weird
  config = config or {}
  local name = config.name
  local id = config.name

  -- If buffer exists and is valid, return it
  if id ~= nil and M.scratch_buffers[id] and vim.api.nvim_buf_is_valid(M.scratch_buffers[id].buffer) then
    return M.scratch_buffers[id]
  end

  local buf = vim.api.nvim_create_buf(false, true)
  if id == nil then
    id = buf
  end
  if name ~= nil then
    name = id .. "|" .. name
  else
    name = id
  end

  -- Set buffer options for scratch buffer
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false

  -- Detect filetype
  local filetype = config.filetype
  if not filetype then
    -- Try to detect from extension
    local ext = get_extension(name)
    if ext then
      filetype = M.extension_to_filetype[ext]
    end
  end

  -- If we have content, try to detect from content
  if not filetype and config.content then
    filetype = detect_filetype_from_content(config.content)
  end

  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, "[Scratch: " .. name .. "]" .. "." .. filetype_to_extension[filetype])

  -- Set filetype if detected
  if filetype then
    vim.bo[buf].filetype = filetype
  end

  -- Set initial content
  if config.content then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, config.content)
  end

  -- Create scratch buffer object
  local scratch_buf = {
    id = id,
    buffer = buf,
    name = name,
    filetype = filetype or "text",
    window = nil,
  }

  M.scratch_buffers[id] = scratch_buf
  M.current_scratch = id
  return scratch_buf
end

-- Show scratch buffer in window
---@param scratch_id string
---@param config? ScratchConfig
---@return nil
function M.show_scratch(scratch_id, config)
  config = config or {}
  local scratch_buf = M.get_or_create_scratch({ name = scratch_id, filetype = config.filetype })

  -- Determine window creation
  local win
  if config.split == "vsplit" then
    vim.cmd("vsplit")
    win = vim.api.nvim_get_current_win()
  elseif config.split == "split" then
    vim.cmd("split")
    win = vim.api.nvim_get_current_win()
  else
    -- Use current window
    win = vim.api.nvim_get_current_win()
  end

  -- Set buffer in window
  vim.api.nvim_win_set_buf(win, scratch_buf.buffer)
  scratch_buf.window = win

  -- Focus window if requested
  if config.focus ~= false then
    vim.api.nvim_set_current_win(win)
  end

  -- Update current scratch
  M.current_scratch = scratch_id
end

-- Close scratch buffer
---@param scratch_id string
---@return nil
function M.close_scratch(scratch_id)
  local scratch_buf = M.scratch_buffers[scratch_id]
  if not scratch_buf then
    return
  end

  -- Close window if it exists
  if scratch_buf.window and vim.api.nvim_win_is_valid(scratch_buf.window) then
    vim.api.nvim_win_close(scratch_buf.window, false)
    scratch_buf.window = nil
  end

  -- Delete buffer
  if vim.api.nvim_buf_is_valid(scratch_buf.buffer) then
    vim.api.nvim_buf_delete(scratch_buf.buffer, { force = true })
  end

  -- Remove from tracking
  M.scratch_buffers[scratch_id] = nil

  -- Update current scratch
  if M.current_scratch == scratch_id then
    M.current_scratch = nil
  end
end

-- List all scratch buffers
---@return nil
function M.list_scratches()
  local items = {}

  for id, scratch_buf in pairs(M.scratch_buffers) do
    if vim.api.nvim_buf_is_valid(scratch_buf.buffer) then
      local line_count = vim.api.nvim_buf_line_count(scratch_buf.buffer)
      local is_current = (M.current_scratch == id) and "● " or "  "
      local display =
        string.format("%s%s (%s) - %d lines", is_current, scratch_buf.name, scratch_buf.filetype, line_count)

      table.insert(items, {
        display = display,
        id = id,
        scratch_buf = scratch_buf,
      })
    end
  end

  if #items == 0 then
    vim.notify("No scratch buffers available", vim.log.levels.WARN)
    return
  end

  -- Sort by name
  table.sort(items, function(a, b)
    return a.scratch_buf.name < b.scratch_buf.name
  end)

  vim.ui.select(items, {
    prompt = "Select Scratch Buffer:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      M.show_scratch(choice.id)
    end
  end)
end

-- Create named scratch buffer
---@param name? string
---@param filetype? string
---@return nil
function M.create_named_scratch(name, filetype)
  if not name then
    M.input({ prompt = "Scratch buffer name: " }, function(input_name)
      if input_name and input_name ~= "" then
        M.input({ prompt = "Filetype (optional): " }, function(input_ft)
          M.show_scratch(input_name, { filetype = input_ft ~= "" and input_ft or nil })
        end)
      end
    end)
    return
  end

  M.show_scratch(name, { filetype = filetype })
end

-- Toggle scratch buffer (show/hide current)
---@return nil
function M.toggle_scratch()
  if M.current_scratch then
    local scratch_buf = M.scratch_buffers[M.current_scratch]
    if scratch_buf and scratch_buf.window and vim.api.nvim_win_is_valid(scratch_buf.window) then
      -- Currently visible, hide it
      vim.api.nvim_win_close(scratch_buf.window, false)
      scratch_buf.window = nil
    else
      -- Not visible, show it
      M.show_scratch(M.current_scratch)
    end
  else
    -- No current scratch, create default
    M.show_scratch("default")
  end
end

-- Quick access to numbered scratch buffers
---@param num integer
---@param filetype? string
---@return nil
function M.scratch_number(num, filetype)
  local name = "scratch" .. num
  M.show_scratch(name, { filetype = filetype })
end

-- Copy current buffer content to scratch
---@param scratch_name? string
---@return nil
function M.copy_to_scratch(scratch_name)
  local current_buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local current_ft = vim.bo[current_buf].filetype

  scratch_name = scratch_name or "copied"

  local scratch_buf = M.get_or_create_scratch({
    name = scratch_name,
    filetype = current_ft,
    content = lines,
  })

  M.show_scratch(scratch_name, { split = "vsplit" })
  vim.notify("Copied " .. #lines .. " lines to scratch buffer '" .. scratch_name .. "'")
end

return M
