extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme: ThemeConfig = load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	if theme != null:
		passed = passed and _assert_true(theme.pipe_i_texture != null, "Cyber theme should load pipe I texture for sprite draw pass")
		passed = passed and _assert_true(theme.pipe_l_texture != null, "Cyber theme should load pipe L texture for sprite draw pass")
		passed = passed and _assert_true(theme.pipe_t_texture != null, "Cyber theme should load pipe T texture for sprite draw pass")
		passed = passed and _assert_true(theme.pipe_x_texture != null, "Cyber theme should load pipe X texture for sprite draw pass")
		for mode in ["dark", "light"]:
			var texture: Texture2D = theme.get_cell_bg_texture_for_mode(mode)
			passed = passed and _assert_true(texture != null, "%s gameplay cell texture should load" % mode)
			if texture != null:
				var image := texture.get_image()
				passed = passed and _assert_true(image != null, "%s gameplay cell texture should expose image" % mode)
				if image != null:
					var center := image.get_pixel(image.get_width() / 2, image.get_height() / 2)
					if mode == "dark":
						passed = passed and _assert_true(center.get_luminance() < 0.35, "Dark gameplay cell texture should be visually dark")
					else:
						passed = passed and _assert_true(center.get_luminance() > 0.65, "Light gameplay cell texture should be visually light")

	if passed:
		print("test_gameplay_cell_texture_runtime_load: PASS")
		quit(0)
	else:
		print("test_gameplay_cell_texture_runtime_load: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
