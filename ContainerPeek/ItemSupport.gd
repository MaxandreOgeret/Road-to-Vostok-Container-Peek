extends RefCounted

const RARITY_COMMON := "Common"


static func item_counts(node: Node) -> Dictionary:
	var result: Dictionary = {}
	var summaries := item_summaries(node)
	for item_name in summaries.keys():
		var summary := summaries[item_name] as Dictionary
		result[item_name] = int(summary.get("amount", 0))
	return result


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
		var amount := slot_amount(slot)
		summary["amount"] = int(summary.get("amount", 0)) + amount
		summary["weight"] = float(summary.get("weight", 0.0)) + slot_total_weight(slot)
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


static func slot_total_weight(slot: Variant) -> float:
	var item := slot_item(slot)
	if item == null or not (item is Object):
		return 0.0

	var raw_weight: Variant = (item as Object).get("weight")
	var slot_weight := 0.0
	if raw_weight is float:
		slot_weight = float(raw_weight)
	elif raw_weight is int:
		slot_weight = float(raw_weight)

	# RTV already reports effective slot weight here, including stack size and loaded contents.
	return maxf(0.0, slot_weight)


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
	var item := slot_item(slot)
	if not item_uses_condition(item):
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


static func item_uses_condition(item: Variant) -> bool:
	if item == null or not (item is Object):
		return false

	var item_object := item as Object
	var item_type := str(item_object.get("type")).strip_edges()
	var item_subtype := str(item_object.get("subtype")).strip_edges()

	if item_subtype == "Magazine":
		return false

	return item_type in ["Weapon", "Armor", "Electronics"]


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


static func rarity_color(rarity: String, enabled: bool) -> Color:
	if not enabled:
		return Color(1.0, 1.0, 1.0, 0.78)

	match normalize_rarity_value(rarity).to_lower():
		"legendary":
			return Color(1.0, 0.75, 0.28, 0.95)
		"epic":
			return Color(0.88, 0.52, 1.0, 0.95)
		"rare":
			return Color(0.45, 0.78, 1.0, 0.95)
		"uncommon":
			return Color(0.56, 0.9, 0.56, 0.92)
		_:
			return Color(1.0, 1.0, 1.0, 0.78)


static func normalize_rarity_value(rarity: Variant) -> String:
	var rarity_text := str(rarity).strip_edges()
	match rarity_text.to_lower():
		"0":
			return "Common"
		"1":
			return "Uncommon"
		"2":
			return "Rare"
		"3":
			return "Epic"
		"4", "5":
			return "Legendary"
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


static func selected_slot(container_node: Node, selection_by_id: Dictionary) -> Variant:
	var selected_name := selected_item_name(container_node, selection_by_id)
	if selected_name.is_empty():
		return null

	for slot in slot_source(container_node):
		if slot_display_name(slot) == selected_name:
			return slot
	return null


static func selected_item_name(container_node: Node, selection_by_id: Dictionary) -> String:
	var counts := item_counts(container_node)
	if counts.is_empty():
		return ""

	var names: Array = counts.keys()
	names.sort()
	var selected_index := int(selection_by_id.get(container_node.get_instance_id(), 0))
	selected_index = clampi(selected_index, 0, maxi(names.size() - 1, 0))
	return str(names[selected_index])


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


static func selectable_item_count(node: Node) -> int:
	return item_counts(node).size()
