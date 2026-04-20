extends RefCounted

const RARITY_COMMON := "Common"


static func item_summaries(node: Node) -> Dictionary:
	var result: Dictionary = {}
	for slot in slot_source(node):
		var item_name := slot_display_name(slot)
		if not result.has(item_name):
			result[item_name] = {
				"amount": 0,
				"weight": 0.0,
				"condition_values": [],
				"rarity": RARITY_COMMON,
			}

		var summary := result[item_name] as Dictionary
		var amount := slot_summary_amount(slot)
		summary["amount"] = int(summary.get("amount", 0)) + amount
		summary["weight"] = float(summary.get("weight", 0.0)) + slot_total_weight(node, slot)
		summary["rarity"] = slot_rarity(slot)

		var condition := slot_condition_percent(slot)
		if condition >= 0:
			var values := summary.get("condition_values", []) as Array
			values.append(condition)
			summary["condition_values"] = values

		result[item_name] = summary

	for item_name in result.keys():
		var summary := result[item_name] as Dictionary
		summary["condition"] = format_condition(summary.get("condition_values", []) as Array)
		summary.erase("condition_values")
		result[item_name] = summary

	return result


static func slot_source(node: Node) -> Array:
	var storaged := bool(node.get("storaged"))
	var source: Variant = node.get("storage") if storaged else node.get("loot")
	if source is Array:
		return source
	return []


static func slot_item(slot: Variant) -> Variant:
	if slot is Object:
		return (slot as Object).get("itemData")
	if slot is Dictionary:
		return (slot as Dictionary).get("itemData", null)
	return null


static func slot_amount(slot: Variant) -> int:
	if slot is Object:
		var raw: Variant = (slot as Object).get("amount")
		if raw is int:
			return maxi(1, int(raw))
		if raw is float:
			return maxi(1, int(round(raw)))
	elif slot is Dictionary:
		var raw_dict: Variant = (slot as Dictionary).get("amount", 1)
		if raw_dict is int:
			return maxi(1, int(raw_dict))
		if raw_dict is float:
			return maxi(1, int(round(raw_dict)))
	return 1


static func slot_summary_amount(slot: Variant) -> int:
	# Mirrors res://Scripts/Item.gd amount semantics: ammo stacks expose item count,
	# while magazine and weapon amounts are loaded-round state, not item multiplicity.
	var item := slot_item(slot)
	if item == null:
		return 1

	var item_type := str(property_value(item, &"type")).strip_edges()
	var item_subtype := str(property_value(item, &"subtype")).strip_edges()
	if item_type == "Ammo" or item_subtype == "Magazine":
		if item_type == "Ammo":
			return slot_amount(slot)
		return 1

	var stackable := property_value(item, &"stackable")
	if stackable is bool and stackable:
		return slot_amount(slot)

	return 1


static func slot_total_weight(_container_node: Node, slot: Variant) -> float:
	# Mirrors res://Scripts/Item.gd Weight() so peek weights track live ammo, chamber,
	# magazine, and nested-item contributions the same way as the game tooltip/item UI.
	var item := slot_item(slot)
	if item == null:
		return 0.0

	var weight := numeric_property(item, [
		&"weight",
	])
	var item_type := str(property_value(item, &"type")).strip_edges()
	var item_subtype := str(property_value(item, &"subtype")).strip_edges()
	var loaded_amount := slot_raw_amount(slot)

	if item_type == "Ammo":
		var default_amount := numeric_property(item, [
			&"defaultAmount",
		])
		if default_amount > 0.0:
			weight *= loaded_amount / default_amount

	if item_subtype == "Magazine" and loaded_amount != 0.0:
		var compatible := property_value(item, &"compatible")
		if compatible is Array and not (compatible as Array).is_empty():
			var ammo_data: Variant = (compatible as Array)[0]
			var ammo_default_amount := numeric_property(ammo_data, [
				&"defaultAmount",
			])
			if ammo_default_amount > 0.0:
				var weight_per_round := numeric_property(ammo_data, [
					&"weight",
				]) / ammo_default_amount
				weight += weight_per_round * loaded_amount

	if item_type == "Weapon" and (loaded_amount != 0.0 or slot_chambered(slot)):
		var ammo_data := property_value(item, &"ammo")
		var ammo_default_amount := numeric_property(ammo_data, [
			&"defaultAmount",
		])
		if ammo_default_amount > 0.0:
			var weight_per_round := numeric_property(ammo_data, [
				&"weight",
			]) / ammo_default_amount
			var total_ammo_weight := weight_per_round * loaded_amount
			if slot_chambered(slot):
				total_ammo_weight += weight_per_round
			weight += total_ammo_weight

	for nested in slot_nested(slot):
		weight += numeric_property(nested, [
			&"weight",
		])

	return maxf(0.0, snappedf(weight, 0.01))


static func property_value(target: Variant, key: StringName) -> Variant:
	if target == null:
		return null
	if target is Object:
		return (target as Object).get(key)
	if target is Dictionary:
		return (target as Dictionary).get(key, null)
	return null


static func numeric_property(target: Variant, keys: Array[StringName]) -> float:
	for key in keys:
		var raw_value := property_value(target, key)
		if raw_value is float:
			return float(raw_value)
		if raw_value is int:
			return float(raw_value)
	return 0.0


static func slot_raw_amount(slot: Variant) -> float:
	if slot is Object:
		var raw: Variant = (slot as Object).get("amount")
		if raw is float:
			return float(raw)
		if raw is int:
			return float(raw)
	elif slot is Dictionary:
		var raw_dict: Variant = (slot as Dictionary).get("amount", 0)
		if raw_dict is float:
			return float(raw_dict)
		if raw_dict is int:
			return float(raw_dict)
	return 0.0


static func slot_chambered(slot: Variant) -> bool:
	var chambered := property_value(slot, &"chamber")
	if chambered is bool:
		return chambered
	return false


static func slot_nested(slot: Variant) -> Array:
	var nested := property_value(slot, &"nested")
	if nested is Array:
		return nested
	return []


static func slot_rarity(slot: Variant) -> String:
	var item := slot_item(slot)
	if item == null or not (item is Object):
		return RARITY_COMMON

	var raw_rarity: Variant = (item as Object).get("rarity")
	if raw_rarity is int:
		return normalize_rarity_value(int(raw_rarity))
	if raw_rarity is float:
		return normalize_rarity_value(int(round(raw_rarity)))

	var rarity := str(raw_rarity).strip_edges()
	return normalize_rarity_value(rarity)


static func slot_condition_percent(slot: Variant) -> int:
	if not slot_shows_condition(slot):
		return -1

	var raw: Variant = null
	if slot is Object:
		raw = (slot as Object).get("condition")
	elif slot is Dictionary:
		raw = (slot as Dictionary).get("condition", null)

	if raw is float:
		return normalize_condition_percent(float(raw))
	if raw is int:
		return normalize_condition_percent(float(raw))
	return -1


static func slot_shows_condition(slot: Variant) -> bool:
	# Mirrors the condition visibility rules used by res://Scripts/Item.gd and
	# res://Scripts/Tooltip.gd for weapons, armor, helmets, armored rigs, and showCondition items.
	var item := slot_item(slot)
	if item == null or not (item is Object):
		return false

	var item_object := item as Object
	var item_type := str(item_object.get("type")).strip_edges()
	if item_type == "Weapon":
		return true
	if item_type == "Armor" or item_type == "Helmet":
		return true
	if item_type == "Rig" and slot_has_nested_armor(slot):
		return true

	var show_condition := item_object.get("showCondition")
	if show_condition is bool and show_condition:
		return true

	return false


static func slot_has_nested_armor(slot: Variant) -> bool:
	for nested in slot_nested(slot):
		var nested_type := str(property_value(nested, &"type")).strip_edges()
		if nested_type == "Armor":
			return true
	return false


static func normalize_condition_percent(value: float) -> int:
	if value < 0.0:
		return -1
	var percent := value * 100.0 if value <= 1.0 else value
	return clampi(int(round(percent)), 0, 100)


static func format_weight(weight: float) -> String:
	return "%.1fkg" % maxf(0.0, weight)


static func format_condition(values: Array) -> String:
	if values.is_empty():
		return "--"

	var min_value := int(values[0])
	var max_value := int(values[0])
	for value in values:
		var percent := int(value)
		min_value = mini(min_value, percent)
		max_value = maxi(max_value, percent)

	if min_value == max_value:
		return "%d%%" % min_value
	return "%d-%d%%" % [min_value, max_value]


static func rarity_color(rarity: String, enabled: bool, custom_colors: Dictionary = {}) -> Color:
	if not enabled:
		return Color(1.0, 1.0, 1.0, 0.78)

	# Mirrors the game's real rarity tiers from res://Scripts/ItemData.gd and the
	# base tooltip rarity colors from res://Scripts/Tooltip.gd.
	match normalize_rarity_value(rarity).to_lower():
		"legendary":
			return rarity_color_override(custom_colors, "legendary", Color(1.0, 0.75, 0.28, 0.95))
		"rare":
			return rarity_color_override(custom_colors, "rare", Color(0.45, 0.78, 1.0, 0.95))
		_:
			return rarity_color_override(custom_colors, "common", Color(1.0, 1.0, 1.0, 0.78))


static func rarity_color_override(custom_colors: Dictionary, key: String, fallback: Color) -> Color:
	var configured := custom_colors.get(key, fallback)
	if configured is Color:
		return configured
	return fallback


static func normalize_rarity_value(rarity: Variant) -> String:
	# Mirrors ItemData.Rarity: Common, Rare, Legendary, Null.
	var rarity_text := str(rarity).strip_edges()
	match rarity_text.to_lower():
		"0":
			return "Common"
		"1":
			return "Rare"
		"2":
			return "Legendary"
		"3":
			return "Null"
		_:
			return rarity_text if not rarity_text.is_empty() else RARITY_COMMON


static func candidate_range(node: Node) -> float:
	var keys: Array[StringName] = [
		&"interactionDistance",
		&"interactionRange",
		&"interactDistance",
		&"interactRange",
		&"maxDistance",
		&"maxRange",
		&"range",
	]
	for key in keys:
		var value: Variant = node.get(key)
		if value is float:
			return maxf(0.1, float(value))
		if value is int:
			return maxf(0.1, float(value))
	return 2.5


static func slot_for_item_name(container_node: Node, item_name: String) -> Variant:
	if item_name.is_empty():
		return null

	for slot in slot_source(container_node):
		if slot_display_name(slot) == item_name:
			return slot
	return null


static func slot_display_name(slot: Variant) -> String:
	var item := slot_item(slot)
	if item == null or not (item is Object):
		return "Unknown Item"

	var item_name := str((item as Object).get("name")).strip_edges()
	if item_name.is_empty():
		return "Unknown Item"
	return item_name


static func remove_slot_from_container(container_node: Node, slot: Variant) -> void:
	var storaged := bool(container_node.get("storaged"))
	var property_name := "storage" if storaged else "loot"
	var source := slot_source(container_node)
	var index := source.find(slot)
	if index == -1:
		return

	source.remove_at(index)
	container_node.set(property_name, source)
