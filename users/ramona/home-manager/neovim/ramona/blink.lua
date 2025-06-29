local blink = require("blink-cmp")
blink.keymap = {
	preset = "enter",
	["<C-Space>"] = false,
	["<C-p>"] = {
		function(cmp)
			cmp.show()
		end,
	},
}
