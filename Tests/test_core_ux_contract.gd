extends SceneTree

const SceneRouterScript := preload("res://addons/shinokute_game_core/ux/scene_router.gd")
const OverlayManagerScript := preload("res://addons/shinokute_game_core/ux/overlay_manager.gd")
const SceneTransitionScript := preload("res://addons/shinokute_game_core/ux/scene_transition_lifecycle.gd")
const OverlayPresentationPath := "res://addons/shinokute_game_core/ux/overlay_presentation_core.gd"

var _passed := true
var _routes: Array = []
var _overlays: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var router = SceneRouterScript.new()
	root.add_child(router)
	router.route_requested.connect(func(key: String, path: String, payload: Dictionary): _routes.append({"key": key, "path": path, "payload": payload}))
	router.configure({"menu": "res://Scenes/Menu.tscn", "game": "res://Scenes/Game.tscn"})
	_assert_eq(router.get_scene_path("game"), "res://Scenes/Game.tscn", "scene path lookup")
	_assert_eq(router.request_route("game", {"mode": "classic"}), OK, "route request OK")
	_assert_eq(_routes[0]["key"], "game", "route signal key")
	_assert_eq(_routes[0]["payload"]["mode"], "classic", "route payload")
	_assert_eq(router.request_route("missing"), ERR_DOES_NOT_EXIST, "missing route error")

	var overlay = OverlayManagerScript.new()
	root.add_child(overlay)
	overlay.overlay_requested.connect(func(key: String, payload: Dictionary): _overlays.append({"key": key, "payload": payload}))
	overlay.configure({"settings": "res://Settings.tscn"})
	_assert_true(overlay.has_overlay("settings"), "overlay registry")
	_assert_eq(overlay.request_overlay("settings", {"tab": "audio"}), OK, "overlay request OK")
	_assert_eq(_overlays[0]["payload"]["tab"], "audio", "overlay payload")
	_assert_eq(overlay.request_overlay("missing"), ERR_DOES_NOT_EXIST, "missing overlay error")

	var transition = SceneTransitionScript.new()
	transition.configure({"game": "res://Scenes/Game.tscn"})
	_assert_eq(transition.request_transition("game", {"fade_out": 0.2, "fade_in": 0.2}), {"status": "queued", "key": "game", "path": "res://Scenes/Game.tscn", "closed": []}, "scene transition queues route")
	_assert_eq(transition.request_transition("game", {}), {"status": "blocked", "reason": "active_transition", "active": "game", "closed": []}, "scene transition blocks duplicate request")
	_assert_eq(transition.advance(0.2).get("phase", ""), "fade_out", "scene transition advances to fade out")
	_assert_eq(transition.advance(0.2).get("phase", ""), "change_scene", "scene transition advances to change scene")
	_assert_eq(transition.advance(0.2).get("phase", ""), "fade_in", "scene transition advances to fade in")
	_assert_eq(transition.advance(0.2).get("phase", ""), "idle", "scene transition returns to idle")
	_assert_eq(transition.request_transition("missing"), {"status": "blocked", "reason": "missing_route", "closed": []}, "scene transition blocks missing route")
	_test_overlay_presentation_core()
	_report("test_core_ux_contract")

func _test_overlay_presentation_core() -> void:
	var script: Script = load(OverlayPresentationPath)
	_assert_true(script != null, "overlay presentation script loads")
	if script == null:
		return
	var presentation = script.new()
	var panel: Dictionary = presentation.resolve_panel({
		"viewport_size": Vector2(480.0, 270.0),
		"owner_rect": Vector4(0.0, 0.0, 600.0, 440.0),
		"viewport_margin": 18.0
	})
	_assert_eq(Vector2(panel.get("size", Vector2.ZERO)), Vector2(444.0, 234.0), "overlay panel clamps to viewport margin")
	_assert_eq(Rect2(panel.get("rect", Rect2())).position, Vector2(18.0, 18.0), "overlay panel centers after clamp")
	_assert_true(bool(panel.get("clamped", false)), "overlay panel reports clamp")
	var content: Dictionary = presentation.resolve_content({
		"panel_rect": panel.get("rect", Rect2()),
		"content_margin": Vector4(18.0, 12.0, 18.0, 12.0)
	})
	_assert_eq(Rect2(content.get("rect", Rect2())).size, Vector2(408.0, 210.0), "overlay content subtracts margins")
	var slots: Dictionary = presentation.resolve_vertical_slots({
		"content_rect": content.get("rect", Rect2()),
		"count": 3,
		"item_owner_rect": Vector4(0.0, 0.0, 520.0, 90.0),
		"spacing": 6.0,
		"fit_height": true
	})
	_assert_eq(Array(slots.get("slots", [])).size(), 3, "overlay slot resolver returns three cards")
	_assert_eq(Vector2(slots.get("item_size", Vector2.ZERO)), Vector2(408.0, 66.0), "overlay slots clamp width and fit height")
	var slot_list: Array = Array(slots.get("slots", []))
	_assert_eq(Rect2(slot_list[1]).position.y, Rect2(slot_list[0]).position.y + 72.0, "overlay slots include spacing")
	var horizontal_slots: Dictionary = presentation.resolve_horizontal_slots({
		"content_rect": content.get("rect", Rect2()),
		"count": 3,
		"item_owner_rect": Vector4(0.0, 0.0, 160.0, 96.0),
		"spacing": 6.0,
		"fit_width": true
	})
	_assert_eq(Array(horizontal_slots.get("slots", [])).size(), 3, "overlay horizontal slot resolver returns three cards")
	_assert_eq(Vector2(horizontal_slots.get("item_size", Vector2.ZERO)), Vector2(132.0, 96.0), "overlay horizontal slots fit width and keep portrait height")
	var horizontal_slot_list: Array = Array(horizontal_slots.get("slots", []))
	_assert_eq(Rect2(horizontal_slot_list[1]).position.x, Rect2(horizontal_slot_list[0]).position.x + 138.0, "overlay horizontal slots include spacing")
	var motion: Dictionary = presentation.resolve_motion({
		"phase": "open",
		"elapsed": 0.15,
		"duration": 0.3,
		"from_alpha": 0.0,
		"to_alpha": 1.0,
		"from_scale": 0.96,
		"to_scale": 1.0
	})
	_assert_float_eq(float(motion.get("progress", 0.0)), 0.5, 0.001, "overlay motion reports normalized progress")
	_assert_float_eq(float(motion.get("alpha", 0.0)), 0.5, 0.001, "overlay motion interpolates alpha")
	_assert_true(not bool(motion.get("done", true)), "overlay motion not done before duration")

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _assert_float_eq(actual: float, expected: float, tolerance: float, label: String) -> void:
	if abs(actual - expected) > tolerance:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
