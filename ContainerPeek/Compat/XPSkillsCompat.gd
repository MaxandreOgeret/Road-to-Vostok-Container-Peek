extends RefCounted

const ItemSupport = preload("res://ContainerPeek/ItemSupport.gd")


class GridItem:
	extends RefCounted

	var slotData

	func _init(slot_data) -> void:
		slotData = slot_data


class GridProxy:
	extends RefCounted

	var _container_node

	func _init(container_node: Node) -> void:
		_container_node = container_node

	func get_children() -> Array:
		var children: Array = []
		for slot in ItemSupport.slot_source(_container_node):
			children.append(GridItem.new(slot))
		return children


class InterfaceProxy:
	extends RefCounted

	var container
	var containerGrid

	func _init(container_node: Node) -> void:
		container = container_node
		containerGrid = GridProxy.new(container_node)

	func AutoStack(slot, _grid) -> bool:
		return ItemSupport.try_stack_slot_into_container(container, slot)

	func Create(slot, _grid, _allow_auto_place) -> bool:
		ItemSupport.append_slot_to_container(container, slot)
		return true


static func notify_container_open(container_node: Node, ui_root: Node) -> bool:
	if not Engine.has_meta("XPMain"):
		return false
	var xp_mod = Engine.get_meta("XPMain")
	if xp_mod == null or container_node == null:
		return false
	if not _tracking_allowed(xp_mod):
		return false

	var awarded: Variant = xp_mod.get("_awarded_containers")
	if not (awarded is Dictionary):
		return false

	var container_id := container_node.get_instance_id()
	if (awarded as Dictionary).has(container_id):
		return false

	(awarded as Dictionary)[container_id] = true
	xp_mod.set("_awarded_containers", awarded)
	_award_container_xp(xp_mod)
	return _try_scavenge(xp_mod, container_node, ui_root)


static func _tracking_allowed(xp_mod: Object) -> bool:
	var game_data: Variant = xp_mod.get("gameData")
	if not (game_data is Object):
		return true
	var game_data_object := game_data as Object
	if _get_bool(game_data_object, "menu", false):
		return false
	if _get_bool(game_data_object, "shelter", false):
		return false
	if _get_bool(game_data_object, "isTrading", false):
		return false
	return true


static func _award_container_xp(xp_mod: Object) -> void:
	# XP Skills may rename or drop these across updates; Object.get() then returns
	# null and float()/int() on null crashes. Bail out instead of awarding zeros,
	# which would otherwise silently corrupt the player's XP totals.
	if (
		xp_mod.get("cfg_xp_container") == null
		or xp_mod.get("_container_xp_fraction") == null
		or xp_mod.get("xp") == null
		or xp_mod.get("xpTotal") == null
	):
		return

	var reward := _get_float(xp_mod, "cfg_xp_container", 0.0)
	var fraction := _get_float(xp_mod, "_container_xp_fraction", 0.0) + reward
	var whole := int(floor(fraction))

	if whole > 0:
		xp_mod.set("xp", _get_int(xp_mod, "xp", 0) + whole)
		xp_mod.set("xpTotal", _get_int(xp_mod, "xpTotal", 0) + whole)
		fraction -= float(whole)

	xp_mod.set("_container_xp_fraction", fraction)
	if xp_mod.has_method("SaveXP"):
		xp_mod.call("SaveXP")


static func _try_scavenge(xp_mod: Object, container_node: Node, ui_root: Node) -> bool:
	if not xp_mod.has_method("get_level") or not xp_mod.has_method("prestige_scavenger_bonus"):
		return false

	var level := _to_int(xp_mod.call("get_level", 11), 0)
	var prestige_bonus := _to_float(xp_mod.call("prestige_scavenger_bonus"), 0.0)
	if level <= 0 and is_zero_approx(prestige_bonus):
		return false

	var chance := level * _get_float(xp_mod, "cfg_scavenger_chance", 0.0) + prestige_bonus
	if randf() >= chance:
		return false

	var proxy := InterfaceProxy.new(container_node)
	var item_name := ""
	if xp_mod.has_method("_try_loot_pool_spawn"):
		item_name = str(xp_mod.call("_try_loot_pool_spawn", level, randf(), proxy)).strip_edges()

	if item_name.is_empty():
		var source := ItemSupport.slot_source(container_node)
		if source.is_empty():
			return false
		var source_slot = source[randi() % source.size()]
		var dupe_data = ItemSupport.clone_slot(source_slot)
		if dupe_data == null or ItemSupport.slot_item(dupe_data) == null:
			return false
		if ItemSupport.slot_is_stackable(dupe_data):
			ItemSupport.set_slot_amount(dupe_data, 1)
		if (
			proxy.AutoStack(dupe_data, proxy.containerGrid)
			or proxy.Create(dupe_data, proxy.containerGrid, true)
		):
			item_name = ItemSupport.slot_display_name(source_slot)

	if item_name.is_empty():
		return false

	if ui_root != null and xp_mod.has_method("_show_scavenge_notify"):
		xp_mod.call("_show_scavenge_notify", ui_root, item_name)
	return true


# Cross-mod property/return values may be absent or retyped after an XP Skills
# update, so every fetched Variant is type-checked and falls back rather than
# being cast blindly (float()/int() on null is a hard runtime error).
static func _to_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	return fallback


static func _to_int(value: Variant, fallback: int) -> int:
	if value is int or value is float:
		return int(value)
	return fallback


static func _get_float(obj: Object, prop: String, fallback: float) -> float:
	return _to_float(obj.get(prop), fallback)


static func _get_int(obj: Object, prop: String, fallback: int) -> int:
	return _to_int(obj.get(prop), fallback)


static func _get_bool(obj: Object, prop: String, fallback: bool) -> bool:
	var value: Variant = obj.get(prop)
	if value == null:
		return fallback
	return bool(value)
