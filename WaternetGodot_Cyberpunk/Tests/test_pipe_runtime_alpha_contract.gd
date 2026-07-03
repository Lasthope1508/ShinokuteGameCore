extends SceneTree

const TEXTURES := [
	"res://Assets/Themes/cyberpunk_theme/i_slices/i_slice_0.png",
	"res://Assets/Themes/cyberpunk_theme/l_slices/l_slice_0.png",
	"res://Assets/Themes/cyberpunk_theme/t_slices/t_slice_0.png",
	"res://Assets/Themes/cyberpunk_theme/cross_slices/cross_slice_0.png"
]

func _init() -> void:
	var passed := true
	for path in TEXTURES:
		var texture: Texture2D = load(path)
		passed = passed and _assert_true(texture != null, "%s should load" % path)
		if texture != null:
			var image := texture.get_image()
			passed = passed and _assert_true(image != null, "%s should expose image" % path)
			if image != null:
				var corner := image.get_pixel(0, 0)
				passed = passed and _assert_true(corner.a < 0.01, "%s corner should stay transparent after import" % path)
	if passed:
		print("test_pipe_runtime_alpha_contract: PASS")
		quit(0)
	else:
		print("test_pipe_runtime_alpha_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
