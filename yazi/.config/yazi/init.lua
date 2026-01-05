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
