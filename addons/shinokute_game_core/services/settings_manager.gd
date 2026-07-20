class_name ShinokuteSettingsManager
extends Node

signal setting_changed(key: String, value: Variant)

const KEY_SFX_ENABLED := "sfx_enabled"
const KEY_BGM_ENABLED := "bgm_enabled"
const KEY_SHIFT_LOCK_ENABLED := "shift_lock_enabled"

const DEFAULTS := {
	KEY_SFX_ENABLED: true,
	KEY_BGM_ENABLED: true,
	KEY_SHIFT_LOCK_ENABLED: false
}

var config: Resource
var save_store: Node

func configure(core_config: Resource, store: Node) -> void:
	config = core_config
	save_store = store

func get_setting(key: String, missing_value: Variant = null) -> Variant:
	var default_value = _default_for(key, missing_value)
	if save_store != null and save_store.has_method("get_setting"):
		return save_store.get_setting(key, default_value)
	return default_value

func set_setting(key: String, value: Variant) -> void:
	var old_value = get_setting(key, null)
	if save_store != null and save_store.has_method("set_setting"):
		save_store.set_setting(key, value)
	if old_value != value:
		setting_changed.emit(key, value)

func is_sfx_enabled() -> bool:
	return bool(get_setting(KEY_SFX_ENABLED, true))

func set_sfx_enabled(value: bool) -> void:
	set_setting(KEY_SFX_ENABLED, value)

func is_bgm_enabled() -> bool:
	return bool(get_setting(KEY_BGM_ENABLED, true))

func set_bgm_enabled(value: bool) -> void:
	set_setting(KEY_BGM_ENABLED, value)

func is_shift_lock_enabled() -> bool:
	return bool(get_setting(KEY_SHIFT_LOCK_ENABLED, false))

func set_shift_lock_enabled(value: bool) -> void:
	set_setting(KEY_SHIFT_LOCK_ENABLED, value)

func _default_for(key: String, missing_value: Variant = null) -> Variant:
	if config != null and config.has_method("get_setting_default"):
		return config.get_setting_default(key, missing_value)
	if DEFAULTS.has(key):
		return DEFAULTS[key]
	return missing_value
