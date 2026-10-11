extends RefCounted


static func looks_like_container(node: Node) -> bool:
	var raw_name: Variant = node.get("containerName")
	var has_name := raw_name is String and not (raw_name as String).strip_edges().is_empty()
	var has_loot := node.get("loot") is Array
	var has_storage := node.get("storage") is Array
	var has_locked := node.get("locked") != null
	var has_storaged := node.get("storaged") != null

	if (has_loot or has_storage) and (has_name or has_locked or has_storaged):
		return true

	var script: Variant = node.get_script()
	if script is Script:
		var path := (script as Script).resource_path.to_lower()
		if path.contains("container") or path.contains("corpse"):
			return has_loot or has_storage or has_name

	var scene_path := node.scene_file_path.to_lower()
	if scene_path.contains("container") or scene_path.contains("corpse"):
		return has_loot or has_storage or has_name

	return false


static func is_corpse(node: Node) -> bool:
	if node == null:
		return false

	var current: Node = node
	var depth := 0
	while current != null and depth < 32:
		if _node_looks_like_corpse(current):
			return true
		current = current.get_parent()
		depth += 1

	return false


static func is_corpse_title(title: String) -> bool:
	return title.to_lower().contains("corpse")


static func _node_looks_like_corpse(node: Node) -> bool:
	if node == null:
		return false

	var script: Variant = node.get_script()
	if script is Script:
		var script_path := (script as Script).resource_path.to_lower()
		if script_path.contains("corpse"):
			return true

	var scene_path := node.scene_file_path.to_lower()
	if scene_path.contains("corpse"):
		return true

	var raw_name: Variant = node.get("containerName")
	if raw_name is String and (raw_name as String).to_lower().contains("corpse"):
		return true

	return false
