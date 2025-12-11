-- Persistent, project-aware scratch buffers with optional floating layout and simple code runners.

local uv = vim.uv or vim.loop

---@class ScratchMeta
---@field key string
---@field name string
---@field filetype string
---@field file string
---@field meta_file string
---@field cwd? string
---@field branch? string
---@field count? integer
---@field id? string

---@class ScratchBuffer
---@field key string
---@field buffer integer
---@field name string
---@field filetype string
---@field file string
---@field window integer?
---@field meta ScratchMeta
---@field output_buf? integer
---@field output_win? integer

---@class ScratchConfig
---@field name? string
---@field id? string
---@field filetype? string
---@field content? string[]
---@field split? string
---@field layout? "current"|"split"|"vsplit"|"tab"|"float"
---@field float_opts? table
---@field focus? boolean
---@field cwd? string
---@field branch? string
---@field count? integer
---@field replace_content? boolean
---@field autowrite? boolean

local has_snacks, Snacks = pcall(require, "snacks")
local scratch_mod = has_snacks and require("snacks.scratch") or nil
local scratch_cfg = has_snacks and Snacks.config.get("scratch") or {}

---@class ScratchManager
local M = {}

local defaults = {
  root = scratch_cfg.root or vim.fn.stdpath("data") .. "/scratch",
  layout = "current",
  autowrite = true,
  float = { width = 0.55, height = 0.6, border = "rounded" },
  filekey = scratch_cfg.filekey or {
    id = nil,
    cwd = true,
    branch = true,
    count = true,
  },
}

local layout_cycle = { "current", "vsplit", "split", "float", "tab" }

local function next_layout(current)
  local idx = 1
  for i, name in ipairs(layout_cycle) do
    if name == current then
      idx = i
      break
    end
  end
  idx = (idx % #layout_cycle) + 1
  return layout_cycle[idx]
end

---@type fun(opts: table, on_confirm: fun(input: string?)): nil
M.input = (has_snacks and Snacks.input and Snacks.input.input) and Snacks.input.input or vim.ui.input

-- State
---@type table<string, ScratchBuffer>
M.scratch_buffers = {}
---@type string?
M.current_scratch = nil
M.layout = defaults.layout
M.last_layout_index = 1

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
  typ = "typst",
}

---@type table<string, string>
local filetype_to_extension = {
  typst = "typ",
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

local function normalize(path)
  return path and vim.fs.normalize(path) or path
end

-- Detect filetype from content
---@param lines string[]
---@return string?
local function detect_filetype_from_content(lines)
  if not lines or #lines == 0 then
    return nil
  end

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

local function get_extension(name)
  return string.match(name or "", "%.([^%.]+)$")
end

local function extension_for_ft(ft)
  return filetype_to_extension[ft] or ft or "txt"
end

local function filter_parts(tbl)
  local ret = {}
  for _, value in ipairs(tbl) do
    if value and value ~= "" then
      ret[#ret + 1] = value
    end
  end
  return ret
end

local function resolve_filetype(config)
  if config.filetype and config.filetype ~= "" then
    return config.filetype
  end
  local ext = get_extension(config.name)
  if ext and M.extension_to_filetype[ext] then
    return M.extension_to_filetype[ext]
  end
  if config.content then
    local detected = detect_filetype_from_content(config.content)
    if detected then
      return detected
    end
  end
  if vim.bo.filetype and vim.bo.filetype ~= "" then
    return vim.bo.filetype
  end
  return "markdown"
end

local function install_autowrite(buf, meta, autowrite)
  if not autowrite then
    return
  end
  local group = vim.api.nvim_create_augroup("mnf_scratch_autowrite_" .. buf, { clear = true })
  local function write()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local dir = vim.fs.dirname(meta.file)
    if dir and dir ~= "" then
      vim.fn.mkdir(dir, "p")
    end
    vim.api.nvim_buf_call(buf, function()
      pcall(vim.cmd.write)
      vim.bo[buf].buflisted = false
    end)
  end
  vim.api.nvim_create_autocmd(
    { "BufHidden", "BufLeave", "VimLeavePre" },
    { group = group, buffer = buf, callback = write }
  )
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      M.scratch_buffers[meta.file] = nil
      if M.current_scratch == meta.file then
        M.current_scratch = nil
      end
    end,
  })
end

local function build_meta(config)
  if not scratch_mod then
    error("Snacks.nvim is required for scratch persistence")
  end

  config = config or {}
  local ft = resolve_filetype(config)
  local ext = extension_for_ft(ft)

  local opts = {
    name = config.name or "Scratch",
    ft = ext,
    id = config.id or defaults.filekey.id,
    file = config.file,
    filekey = defaults.filekey,
    root = defaults.root,
  }

  -- Allow explicit overrides; Snacks will compute when nil.
  if config.cwd then
    opts.cwd = config.cwd
  end
  if config.branch then
    opts.branch = config.branch
  end
  if config.count then
    opts.count = config.count
  end

  local meta = scratch_mod.get(opts)
  meta.filetype = ft
  meta.ft = ext
  meta.meta_file = meta.file .. ".meta"
  return meta
end

local function ensure_buffer(meta, config)
  local buf = vim.fn.bufadd(meta.file)
  vim.fn.bufload(buf)
  vim.api.nvim_buf_set_name(buf, meta.file)

  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = meta.filetype

  local line_count = vim.api.nvim_buf_line_count(buf)
  local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  local is_blank = line_count == 1 and (first_line == nil or first_line == "")

  if config.content and (config.replace_content or is_blank) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, config.content)
  end

  return buf
end

local function line_count_for(meta, scratch)
  if scratch and vim.api.nvim_buf_is_valid(scratch.buffer) then
    return vim.api.nvim_buf_line_count(scratch.buffer)
  end
  local ok, lines = pcall(vim.fn.readfile, meta.file)
  return ok and #lines or 0
end

local function longest_line_length(lines)
  local longest = 0
  for _, line in ipairs(lines) do
    if #line > longest then
      longest = #line
    end
  end
  return longest
end

local function float_size(opts, line_count, longest)
  local width = opts.width or defaults.float.width
  local height = opts.height or defaults.float.height
  width = width < 1 and math.floor(vim.o.columns * width) or width
  height = height < 1 and math.floor(vim.o.lines * height) or height
  width = math.min(vim.o.columns - 4, math.max(30, longest + 4, width))
  height = math.min(vim.o.lines - 4, math.max(6, line_count + 2, height))
  return width, height
end

local function find_by_buf(bufnr)
  for key, scratch in pairs(M.scratch_buffers) do
    if scratch.buffer == bufnr then
      return scratch, key
    end
  end
  return nil, nil
end

local runners = {
  lua = function(scratch)
    return { cmd = { "lua", scratch.file }, label = "lua" }
  end,
  python = function(scratch)
    return { cmd = { "python3", scratch.file }, label = "python" }
  end,
  sh = function(scratch)
    return { cmd = { "bash", scratch.file }, label = "shell" }
  end,
  bash = function(scratch)
    return { cmd = { "bash", scratch.file }, label = "shell" }
  end,
}

-- Get or create a scratch buffer
---@param config ScratchConfig
---@return ScratchBuffer
function M.get_or_create_scratch(config)
  config = config or {}
  local meta = build_meta(config)

  local key = meta.file
  local existing = M.scratch_buffers[key]
  if existing and vim.api.nvim_buf_is_valid(existing.buffer) then
    if config.content and config.replace_content then
      vim.api.nvim_buf_set_lines(existing.buffer, 0, -1, false, config.content)
    end
    M.current_scratch = key
    return existing
  end

  local buf = ensure_buffer(meta, config)
  --install_autowrite(buf, meta, config.autowrite ~= false and defaults.autowrite)

  local scratch_buf = {
    key = key,
    buffer = buf,
    name = meta.name,
    filetype = meta.filetype,
    file = meta.file,
    meta = meta,
    window = nil,
    layout = config.layout or M.layout or defaults.layout,
  }

  M.scratch_buffers[key] = scratch_buf
  M.current_scratch = key
  return scratch_buf
end

-- Show scratch buffer in window
---@param scratch_id string
---@param config? ScratchConfig
function M.show_scratch(scratch_id, config)
  config = config or {}
  config.name = scratch_id or config.name

  local scratch_buf = M.get_or_create_scratch(config)

  local layout = config.layout or config.split or scratch_buf.layout or M.layout or defaults.layout
  scratch_buf.layout = layout

  local win
  local existing_win = scratch_buf.window

  if existing_win and vim.api.nvim_win_is_valid(existing_win) and layout == "current" then
    win = existing_win
    vim.api.nvim_set_current_win(win)
  elseif existing_win and vim.api.nvim_win_is_valid(existing_win) then
    pcall(vim.api.nvim_win_close, existing_win, false)
  end

  if not win and layout == "vsplit" then
    vim.cmd("vsplit")
    win = vim.api.nvim_get_current_win()
  elseif not win and layout == "split" then
    vim.cmd("split")
    win = vim.api.nvim_get_current_win()
  elseif not win and layout == "tab" then
    vim.cmd("tab split")
    win = vim.api.nvim_get_current_win()
  elseif not win and layout == "float" then
    local lines = vim.api.nvim_buf_get_lines(scratch_buf.buffer, 0, -1, false)
    local width, height = float_size(config.float_opts or {}, #lines, longest_line_length(lines))
    win = vim.api.nvim_open_win(scratch_buf.buffer, true, {
      relative = "editor",
      style = "minimal",
      border = (config.float_opts or {}).border or defaults.float.border,
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      title = (" Scratch: %s "):format(scratch_buf.name),
      title_pos = "center",
    })
  elseif not win then
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, scratch_buf.buffer)
  end

  if layout ~= "float" then
    vim.api.nvim_win_set_buf(win, scratch_buf.buffer)
  end

  scratch_buf.window = win

  if config.focus ~= false then
    vim.api.nvim_set_current_win(win)
  end

  M.current_scratch = scratch_buf.key

  if not vim.b[scratch_buf.buffer].mnf_scratch_layout_map then
    vim.keymap.set("n", "'f", function()
      require("mnf.scratch").cycle_layout(scratch_buf.name)
    end, { buffer = scratch_buf.buffer, desc = "Cycle scratch layout" })
    vim.b[scratch_buf.buffer].mnf_scratch_layout_map = true
  end
end

-- Close scratch buffer
---@param scratch_id string
function M.close_scratch(scratch_id)
  for key, scratch_buf in pairs(M.scratch_buffers) do
    if scratch_buf.name == scratch_id or key == scratch_id then
      if scratch_buf.window and vim.api.nvim_win_is_valid(scratch_buf.window) then
        vim.api.nvim_win_close(scratch_buf.window, false)
      end
      if vim.api.nvim_buf_is_valid(scratch_buf.buffer) then
        vim.api.nvim_buf_delete(scratch_buf.buffer, { force = true })
      end
      M.scratch_buffers[key] = nil
      if M.current_scratch == key then
        M.current_scratch = nil
      end
      break
    end
  end
end

local function project_metas()
  if not scratch_mod then
    return {}
  end
  local list = scratch_mod.list()
  for _, meta in ipairs(list) do
    meta.filetype = meta.filetype or M.extension_to_filetype[meta.ft] or meta.ft
    meta.meta_file = meta.file .. ".meta"
  end
  return list
end

-- List all scratch buffers (including persisted for this project)
function M.list_scratches()
  if scratch_mod and scratch_mod.select then
    scratch_mod.select()
    return
  end

  -- Fallback: minimal list via ui.select
  local items = {}
  local metas = project_metas()
  for _, meta in ipairs(metas) do
    local scratch = M.scratch_buffers[meta.file]
    local line_count = line_count_for(meta, scratch)
    local is_current = (M.current_scratch == meta.file) and "● " or "  "
    local branch = meta.branch and (" [" .. meta.branch .. "]") or ""
    table.insert(items, {
      display = string.format("%s%s (%s)%s - %d lines", is_current, meta.name, meta.filetype, branch, line_count),
      meta = meta,
    })
  end
  if #items == 0 then
    vim.notify("No scratch buffers available", vim.log.levels.WARN)
    return
  end
  vim.ui.select(items, {
    prompt = "Select Scratch Buffer:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice and choice.meta then
      M.show_scratch(choice.meta.name, {
        filetype = choice.meta.filetype,
        id = choice.meta.id,
        cwd = choice.meta.cwd,
        branch = choice.meta.branch,
        count = choice.meta.count,
      })
    end
  end)
end

-- Create named scratch buffer
---@param name? string
---@param filetype? string
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
function M.toggle_scratch()
  if M.current_scratch then
    local scratch_buf = M.scratch_buffers[M.current_scratch]
    if scratch_buf and scratch_buf.window and vim.api.nvim_win_is_valid(scratch_buf.window) then
      vim.api.nvim_win_close(scratch_buf.window, false)
      scratch_buf.window = nil
      return
    end
    if scratch_buf then
      M.show_scratch(scratch_buf.name)
      return
    end
  end
  M.show_scratch("default")
end

-- Quick access to numbered scratch buffers
---@param num integer
---@param filetype? string
function M.scratch_number(num, filetype)
  local name = "scratch" .. num
  M.show_scratch(name, { filetype = filetype })
end

-- Copy current buffer content to scratch
---@param scratch_name? string
function M.copy_to_scratch(scratch_name)
  local current_buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local current_ft = vim.bo[current_buf].filetype

  scratch_name = scratch_name or "copied"

  M.get_or_create_scratch({
    name = scratch_name,
    filetype = current_ft,
    content = lines,
    replace_content = true,
  })

  M.show_scratch(scratch_name, { split = "vsplit" })
  vim.notify("Copied " .. #lines .. " lines to scratch buffer '" .. scratch_name .. "'")
end

function M.cycle_layout(name)
  local scratch = nil
  if name then
    scratch = M.get_or_create_scratch({ name = name })
  else
    scratch = (M.current_scratch and M.scratch_buffers[M.current_scratch])
      or select(1, find_by_buf(vim.api.nvim_get_current_buf()))
  end
  if not scratch then
    vim.notify("No scratch buffer to cycle layout", vim.log.levels.WARN)
    return
  end
  local current = scratch.layout or M.layout or defaults.layout
  local new_layout = next_layout(current)
  scratch.layout = new_layout
  M.layout = new_layout
  M.show_scratch(scratch.name, { layout = new_layout, filetype = scratch.filetype, id = scratch.meta.id })
end

function M.set_layout(layout)
  if not layout then
    return
  end
  M.layout = layout
  if M.current_scratch then
    local scratch = M.scratch_buffers[M.current_scratch]
    if scratch then
      scratch.layout = layout
      M.show_scratch(scratch.name, { layout = layout, filetype = scratch.filetype, id = scratch.meta.id })
    end
  end
end

function M.toggle_layout()
  return M.cycle_layout()
end

local function show_output(scratch, lines, title)
  if not scratch.output_buf or not vim.api.nvim_buf_is_valid(scratch.output_buf) then
    scratch.output_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[scratch.output_buf].buflisted = false
    vim.bo[scratch.output_buf].filetype = "log"
    vim.bo[scratch.output_buf].buftype = "nofile"
    vim.bo[scratch.output_buf].swapfile = false
  end

  vim.api.nvim_buf_set_lines(scratch.output_buf, 0, -1, false, lines)

  local width, height = float_size({ width = 0.5, height = 0.3 }, #lines, longest_line_length(lines))
  local win = scratch.output_win
  if not win or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_open_win(scratch.output_buf, false, {
      relative = "editor",
      style = "minimal",
      border = "single",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      title = title or "Scratch Run",
      title_pos = "center",
    })
  else
    vim.api.nvim_win_set_buf(win, scratch.output_buf)
    vim.api.nvim_win_set_height(win, height)
    vim.api.nvim_win_set_width(win, width)
  end
  scratch.output_win = win
end

-- Run the current scratch buffer (lua/python/sh)
---@param scratch_name? string
function M.run_scratch(scratch_name)
  local scratch = nil
  if scratch_name then
    scratch = M.get_or_create_scratch({ name = scratch_name })
  else
    scratch = M.scratch_buffers[M.current_scratch or ""] or select(1, find_by_buf(vim.api.nvim_get_current_buf()))
  end

  if not scratch then
    vim.notify("No scratch buffer to run", vim.log.levels.WARN)
    return
  end

  if not vim.api.nvim_buf_is_valid(scratch.buffer) then
    vim.notify("Scratch buffer is not valid", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_call(scratch.buffer, function()
    pcall(vim.cmd.write)
  end)

  local ft = scratch.filetype or vim.bo[scratch.buffer].filetype
  local runner = runners[ft]
  if not runner then
    vim.notify("No runner configured for filetype '" .. ft .. "'", vim.log.levels.WARN)
    return
  end

  local job = runner(scratch)
  if not job or not job.cmd then
    vim.notify("Runner for '" .. ft .. "' is misconfigured", vim.log.levels.ERROR)
    return
  end

  vim.system(job.cmd, { text = true }, function(res)
    local output = {}
    if res.stdout and res.stdout ~= "" then
      vim.list_extend(output, vim.split(res.stdout, "\n", { plain = true }))
    end
    if res.stderr and res.stderr ~= "" then
      vim.list_extend(output, vim.split(res.stderr, "\n", { plain = true }))
    end
    output[#output + 1] = ("[exit %d]"):format(res.code or -1)
    vim.schedule(function()
      show_output(scratch, output, "Run " .. (job.label or ft))
    end)
  end)
end

return M
