function Status:mode()
	-- Ref: https://github.com/sxyazi/yazi/blob/577065cbd05a282a1d6f923c89cdf74d5af2f3e9/yazi-plugin/preset/components/status.lua#L39-L48
	-- local mode = tostring(self._tab.mode):sub(1, 3):upper()
	local mode = tostring(self._tab.mode):upper() -- removed :sub(1, 3)

	local style = self:style()
	return ui.Line({
		ui.Span(th.status.sep_left.open):fg(style.main:bg()):bg("reset"),
		ui.Span(" " .. mode .. " "):style(style.main),
		ui.Span(th.status.sep_left.close):fg(style.main:bg()):bg(style.alt:bg()),
	})
end

require("eza-preview"):setup({
	-- Start in list mode; use L to toggle tree view.
	default_tree = false,
})

-- This was good and robust, but we need yazi to emit tui=0 on shutdown
-- REALLY Yazi does this all CORRECTLY by emitting the CSI alternate screen
-- code but neovim has no way of intercepting those events in a term://*
-- buffer.
-- So right now we will have a custom apc code that neovim listens
-- for in autocmds.lua. Leaving the original code here for future me
-- if interested.
--
-- local ESC = string.char(27)
-- local BEL = string.char(7)
-- local ST = ESC .. "\\" -- ESC \  (note: backslash escaped for Lua string)
--
-- local function send_osc(payload)
-- 	io.stdout:write(ESC .. "]" .. payload .. BEL) -- simplest: BEL-terminated
-- 	io.stdout:flush()
-- end
--
-- local function send_apc(payload)
-- 	io.stdout:write(ESC .. "_" .. payload .. ST) -- ST-terminated
-- 	io.stdout:flush()
-- end
--
-- local function send_dcs(payload)
-- 	io.stdout:write(ESC .. "P" .. payload .. ST) -- ST-terminated
-- 	io.stdout:flush()
-- end
--
-- if os.getenv("NVIM") then
-- 	send_apc("yazi:tui=1")
-- end
