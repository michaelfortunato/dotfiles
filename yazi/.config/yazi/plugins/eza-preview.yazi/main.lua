--- @since 25.5.31

local M = {}

local function fail(s, ...)
	ya.err({ title = "Eza Preview", content = string.format(s, ...), timeout = 5 })
end

local function folder_peek(job)
	local folder = cx.active.preview.folder
	if not folder then
		return ya.preview_widget(job, ui.Line("Loading..."):area(job.area):align(ui.Align.CENTER))
	elseif folder.cwd ~= job.file.url then
		return
	end

	local bound = math.max(0, #folder.files - job.area.h)
	if job.skip > bound then
		return ya.emit("peek", { bound, only_if = job.file.url, upper_bound = true })
	end

	if #folder.files == 0 then
		local done, err = folder.stage()
		local s = not done and "Loading..." or not err and "No items" or string.format("Error: %s", err)
		return ya.preview_widget(job, ui.Text(s):area(job.area):align(ui.Align.CENTER):wrap(ui.Wrap.YES))
	end

	local left, right = {}, {}
	for _, f in ipairs(folder.window) do
		local entity = Entity:new(f)
		left[#left + 1], right[#right + 1] = entity:redraw(), Linemode:new(f):redraw()

		local max = math.max(0, job.area.w - right[#right]:width())
		left[#left]:truncate { max = max, ellipsis = entity:ellipsis(max) }
	end

	ya.preview_widget(job, {
		ui.List(left):area(job.area),
		ui.Text(right):area(job.area):align(ui.Align.RIGHT),
		table.unpack(Marker:new(job.area, folder):redraw()),
	})
end

local function get_or_init_state(state)
	if state.initialized then
		return
	end
	state.opts = {
		level = 3,
		follow_symlinks = true,
		dereference = false,
		all = true,
		ignore_glob = {},
		git_ignore = true,
		git_status = false,
		icons = true,
	}
	state.tree = true
	state.level_override = nil
	state.initialized = true
end

local function apply_config(state, user_config)
	get_or_init_state(state)
	user_config = user_config or {}
	for key, value in pairs(user_config) do
		if key == "default_tree" then
			state.tree = value
		elseif state.opts[key] ~= nil then
			state.opts[key] = value
		end
	end
end

function M:setup(user_config)
	apply_config(self, user_config)
end

local is_tree_view_mode = ya.sync(function(state, _)
	get_or_init_state(state)
	return state.tree
end)

local get_opts = ya.sync(function(state)
	get_or_init_state(state)
	return state.opts
end)

local toggle_view_mode = ya.sync(function(state, _)
	get_or_init_state(state)
	state.tree = not state.tree
end)

local inc_level = ya.sync(function(state)
	get_or_init_state(state)
	state.opts.level = state.opts.level + 1
end)

local dec_level = ya.sync(function(state)
	get_or_init_state(state)
	if state.opts.level > 1 then
		state.opts.level = state.opts.level - 1
	end
end)

local get_level_override = ya.sync(function(state)
	get_or_init_state(state)
	return state.level_override
end)

local cycle_level = ya.sync(function(state)
	get_or_init_state(state)

	-- Cycle: off (list) -> base level -> 6 -> full -> off ...
	if not state.tree then
		state.tree = true
		state.level_override = nil
	elseif state.level_override == nil then
		state.level_override = 6
	elseif state.level_override == 6 then
		state.level_override = "full"
	else
		state.tree = false
		state.level_override = nil
	end
end)

local cycle_level_rev = ya.sync(function(state)
	get_or_init_state(state)

	-- Cycle (reverse): off (list) -> full -> 6 -> base level -> off ...
	if not state.tree then
		state.tree = true
		state.level_override = "full"
	elseif state.level_override == nil then
		state.tree = false
		state.level_override = nil
	elseif state.level_override == 6 then
		state.level_override = nil
	else
		state.level_override = 6
	end
end)

local toggle_follow_symlinks = ya.sync(function(state)
	get_or_init_state(state)
	state.opts.follow_symlinks = not state.opts.follow_symlinks
end)

local toggle_hidden = ya.sync(function(state)
	get_or_init_state(state)
	state.opts.all = not state.opts.all
end)

local toggle_git_ignore = ya.sync(function(state)
	get_or_init_state(state)
	state.opts.git_ignore = not state.opts.git_ignore
end)

local toggle_git_status = ya.sync(function(state)
	get_or_init_state(state)
	state.opts.git_status = not state.opts.git_status
end)

function M:entry(job)
	local args = string.gsub(job.args[1] or "", "^%s*(.-)%s*$", "%1")
	if args == "inc-level" then
		inc_level()
	elseif args == "dec-level" then
		dec_level()
	elseif args == "cycle-level" then
		cycle_level()
	elseif args == "cycle-level-rev" then
		cycle_level_rev()
	elseif args == "toggle-follow-symlinks" then
		toggle_follow_symlinks()
	elseif args == "toggle-hidden" then
		toggle_hidden()
	elseif args == "toggle-git-ignore" then
		toggle_git_ignore()
	elseif args == "toggle-git-status" then
		toggle_git_status()
	else
		toggle_view_mode()
	end
	ya.emit("seek", { 0 })
end

function M:peek(job)
	local opts = get_opts()
	local is_tree = is_tree_view_mode()
	local level_override = get_level_override()
	local args = {
		"--color=always",
		"--group-directories-first",
		"--no-quotes",
		tostring(job.file.url),
	}
	if is_tree then
		table.insert(args, "--tree")
		if level_override ~= "full" then
			local level = level_override or opts.level
			table.insert(args, string.format("--level=%d", level))
		end
	end
	if opts then
		if opts.icons then
			table.insert(args, "--icons=always")
		end
		if opts.follow_symlinks then
			table.insert(args, "--follow-symlinks")
		end
		if opts.all then
			table.insert(args, "--all")
		end
		if opts.dereference then
			table.insert(args, "--dereference")
		end
		if opts.git_status then
			table.insert(args, "--long")
			table.insert(args, "--no-permissions")
			table.insert(args, "--no-user")
			table.insert(args, "--no-time")
			table.insert(args, "--no-filesize")
			table.insert(args, "--git")
			table.insert(args, "--git-repos")
		end
		if opts.git_ignore then
			table.insert(args, "--git-ignore")
		end
		if opts.ignore_glob and type(opts.ignore_glob) == "table" and #opts.ignore_glob > 0 then
			local pattern_str = table.concat(opts.ignore_glob, "|")
			table.insert(args, "-I")
			table.insert(args, pattern_str)
		elseif opts.ignore_glob and type(opts.ignore_glob) == "string" and opts.ignore_glob ~= "" then
			table.insert(args, "-I")
			table.insert(args, opts.ignore_glob)
		end
	end
	local child, err = Command("eza"):arg(args):stdout(Command.PIPED):stderr(Command.PIPED):spawn()
	if not child then
		fail("Cannot run `eza`: %s", err)
		return folder_peek(job)
	end
	local limit = job.area.h
	local lines = ""
	local num_lines = 1
	local num_skip = 0
	local empty_output = false
	local read_err = nil
	repeat
		local line, event = child:read_line()
		if event == 1 then
			read_err = tostring(line or event)
			break
		elseif event ~= 0 then
			break
		end
		if num_skip >= job.skip then
			lines = lines .. line
			num_lines = num_lines + 1
		else
			num_skip = num_skip + 1
		end
	until num_lines >= limit
	if read_err then
		fail("Failed to read `eza` output: %s", read_err)
		child:start_kill()
		return
	end

	if num_lines == 1 and not is_tree then
		empty_output = true
	elseif num_lines == 2 and is_tree then
		empty_output = true
	end
	child:start_kill()
	if job.skip > 0 and num_lines < limit then
		ya.emit("peek", {
			tostring(math.max(0, job.skip - (limit - num_lines))),
			only_if = tostring(job.file.url),
			upper_bound = "",
		})
	elseif empty_output then
		ya.preview_widget(job, {
			ui.Text({ ui.Line("No items") }):area(job.area):align(ui.Text.CENTER),
		})
	else
		ya.preview_widget(job, {
			ui.Text.parse(lines):area(job.area),
		})
	end
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		local step = math.floor(job.units * job.area.h / 10)
		ya.emit("peek", {
			math.max(0, cx.active.preview.skip + step),
			only_if = tostring(job.file.url),
			force = true,
		})
	end
end

return M
