class_name ShinokuteAdsManager
extends Node

signal ad_requested(placement: String)
signal ad_completed(placement: String, rewarded: bool)
signal ad_state_changed(placement: String, state: String, payload: Dictionary)
signal ad_failed(placement: String, reason: String, payload: Dictionary)
signal ad_reward_claimed(placement: String, reward_token: String, payload: Dictionary)

var enabled := true
var placements: Dictionary = {}
var provider_capabilities: Dictionary = {}
var _last_shown_at: Dictionary = {}
var _placement_state: Dictionary = {}
var _reward_claims: Dictionary = {}

func configure(placement_config: Dictionary = {}, is_enabled: bool = true, capabilities: Dictionary = {}) -> void:
	placements = placement_config.duplicate(true)
	enabled = is_enabled
	provider_capabilities = capabilities.duplicate(true)
	_placement_state = {}
	_reward_claims = {}

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
	_set_state(placement, "requested", {})
	ad_requested.emit(placement)
	return OK

func mark_showing(placement: String, payload: Dictionary = {}) -> int:
	if not placements.has(placement):
		return ERR_DOES_NOT_EXIST
	_set_state(placement, "showing", payload)
	return OK

func fail_ad(placement: String, reason: String, payload: Dictionary = {}) -> int:
	if not placements.has(placement):
		return ERR_DOES_NOT_EXIST
	var combined_payload := payload.duplicate(true)
	combined_payload["reason"] = reason
	_set_state(placement, "failed", combined_payload)
	ad_failed.emit(placement, reason, payload.duplicate(true))
	return OK

func complete_ad(placement: String, rewarded: bool = false, reward_token: String = "", payload: Dictionary = {}) -> int:
	if rewarded and not reward_token.is_empty():
		var claim_result := claim_reward(placement, reward_token, payload)
		if claim_result != OK and claim_result != ERR_ALREADY_EXISTS:
			return claim_result
	_set_state(placement, "completed", payload)
	ad_completed.emit(placement, rewarded)
	return OK

func claim_reward(placement: String, reward_token: String, payload: Dictionary = {}) -> int:
	if reward_token.is_empty():
		return ERR_INVALID_PARAMETER
	var claim_key := "%s:%s" % [placement, reward_token]
	if bool(_reward_claims.get(claim_key, false)):
		return ERR_ALREADY_EXISTS
	_reward_claims[claim_key] = true
	var combined_payload := payload.duplicate(true)
	combined_payload["reward_token"] = reward_token
	ad_reward_claimed.emit(placement, reward_token, combined_payload)
	return OK

func reset_cooldown(placement: String) -> void:
	_last_shown_at.erase(placement)

func provider_status() -> Dictionary:
	return provider_capabilities.duplicate(true)

func placement_status(placement: String) -> Dictionary:
	var current := Dictionary(_placement_state.get(placement, {}))
	var status := {
		"placement": placement,
		"state": String(current.get("state", "idle")),
		"payload": Dictionary(current.get("payload", {})),
		"cooldown_seconds": int(Dictionary(placements.get(placement, {})).get("cooldown_seconds", 0)),
		"last_shown_at": float(_last_shown_at.get(placement, -1000000000.0))
	}
	return status

func _set_state(placement: String, state: String, payload: Dictionary = {}) -> void:
	_placement_state[placement] = {
		"state": state,
		"payload": payload.duplicate(true)
	}
	ad_state_changed.emit(placement, state, payload.duplicate(true))
