extends Node

const ConfigSupport = preload("res://ContainerPeek/ConfigSupport.gd")

const MOD_ID := "ContainerPeek"
const MOD_NAME := "Container Peek"
const CONFIG_DIR := "user://MCM/%s" % MOD_ID
const CONFIG_FILE := "config.ini"
const MCM_HELPERS_RES := "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"

const TRANSFER_ACTION := &"container_peek_transfer"
const TAKE_ALL_ACTION := &"container_peek_take_all"
const RARITY_COLORS_KEY := "rarity_colors"
const RUMMAGE_TIME_KEY := "rummage_seconds_per_item"

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
	return ConfigSupport.event_label(event)


func get_bool(setting_key: String, default_value: bool = false) -> bool:
	var value: Variant = _config.get_value("Bool", setting_key, default_value)
	if value is Dictionary:
		return bool((value as Dictionary).get("value", default_value))
	return bool(value)


func get_float(setting_key: String, default_value: float = 0.0) -> float:
	var value: Variant = _config.get_value("Float", setting_key, default_value)
	if value is Dictionary:
		value = (value as Dictionary).get("value", default_value)
	if value is float:
		return float(value)
	if value is int:
		return float(value)
	return default_value


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
	(
		config
		. set_value(
			"Bool",
			RARITY_COLORS_KEY,
			{
				"name": "Rarity Colors",
				"tooltip": "Color item names by rarity in the preview list.",
				"default": true,
				"value": true,
				"menu_pos": 30,
			}
		)
	)
	(
		config
		. set_value(
			"Float",
			RUMMAGE_TIME_KEY,
			{
				"name": "Rummage Time / Item",
				"tooltip": "Seconds each item row takes to appear the first time you inspect a container. Set to 0 to disable.",
				"default": 0.0,
				"value": 0.0,
				"minRange": 0.0,
				"maxRange": 2.0,
				"step": 0.05,
				"menu_pos": 40,
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
