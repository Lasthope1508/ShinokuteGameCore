class_name ShinokuteLocalizationService
extends Node

signal locale_changed(locale: String)

var locale: String = "en"
var translations: Dictionary = {}

func configure(default_locale: String = "en", translation_table: Dictionary = {}) -> void:
	locale = default_locale
	translations = translation_table.duplicate(true)

func set_locale(value: String) -> void:
	var clean := value.strip_edges()
	if clean.is_empty():
		return
	locale = clean
	locale_changed.emit(locale)

func tr_key(key: String, params: Dictionary = {}) -> String:
	var text := _lookup(locale, key)
	if text.is_empty():
		text = key
	for param_key in params.keys():
		text = text.replace("{%s}" % String(param_key), String(params[param_key]))
	return text

func _lookup(language: String, key: String) -> String:
	if not translations.has(language):
		return ""
	return String(translations[language].get(key, ""))
