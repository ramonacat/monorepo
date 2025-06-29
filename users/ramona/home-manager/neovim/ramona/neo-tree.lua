require("neo-tree").setup({
	filesystem = {
		follow_current_file = {
			enabled = true,
		},
		filtered_items = {
			always_show = {
				".github",
				".gitignore",
			},
		},
	},
})
