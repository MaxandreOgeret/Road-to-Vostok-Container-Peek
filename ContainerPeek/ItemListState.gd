extends RefCounted

const ItemSupport = preload("res://ContainerPeek/ItemSupport.gd")
const SORT_MODE_NAME := 0
const SORT_MODE_RARITY := 1
const SORT_MODE_WEIGHT := 2
const SORT_MODE_VALUE := 3
const RARITY_COMMON := "Common"

var _selection_by_target: Dictionary = {}
var _selected_name_by_target: Dictionary = {}
var _reveal_state_by_target: Dictionary = {}


func reset() -> void:
	_selection_by_target.clear()
	_selected_name_by_target.clear()
	_reveal_state_by_target.clear()


func reset_target(target_id: int) -> void:
	if target_id == -1:
		return
	_selection_by_target[target_id] = 0
	_selected_name_by_target.erase(target_id)


func visible_names_for(
	target_id: int,
	summaries: Dictionary,
	summary_signature: String,
	revealed_count: int,
	sort_mode: int
) -> Array:
	var ordered_names := _revealed_names(target_id, summaries, summary_signature, revealed_count)
	ordered_names.sort_custom(
		func(a: Variant, b: Variant) -> bool:
			return _item_name_less(str(a), str(b), summaries, sort_mode)
	)

	_sync_selection(target_id, ordered_names)
	return ordered_names


func move_selection(target_id: int, item_names: Array, direction: int) -> bool:
	if target_id == -1 or item_names.is_empty() or direction == 0:
		return false

	var current := _sync_selection(target_id, item_names)
	var next_selection := clampi(current + direction, 0, item_names.size() - 1)
	if next_selection == current:
		return false

	_set_selection(target_id, item_names, next_selection)
	return true


func selected_index(target_id: int, item_names: Array) -> int:
	if item_names.is_empty():
		return 0
	return _sync_selection(target_id, item_names)


func selected_name(target_id: int, item_names: Array) -> String:
	if target_id == -1 or item_names.is_empty():
		return ""

	var index := _sync_selection(target_id, item_names)
	return str(item_names[index])


func _revealed_names(
	target_id: int, summaries: Dictionary, summary_signature: String, revealed_count: int
) -> Array:
	var reveal_order := _reveal_order(target_id, summaries, summary_signature)
	var visible_count := clampi(revealed_count, 0, reveal_order.size())
	var visible_names: Array = []
	for i in range(visible_count):
		visible_names.append(str(reveal_order[i]))
	return visible_names


func _reveal_order(target_id: int, summaries: Dictionary, summary_signature: String) -> Array:
	var current_state := _reveal_state_by_target.get(target_id, {}) as Dictionary
	if str(current_state.get("signature", "")) == summary_signature:
		return current_state.get("names", []) as Array

	var names: Array = summaries.keys()
	names.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a).nocasecmp_to(str(b)) < 0)
	names.shuffle()
	_reveal_state_by_target[target_id] = {
		"signature": summary_signature,
		"names": names.duplicate(),
	}
	return names


func _sync_selection(target_id: int, item_names: Array) -> int:
	if target_id == -1 or item_names.is_empty():
		if target_id != -1:
			_selection_by_target[target_id] = 0
			_selected_name_by_target.erase(target_id)
		return 0

	var selected_name := str(_selected_name_by_target.get(target_id, ""))
	if not selected_name.is_empty():
		var selected_index := item_names.find(selected_name)
		if selected_index >= 0:
			_selection_by_target[target_id] = selected_index
			return selected_index

	var current := int(_selection_by_target.get(target_id, 0))
	var clamped := clampi(current, 0, item_names.size() - 1)
	_set_selection(target_id, item_names, clamped)
	return clamped


func _set_selection(target_id: int, item_names: Array, index: int) -> void:
	if target_id == -1 or item_names.is_empty():
		return

	var clamped := clampi(index, 0, item_names.size() - 1)
	_selection_by_target[target_id] = clamped
	_selected_name_by_target[target_id] = str(item_names[clamped])


static func _item_name_less(a: String, b: String, summaries: Dictionary, sort_mode: int) -> bool:
	var a_summary := summaries.get(a, {}) as Dictionary
	var b_summary := summaries.get(b, {}) as Dictionary

	match sort_mode:
		SORT_MODE_RARITY:
			var a_rarity := _rarity_rank(str(a_summary.get("rarity", RARITY_COMMON)))
			var b_rarity := _rarity_rank(str(b_summary.get("rarity", RARITY_COMMON)))
			if a_rarity != b_rarity:
				return a_rarity > b_rarity
		SORT_MODE_WEIGHT:
			var a_weight := float(a_summary.get("weight", 0.0))
			var b_weight := float(b_summary.get("weight", 0.0))
			if not is_equal_approx(a_weight, b_weight):
				return a_weight > b_weight
		SORT_MODE_VALUE:
			var a_value := int(a_summary.get("value", 0))
			var b_value := int(b_summary.get("value", 0))
			if a_value != b_value:
				return a_value > b_value
		_:
			pass

	return a.nocasecmp_to(b) < 0


static func _rarity_rank(rarity: String) -> int:
	match ItemSupport.normalize_rarity_value(rarity).to_lower():
		"legendary":
			return 4
		"epic":
			return 3
		"rare":
			return 2
		"uncommon":
			return 1
		_:
			return 0
