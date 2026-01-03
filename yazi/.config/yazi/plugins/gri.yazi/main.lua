local M = {}

local state = ya.sync(function()
	local selected = {}
	for _, url in pairs(cx.active.selected) do
		selected[#selected + 1] = url
	end
	return cx.active.current.cwd, selected
end)

function M:entry()
	ya.emit("escape", { visual = true })

	local cwd, selected = state()
	if cwd.scheme.is_virtual then
		return ya.notify({
			title = "Fzf",
			content = "Not supported under virtual filesystems",
			timeout = 5,
			level = "warn",
		})
	end

	local _permit = ui.hide()
	local output, err = M.run_with(cwd, selected)
	if not output then
		return ya.notify({ title = "gri", content = tostring(err), timeout = 5, level = "error" })
	end

	local line = output:match("([^\r\n]+)")
	if not line or line == "" then
		return
	end

	local file, lnum = line:match("^([^:]+):(%d+):")
	if not file or not lnum then
		return
	end

	local url = Url(file)
	if not url.is_absolute then
		url = cwd:join(url)
	end

	ya.emit("reveal", { url, raw = true })
	ya.emit("shell", {
		string.format("nvim %s +%s", ya.quote(tostring(url)), lnum),
		block = true,
		confirm = true,
	})
end

function M.run_with(cwd, selected)
	local rg_prefix = "rg --column --line-number --no-heading --color=always --smart-case"
	local rg = rg_prefix .. " {q}"
	if #selected > 0 then
		local args = { rg_prefix, "{q}", "--" }
		for _, u in ipairs(selected) do
			args[#args + 1] = ya.quote(tostring(u))
		end
		rg = table.concat(args, " ")
	end

	local child, err = Command("fzf")
		:arg({
			"--ansi",
			"--disabled",
			"--query",
			"",
			"--bind",
			"start:reload:" .. rg .. " || true",
			"--bind",
			"change:reload:sleep 0.1; " .. rg .. " || true",
			"--bind",
			"alt-enter:unbind(change,alt-enter)+change-prompt(2. fzf> )+enable-search+clear-query",
			"--color",
			"hl:-1:underline,hl+:-1:underline:reverse",
			"--cycle",
			"--prompt",
			"1. ripgrep> ",
			"--delimiter",
			":",
			"--preview",
			"bat --color=always {1} --highlight-line {2}",
			"--preview-window",
			"up,60%,border-bottom,+{2}+3/3,~3",
			"--bind",
			"ctrl-y:accept",
		})
		:cwd(tostring(cwd))
		:stdin(Command.INHERIT)
		:stdout(Command.PIPED)
		:spawn()

	if not child then
		return nil, Err("Failed to start `fzf`, error: %s", err)
	end

	local output, err = child:wait_with_output()
	if not output then
		return nil, Err("Cannot read `fzf` output, error: %s", err)
	elseif not output.status.success and output.status.code ~= 130 then
		return nil, Err("`fzf` exited with error code %s", output.status.code)
	end
	return output.stdout, nil
end

function M.split_urls(cwd, output)
	local t = {}
	for line in output:gmatch("[^\r\n]+") do
		local u = Url(line)
		if u.is_absolute then
			t[#t + 1] = u
		else
			t[#t + 1] = cwd:join(u)
		end
	end
	return t
end

return M
