extends SceneTree

const SceneRouterScript := preload("res://addons/shinokute_game_core/ux/scene_router.gd")
const OverlayManagerScript := preload("res://addons/shinokute_game_core/ux/overlay_manager.gd")
const SceneTransitionScript := preload("res://addons/shinokute_game_core/ux/scene_transition_lifecycle.gd")

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
	_report("test_core_ux_contract")

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
