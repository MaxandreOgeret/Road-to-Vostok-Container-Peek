extends RefCounted

const ItemSupport = preload("res://ContainerPeek/ItemSupport.gd")
const SORT_MODE_NAME := 0
const SORT_MODE_RARITY := 1
const SORT_MODE_WEIGHT := 2
const SORT_MODE_VALUE := 3
const RARITY_COMMON := "Common"

var _debug_enabled := false
var _debug_log_path := ""
var _selected_name_by_target: Dictionary = {}
var _anchor_row_by_target: Dictionary = {}
var _window_start_by_target: Dictionary = {}
var _anchored_by_target: Dictionary = {}
var _manual_input_by_target: Dictionary = {}
var _reveal_state_by_target: Dictionary = {}
var _visible_names_cache_by_target: Dictionary = {}


func set_debug_enabled(enabled: bool, log_path: String) -> void:
	_debug_enabled = enabled
	_debug_log_path = log_path


func reset() -> void:
	var had_state := (
		not _selected_name_by_target.is_empty()
		or not _anchor_row_by_target.is_empty()
		or not _window_start_by_target.is_empty()
		or not _anchored_by_target.is_empty()
		or not _manual_input_by_target.is_empty()
		or not _reveal_state_by_target.is_empty()
		or not _visible_names_cache_by_target.is_empty()
	)
	_selected_name_by_target.clear()
	_anchor_row_by_target.clear()
	_window_start_by_target.clear()
	_anchored_by_target.clear()
	_manual_input_by_target.clear()
	_reveal_state_by_target.clear()
	_visible_names_cache_by_target.clear()
	if had_state:
		_debug_log("reset-all")


func reset_target(target_id: int) -> void:
	if target_id == -1:
		return
	var had_state := (
		_selected_name_by_target.has(target_id)
		or _anchor_row_by_target.has(target_id)
		or _window_start_by_target.has(target_id)
		or _anchored_by_target.has(target_id)
		or _manual_input_by_target.has(target_id)
		or _reveal_state_by_target.has(target_id)
		or _visible_names_cache_by_target.has(target_id)
	)
	_selected_name_by_target.erase(target_id)
	_anchor_row_by_target.erase(target_id)
	_window_start_by_target.erase(target_id)
	_anchored_by_target.erase(target_id)
	_manual_input_by_target.erase(target_id)
	_reveal_state_by_target.erase(target_id)
	_visible_names_cache_by_target.erase(target_id)
	if had_state:
		_debug_log("reset-target id=%d" % target_id)


func reset_for_sort_change(target_id: int) -> void:
	if target_id != -1:
		_debug_log("reset-sort id=%d" % target_id)
	reset_target(target_id)


func derive_state(
	target_id: int,
	summaries: Dictionary,
	summary_signature: String,
	revealed_count: int,
	sort_mode: int,
	max_visible_items: int
) -> Dictionary:
	var visible_names := _visible_names(
		target_id, summaries, summary_signature, revealed_count, sort_mode
	)
	var visible_count := visible_names.size()
	var viewport_size := maxi(1, max_visible_items)
	var viewport_full := visible_count >= viewport_size
	var logical_row_count := visible_count + (1 if visible_count < summaries.size() else 0)
	var manual_input := bool(_manual_input_by_target.get(target_id, false))

	if not viewport_full:
		if bool(_anchored_by_target.get(target_id, false)):
			_debug_log(
				(
					"drop-anchor id=%d visible=%d viewport=%d"
					% [target_id, visible_count, viewport_size]
				)
			)
		_anchored_by_target[target_id] = false
		_anchor_row_by_target.erase(target_id)
		_window_start_by_target[target_id] = 0
	else:
		var selected_index_for_anchor := _resolved_selected_index(
			target_id, visible_names, false, viewport_size, manual_input
		)
		if not bool(_anchored_by_target.get(target_id, false)):
			_anchor_row_by_target[target_id] = clampi(
				selected_index_for_anchor, 0, viewport_size - 1
			)
			_anchored_by_target[target_id] = true
			_debug_log(
				(
					"enter-anchor id=%d visible=%d viewport=%d selected=%d anchor_row=%d"
					% [
						target_id,
						visible_count,
						viewport_size,
						selected_index_for_anchor,
						int(_anchor_row_by_target.get(target_id, 0)),
					]
				)
			)

	var anchored := viewport_full and bool(_anchored_by_target.get(target_id, false))
	var selected_index := _resolved_selected_index(
		target_id, visible_names, anchored, viewport_size, manual_input or anchored
	)
	var selected_name := ""
	if selected_index >= 0 and selected_index < visible_names.size():
		selected_name = str(visible_names[selected_index])
		_selected_name_by_target[target_id] = selected_name

	var window_start := 0
	if anchored and selected_index >= 0:
		var anchor_row := clampi(int(_anchor_row_by_target.get(target_id, 0)), 0, viewport_size - 1)
		window_start = clampi(
			selected_index - anchor_row, 0, maxi(visible_count - viewport_size, 0)
		)
	else:
		window_start = 0
	_window_start_by_target[target_id] = window_start

	var window_end := mini(window_start + viewport_size, logical_row_count)
	var rendered_names: Array = []
	var item_window_end := mini(window_end, visible_count)
	for i in range(window_start, item_window_end):
		rendered_names.append(str(visible_names[i]))

	var selected_viewport_row := -1
	if selected_index >= 0:
		selected_viewport_row = selected_index - window_start

	_debug_log(
		(
			(
				"derive id=%d visible=%d revealed=%d full=%s anchored=%s selected='%s' "
				+ "manual=%s "
				+ "selected_index=%d anchor_row=%d window=%d..%d viewport_row=%d "
				+ "placeholder=%s"
			)
			% [
				target_id,
				visible_count,
				revealed_count,
				str(viewport_full),
				str(anchored),
				selected_name,
				str(manual_input),
				selected_index,
				int(_anchor_row_by_target.get(target_id, -1)),
				window_start,
				window_end,
				selected_viewport_row,
				str(logical_row_count > visible_count and window_end > visible_count),
			]
		)
	)

	return {
		"visible_names": visible_names,
		"selected_name": selected_name,
		"selected_index": selected_index,
		"selected_viewport_row": selected_viewport_row,
		"window_start": window_start,
		"window_end": window_end,
		"rendered_names": rendered_names,
		"render_placeholder": logical_row_count > visible_count and window_end > visible_count,
		"viewport_full": viewport_full,
		"anchored": anchored,
		"snap_to_top": false,
	}


func move_selection(
	target_id: int, item_names: Array, direction: int, max_visible_items: int
) -> bool:
	if target_id == -1 or item_names.is_empty() or direction == 0:
		return false

	var current := _resolved_selected_index(
		target_id,
		item_names,
		bool(_anchored_by_target.get(target_id, false)),
		max_visible_items,
		true
	)
	var next_selection := clampi(current + direction, 0, item_names.size() - 1)
	if next_selection == current:
		return false

	var viewport_size := maxi(1, max_visible_items)
	var viewport_full := item_names.size() >= viewport_size
	var next_item_name := str(item_names[next_selection])
	_selected_name_by_target[target_id] = next_item_name
	_manual_input_by_target[target_id] = true

	if viewport_full:
		var window_start := int(_window_start_by_target.get(target_id, 0))
		if next_selection < window_start:
			window_start = next_selection
		elif next_selection >= window_start + viewport_size:
			window_start = next_selection - (viewport_size - 1)
		window_start = clampi(window_start, 0, maxi(item_names.size() - viewport_size, 0))
		_window_start_by_target[target_id] = window_start
		_anchor_row_by_target[target_id] = next_selection - window_start
		_anchored_by_target[target_id] = true
	else:
		_window_start_by_target[target_id] = 0
		_anchor_row_by_target.erase(target_id)
		_anchored_by_target[target_id] = false

	_debug_log(
		(
			("move id=%d dir=%d current=%d next=%d item='%s' full=%s window_start=%d anchor_row=%d")
			% [
				target_id,
				direction,
				current,
				next_selection,
				next_item_name,
				str(viewport_full),
				int(_window_start_by_target.get(target_id, 0)),
				int(_anchor_row_by_target.get(target_id, -1)),
			]
		)
	)

	return true


func selected_name(target_id: int, item_names: Array) -> String:
	var selected_index := _resolved_selected_index(
		target_id,
		item_names,
		bool(_anchored_by_target.get(target_id, false)),
		item_names.size(),
		true
	)
	if selected_index < 0 or selected_index >= item_names.size():
		return ""
	return str(item_names[selected_index])


func _visible_names(
	target_id: int,
	summaries: Dictionary,
	summary_signature: String,
	revealed_count: int,
	sort_mode: int
) -> Array:
	var cached := _visible_names_cache_by_target.get(target_id, {}) as Dictionary
	if (
		str(cached.get("signature", "")) == summary_signature
		and int(cached.get("sort_mode", -1)) == sort_mode
	):
		var cached_revealed_count := int(cached.get("revealed_count", -1))
		if cached_revealed_count == revealed_count:
			return cached.get("names", []) as Array
		if cached_revealed_count >= 0 and revealed_count > cached_revealed_count:
			var reveal_order := _reveal_order(target_id, summaries, summary_signature)
			if revealed_count <= reveal_order.size():
				var cached_names := (cached.get("names", []) as Array).duplicate()
				for i in range(cached_revealed_count, revealed_count):
					_insert_sorted_name(str(reveal_order[i]), cached_names, summaries, sort_mode)
				_visible_names_cache_by_target[target_id] = {
					"signature": summary_signature,
					"revealed_count": revealed_count,
					"sort_mode": sort_mode,
					"names": cached_names,
				}
				return cached_names

	var names := _revealed_names(target_id, summaries, summary_signature, revealed_count)
	names.sort_custom(
		func(a: Variant, b: Variant) -> bool:
			return _item_name_less(str(a), str(b), summaries, sort_mode)
	)
	_visible_names_cache_by_target[target_id] = {
		"signature": summary_signature,
		"revealed_count": revealed_count,
		"sort_mode": sort_mode,
		"names": names,
	}
	return names


func _insert_sorted_name(
	item_name: String, names: Array, summaries: Dictionary, sort_mode: int
) -> void:
	var insert_at := names.size()
	for i in range(names.size()):
		if _item_name_less(item_name, str(names[i]), summaries, sort_mode):
			insert_at = i
			break
	names.insert(insert_at, item_name)


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


func _resolved_selected_index(
	target_id: int,
	item_names: Array,
	anchored: bool,
	max_visible_items: int,
	preserve_selected_name: bool
) -> int:
	if target_id == -1 or item_names.is_empty():
		if target_id != -1:
			_selected_name_by_target.erase(target_id)
		return -1

	if preserve_selected_name:
		var selected_name := str(_selected_name_by_target.get(target_id, ""))
		if not selected_name.is_empty():
			var selected_index := item_names.find(selected_name)
			if selected_index >= 0:
				return selected_index

	if anchored:
		var window_start := int(_window_start_by_target.get(target_id, 0))
		var anchor_row := clampi(
			int(_anchor_row_by_target.get(target_id, 0)), 0, maxi(0, max_visible_items - 1)
		)
		return clampi(window_start + anchor_row, 0, item_names.size() - 1)

	return 0


func _debug_log(line: String) -> void:
	if not _debug_enabled or _debug_log_path.is_empty():
		return

	var file := FileAccess.open(_debug_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(_debug_log_path, FileAccess.WRITE)
	if file == null:
		return

	file.seek_end()
	file.store_line("[ContainerPeek][Policy] %s" % line)


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
