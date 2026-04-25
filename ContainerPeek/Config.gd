extends Node

const ConfigSupport = preload("res://ContainerPeek/ConfigSupport.gd")

const MOD_ID := "ContainerPeek"
const MOD_NAME := "Container Peek"
const CONFIG_DIR := "user://MCM/%s" % MOD_ID
const CONFIG_FILE := "config.ini"
const MCM_HELPERS_RES := "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"
const XP_SKILLS_MAIN_RES := "res://mods/XPSkillsSystem/Main.gd"

const TRANSFER_ACTION := &"container_peek_transfer"
const TAKE_ALL_ACTION := &"container_peek_take_all"
const SORT_ACTION := &"container_peek_sort"
const CAPTURE_GAME_INPUT_KEY := "capture_game_input"
const RARITY_COLORS_KEY := "rarity_colors"
const SHOW_CATEGORY_ICONS_KEY := "show_category_icons"
const RUMMAGE_TIME_KEY := "rummage_seconds_per_item"
const RUMMAGE_AUDIO_KEY := "rummage_audio"
const ENABLE_IN_SHELTER_KEY := "enable_in_shelter"
const RUMMAGE_IN_SHELTER_KEY := "rummage_in_shelter"
const PANEL_OPACITY_KEY := "panel_opacity"
const XP_SKILLS_COMPAT_KEY := "xp_skills_compat"
const CURSOR_LOG_KEY := "debug_cursor_log"
const PERFORMANCE_LOG_KEY := "debug_performance_log"
const RARITY_COMMON_COLOR_KEY := "rarity_common_color"
const RARITY_RARE_COLOR_KEY := "rarity_rare_color"
const RARITY_LEGENDARY_COLOR_KEY := "rarity_legendary_color"
const SORT_MODE_SECTION := "State"
const SORT_MODE_KEY := "sort_mode"

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

	_reset_session_only_settings()

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


func get_color(setting_key: String, default_value: Color = Color(1.0, 1.0, 1.0, 1.0)) -> Color:
	var value: Variant = _config.get_value("Color", setting_key, default_value)
	if value is Dictionary:
		value = (value as Dictionary).get("value", default_value)
	if value is Color:
		return value
	return default_value


func get_int(section: String, setting_key: String, default_value: int = 0) -> int:
	var value: Variant = _config.get_value(section, setting_key, default_value)
	if value is Dictionary:
		value = (value as Dictionary).get("value", default_value)
	if value is int:
		return int(value)
	if value is float:
		return int(round(value))
	return default_value


func set_int(section: String, setting_key: String, value: int) -> void:
	_config.set_value(section, setting_key, value)
	_config.save(_config_path())


func _on_config_saved(config: ConfigFile) -> void:
	_config = config
	_apply_input_actions()


func _reset_session_only_settings() -> void:
	var changed := false
	for setting_key in [CURSOR_LOG_KEY, PERFORMANCE_LOG_KEY]:
		var value: Variant = _config.get_value("Bool", setting_key, false)
		if value is Dictionary:
			var data := (value as Dictionary).duplicate(true)
			if bool(data.get("value", false)):
				data["value"] = false
				_config.set_value("Bool", setting_key, data)
				changed = true
		elif bool(value):
			_config.set_value("Bool", setting_key, false)
			changed = true

	if changed:
		_config.save(_config_path())


func _load_mcm_helpers() -> Resource:
	if not ResourceLoader.exists(MCM_HELPERS_RES):
		return null
	return load(MCM_HELPERS_RES) as Resource


func _build_default_config() -> ConfigFile:
	var config := ConfigFile.new()
	var xp_skills_detected := _xp_skills_detected()
	var xp_skills_status := "Detected" if xp_skills_detected else "Not Detected"
	var xp_skills_tooltip := (
		(
			"Container Peek will trigger XP & Skills System search XP and scavenger"
			+ " bonuses from the popup window."
		)
		if xp_skills_detected
		else (
			"XP & Skills System was not detected. This toggle does nothing unless"
			+ " that mod is installed."
		)
	)
	(
		config
		. set_value(
			"Keycode",
			String(TRANSFER_ACTION),
			{
				"name": "Take Selected",
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
			"Keycode",
			String(SORT_ACTION),
			{
				"name": "Cycle Sort",
				"tooltip":
				"Cycle the preview list between name, rarity, weight, and value sorting.",
				"default": KEY_V,
				"default_type": "Key",
				"value": KEY_V,
				"type": "Key",
				"menu_pos": 30,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			CAPTURE_GAME_INPUT_KEY,
			{
				"name": "Capture Shared Inputs",
				"tooltip":
				(
					"Prevent game actions bound to the same keys or mouse buttons from"
					+ " firing while the peek menu uses them."
				),
				"default": true,
				"value": true,
				"menu_pos": 40,
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
				"menu_pos": 120,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			SHOW_CATEGORY_ICONS_KEY,
			{
				"name": "Show Category Icons",
				"tooltip": "Display item category icons in the preview list.",
				"default": true,
				"value": true,
				"menu_pos": 100,
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
				"tooltip":
				(
					"Seconds each item row takes to appear the first time you inspect a"
					+ " container. Set to 0 to disable."
				),
				"default": 0.5,
				"value": 0.5,
				"minRange": 0.0,
				"maxRange": 2.0,
				"step": 0.05,
				"menu_pos": 200,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			RUMMAGE_AUDIO_KEY,
			{
				"name": "Rummage Audio",
				"tooltip": "Play the rummaging sound effect while items are being revealed.",
				"default": true,
				"value": true,
				"menu_pos": 210,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			ENABLE_IN_SHELTER_KEY,
			{
				"name": "Enable In Shelter",
				"tooltip": "Allow the peek menu to appear while you are in the shelter.",
				"default": true,
				"value": true,
				"menu_pos": 300,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			RUMMAGE_IN_SHELTER_KEY,
			{
				"name": "Rummage In Shelter",
				"tooltip": "Allow rummaging delays while inspecting containers in the shelter.",
				"default": false,
				"value": false,
				"menu_pos": 310,
			}
		)
	)
	(
		config
		. set_value(
			"Float",
			PANEL_OPACITY_KEY,
			{
				"name": "Menu Opacity",
				"tooltip": "Opacity of the peek menu background. Does not affect text.",
				"default": 0.9,
				"value": 0.9,
				"minRange": 0.1,
				"maxRange": 1.0,
				"step": 0.05,
				"menu_pos": 110,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			XP_SKILLS_COMPAT_KEY,
			{
				"name": "XP & Skills Compat [%s]" % xp_skills_status,
				"tooltip": xp_skills_tooltip,
				"default": true,
				"value": true,
				"menu_pos": 400,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			CURSOR_LOG_KEY,
			{
				"name": "Cursor Debug Log",
				"tooltip":
				"Write cursor and viewport debug events to user://containerpeek_cursor.log.",
				"default": false,
				"value": false,
				"menu_pos": 900,
			}
		)
	)
	(
		config
		. set_value(
			"Bool",
			PERFORMANCE_LOG_KEY,
			{
				"name": "Performance Log",
				"tooltip":
				(
					"Write filtered timing data for the peek menu update path to"
					+ " user://containerpeek_perf.log."
				),
				"default": false,
				"value": false,
				"menu_pos": 910,
			}
		)
	)
	(
		config
		. set_value(
			"Color",
			RARITY_COMMON_COLOR_KEY,
			{
				"name": "Common Color",
				"tooltip": "Preview list color for common items.",
				"default": Color(1.0, 1.0, 1.0, 0.78),
				"value": Color(1.0, 1.0, 1.0, 0.78),
				"allowAlpha": true,
				"menu_pos": 130,
			}
		)
	)
	(
		config
		. set_value(
			"Color",
			RARITY_RARE_COLOR_KEY,
			{
				"name": "Rare Color",
				"tooltip": "Preview list color for rare items.",
				"default": Color.RED,
				"value": Color.RED,
				"allowAlpha": true,
				"menu_pos": 140,
			}
		)
	)
	(
		config
		. set_value(
			"Color",
			RARITY_LEGENDARY_COLOR_KEY,
			{
				"name": "Legendary Color",
				"tooltip": "Preview list color for legendary items.",
				"default": Color.DARK_VIOLET,
				"value": Color.DARK_VIOLET,
				"allowAlpha": true,
				"menu_pos": 150,
			}
		)
	)
	config.set_value(SORT_MODE_SECTION, SORT_MODE_KEY, 0)
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
	_set_action(SORT_ACTION, _input_event_from_data(_binding_data(SORT_ACTION)))


func _xp_skills_detected() -> bool:
	if Engine.get_meta("XPMain", null) != null:
		return true
	return ResourceLoader.exists(XP_SKILLS_MAIN_RES)


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
