extends RefCounted

const GAME_DATA_RES := "res://Resources/GameData.tres"
const AIM_ACTION := &"aim"
const MENU_WHEEL_BUTTONS := [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]

var _game_data: Resource
var _weapon_input_suppressed_target_id := -1
var _captured_action_events: Dictionary = {}
var _debug_logger := Callable()


func set_debug_logger(logger: Callable) -> void:
	_debug_logger = logger


func should_hide_for_aim(target: Dictionary) -> bool:
	return should_hide_for_weapon_input(target)


func should_hide_for_weapon_input(target: Dictionary) -> bool:
	var target_id := int(target.get("id", -1))
	if target_id == -1:
		clear_weapon_input_suppression()
		return false

	if _weapon_input_suppressed_target_id != -1 and _weapon_input_suppressed_target_id != target_id:
		clear_weapon_input_suppression()

	if _weapon_input_suppressed_target_id == target_id:
		return true

	if (
		_weapon_is_held()
		and (_aim_input_active() or _game_data_is_aiming() or _game_data_is_firing())
	):
		_weapon_input_suppressed_target_id = target_id
		return true

	return false


func handle_aim_input(event: InputEvent, current_target_id: int) -> bool:
	return handle_weapon_hide_input(event, current_target_id)


func handle_weapon_hide_input(event: InputEvent, current_target_id: int) -> bool:
	if current_target_id == -1:
		return false
	if not _weapon_is_held():
		return false
	if not _is_action_event_pressed(event, AIM_ACTION):
		return false

	_weapon_input_suppressed_target_id = current_target_id
	return true


func clear_aim_suppression() -> void:
	clear_weapon_input_suppression()


func clear_weapon_input_suppression() -> void:
	_weapon_input_suppressed_target_id = -1


func capture_menu_input(protected_actions: Array[StringName]) -> void:
	if not _captured_action_events.is_empty():
		return

	var menu_events := _menu_input_events(protected_actions)
	for action_variant in InputMap.get_actions():
		var action_name := action_variant as StringName
		if _is_protected_action(action_name, protected_actions):
			continue

		var action_events := InputMap.action_get_events(action_name)
		var kept_events: Array[InputEvent] = []
		var removed_events: Array[InputEvent] = []
		for event in action_events:
			if _event_conflicts_with_menu(event, menu_events):
				removed_events.append(event)
			else:
				kept_events.append(event)

		if removed_events.is_empty():
			continue

		_captured_action_events[action_name] = action_events
		InputMap.action_erase_events(action_name)
		for event in kept_events:
			InputMap.action_add_event(action_name, event)
		Input.action_release(action_name)
		_debug_log(
			(
				"[ContainerPeek][InputCapture] captured action=%s removed=%d kept=%d"
				% [String(action_name), removed_events.size(), kept_events.size()]
			)
		)


func restore_menu_input() -> void:
	if _captured_action_events.is_empty():
		return

	for action_name in _captured_action_events.keys():
		if not InputMap.has_action(action_name):
			continue
		InputMap.action_erase_events(action_name)
		for event in _captured_action_events[action_name]:
			InputMap.action_add_event(action_name, event)
		Input.action_release(action_name)
	var restored_count := _captured_action_events.size()
	_captured_action_events.clear()
	_debug_log("[ContainerPeek][InputCapture] restored actions=%d" % restored_count)


func _menu_input_events(protected_actions: Array[StringName]) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	for action_name in protected_actions:
		if InputMap.has_action(action_name):
			result.append_array(InputMap.action_get_events(action_name))

	for button_index in MENU_WHEEL_BUTTONS:
		var event := InputEventMouseButton.new()
		event.button_index = int(button_index)
		event.pressed = true
		result.append(event)
	return result


func _is_protected_action(action_name: StringName, protected_actions: Array[StringName]) -> bool:
	if action_name == AIM_ACTION:
		return true
	if protected_actions.has(action_name):
		return true
	return String(action_name).begins_with("container_peek_")


func _event_conflicts_with_menu(event: InputEvent, menu_events: Array[InputEvent]) -> bool:
	for menu_event in menu_events:
		if _events_match(event, menu_event):
			return true
	return false


func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a == null or b == null:
		return false

	if a is InputEventMouseButton and b is InputEventMouseButton:
		return (
			(a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index
		)

	return a.is_match(b, true) or b.is_match(a, true)


func _is_action_event_pressed(event: InputEvent, action_name: StringName) -> bool:
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	return event.is_action_pressed(action_name, false)


func _aim_input_active() -> bool:
	return InputMap.has_action(AIM_ACTION) and Input.is_action_pressed(AIM_ACTION)


func _game_data_is_aiming() -> bool:
	var game_data := _load_game_data()
	if game_data == null:
		return false

	var is_aiming: Variant = game_data.get("isAiming")
	return is_aiming != null and bool(is_aiming)


func _game_data_is_firing() -> bool:
	var game_data := _load_game_data()
	if game_data == null:
		return false

	var is_firing: Variant = game_data.get("isFiring")
	return is_firing != null and bool(is_firing)


func _weapon_is_held() -> bool:
	var game_data := _load_game_data()
	if game_data == null:
		return false

	var primary: Variant = game_data.get("primary")
	var secondary: Variant = game_data.get("secondary")
	return (primary != null and bool(primary)) or (secondary != null and bool(secondary))


func _load_game_data() -> Resource:
	if not ResourceLoader.exists(GAME_DATA_RES):
		return null
	if _game_data == null:
		_game_data = load(GAME_DATA_RES) as Resource
	return _game_data


func _debug_log(line: String) -> void:
	if not _debug_logger.is_valid():
		return
	_debug_logger.call(line)
