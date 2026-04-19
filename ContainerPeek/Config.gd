extends Node

const MOD_ID := "ContainerPeek"
const MOD_NAME := "Container Peek"
const CONFIG_DIR := "user://MCM/%s" % MOD_ID
const CONFIG_FILE := "config.ini"
const MCM_HELPERS_RES := "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"

const TRANSFER_ACTION := &"container_peek_transfer"
const TAKE_ALL_ACTION := &"container_peek_take_all"

var _config := ConfigFile.new()
var _mcm_helpers: Resource


func _ready() -> void:
	_mcm_helpers = _load_mcm_helpers()
	_ensure_config_dir()

	var defaults := _build_default_config()
	var config_path := _config_path()
	if FileAccess.file_exists(config_path):
		if _mcm_helpers != null and _mcm_helpers.has_method("CheckConfigurationHasUpdated"):
			_mcm_helpers.call("CheckConfigurationHasUpdated", MOD_ID, defaults, config_path)
		if _config.load(config_path) != OK:
			_config = defaults
			_config.save(config_path)
	else:
		_config = defaults
		_config.save(config_path)

	if _mcm_helpers != null and _mcm_helpers.has_method("RegisterConfiguration"):
		_mcm_helpers.call(
			"RegisterConfiguration",
			MOD_ID,
			MOD_NAME,
			CONFIG_DIR,
			"Configure Container Peek controls.",
			{CONFIG_FILE: Callable(self, "_on_config_saved")}
		)

	# Keep defaults working even when MCM is missing or not initialized yet.
	_apply_input_actions()


func get_binding_label(action_name: StringName) -> String:
	var event := _input_event_from_data(_binding_data(action_name))
	if event is InputEventMouseButton:
		return _mouse_button_text((event as InputEventMouseButton).button_index)
	if event is InputEventKey:
		return _clean_key_label((event as InputEventKey).as_text())
	return ""


func _on_config_saved(config: ConfigFile) -> void:
	_config = config
	_apply_input_actions()


func _load_mcm_helpers() -> Resource:
	if not ResourceLoader.exists(MCM_HELPERS_RES):
		return null
	return load(MCM_HELPERS_RES) as Resource


func _build_default_config() -> ConfigFile:
	var config := ConfigFile.new()
	(
		config
		. set_value(
			"Keycode",
			String(TRANSFER_ACTION),
			{
				"name": "Transfer Selected",
				"tooltip": "Move the selected item to inventory.",
				"default": KEY_F,
				"default_type": "Key",
				"value": KEY_F,
				"type": "Key",
				"menu_pos": 10,
			}
		)
	)
	(
		config
		. set_value(
			"Keycode",
			String(TAKE_ALL_ACTION),
			{
				"name": "Take All",
				"tooltip": "Transfer every item from the focused container.",
				"default": KEY_R,
				"default_type": "Key",
				"value": KEY_R,
				"type": "Key",
				"menu_pos": 20,
			}
		)
	)
	return config


func _ensure_config_dir() -> void:
	var root := DirAccess.open("user://")
	if root == null:
		return
	root.make_dir_recursive("MCM/%s" % MOD_ID)


func _config_path() -> String:
	return "%s/%s" % [CONFIG_DIR, CONFIG_FILE]


func _apply_input_actions() -> void:
	_set_action(TRANSFER_ACTION, _input_event_from_data(_binding_data(TRANSFER_ACTION)))
	_set_action(TAKE_ALL_ACTION, _input_event_from_data(_binding_data(TAKE_ALL_ACTION)))


func _binding_data(action_name: StringName) -> Dictionary:
	var key := String(action_name)
	var data: Variant = _config.get_value("Keycode", key, {})
	if data is Dictionary and not (data as Dictionary).is_empty():
		return (data as Dictionary).duplicate(true)
	return _default_binding_data(action_name)


func _default_binding_data(action_name: StringName) -> Dictionary:
	var defaults := _build_default_config()
	var data: Variant = defaults.get_value("Keycode", String(action_name), {})
	return data.duplicate(true) if data is Dictionary else {}


func _input_event_from_data(data: Dictionary) -> InputEvent:
	if data.is_empty():
		return null

	var input_type := str(data.get("type", data.get("default_type", "Key")))
	var raw_value: Variant = data.get("value", data.get("default", KEY_NONE))
	var keycode := int(raw_value)

	if input_type == "Mouse":
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = keycode
		return mouse_event

	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	return key_event


func _set_action(action_name: StringName, event: InputEvent) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)
	if event != null:
		InputMap.action_add_event(action_name, event)


func _mouse_button_text(button_index: int) -> String:
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


func _clean_key_label(label: String) -> String:
	return label.replace(" (Physical)", "").replace(" - Physical", "")
