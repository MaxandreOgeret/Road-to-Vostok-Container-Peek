extends RefCounted

const CONFIG_PATH := "user://MCM/ContainerPeek/config.ini"


static func binding_label(owner: Node, action_name: StringName) -> String:
	var config_node := owner.get_node_or_null("/root/ContainerPeekConfig")
	if config_node != null and config_node.has_method("get_binding_label"):
		return str(config_node.call("get_binding_label", action_name))

	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return ""

	return event_label(events[0])


static func bool_setting(owner: Node, setting_key: String, default_value: bool = false) -> bool:
	var config_node := owner.get_node_or_null("/root/ContainerPeekConfig")
	if config_node != null and config_node.has_method("get_bool"):
		return bool(config_node.call("get_bool", setting_key, default_value))

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		var value: Variant = config.get_value("Bool", setting_key, default_value)
		if value is Dictionary:
			return bool((value as Dictionary).get("value", default_value))
		return bool(value)
	return default_value


static func float_setting(owner: Node, setting_key: String, default_value: float = 0.0) -> float:
	var config_node := owner.get_node_or_null("/root/ContainerPeekConfig")
	if config_node != null and config_node.has_method("get_float"):
		return float(config_node.call("get_float", setting_key, default_value))

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		var value: Variant = config.get_value("Float", setting_key, default_value)
		if value is Dictionary:
			value = (value as Dictionary).get("value", default_value)
		if value is float:
			return float(value)
		if value is int:
			return float(value)
	return default_value


static func event_label(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		return _mouse_button_text((event as InputEventMouseButton).button_index)
	if event is InputEventKey:
		return _clean_key_label((event as InputEventKey).as_text())
	return ""


static func _mouse_button_text(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "Left Mouse Button"
		MOUSE_BUTTON_RIGHT:
			return "Right Mouse Button"
		MOUSE_BUTTON_MIDDLE:
			return "Middle Mouse Button"
		MOUSE_BUTTON_WHEEL_DOWN:
			return "Mouse Wheel Down"
		MOUSE_BUTTON_WHEEL_UP:
			return "Mouse Wheel Up"
		MOUSE_BUTTON_XBUTTON1:
			return "Mouse Button 1"
		MOUSE_BUTTON_XBUTTON2:
			return "Mouse Button 2"
		_:
			return "Mouse %d" % button_index


static func _clean_key_label(label: String) -> String:
	return label.replace(" (Physical)", "").replace(" - Physical", "")
