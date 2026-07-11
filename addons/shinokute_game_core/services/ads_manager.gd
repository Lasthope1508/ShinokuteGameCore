class_name ShinokuteAdsManager
extends Node

signal ad_requested(placement: String)
signal ad_completed(placement: String, rewarded: bool)

var enabled := true
var placements: Dictionary = {}
var _last_shown_at: Dictionary = {}

func configure(placement_config: Dictionary = {}, is_enabled: bool = true) -> void:
	placements = placement_config.duplicate(true)
	enabled = is_enabled

func can_show(placement: String) -> bool:
	if not enabled:
		return false
	if not placements.has(placement):
		return false
	var now := Time.get_unix_time_from_system()
	var cooldown := int(placements.get(placement, {}).get("cooldown_seconds", 0))
	var last := float(_last_shown_at.get(placement, -1000000000.0))
	return now - last >= cooldown

func request_ad(placement: String) -> int:
	if not placements.has(placement):
		return ERR_DOES_NOT_EXIST
	if not can_show(placement):
		return ERR_BUSY
	_last_shown_at[placement] = Time.get_unix_time_from_system()
	ad_requested.emit(placement)
	return OK

func complete_ad(placement: String, rewarded: bool = false) -> void:
	ad_completed.emit(placement, rewarded)

func reset_cooldown(placement: String) -> void:
	_last_shown_at.erase(placement)
