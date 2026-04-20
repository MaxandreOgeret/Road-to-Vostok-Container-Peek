extends Node

const ConfigSupport = preload("res://ContainerPeek/ConfigSupport.gd")
const ItemSupport = preload("res://ContainerPeek/ItemSupport.gd")
const GAME_DATA_RES := "res://Resources/GameData.tres"
const UI_THEME_RES := "res://UI/Themes/Theme.tres"
const UI_TILE_RES := "res://UI/Sprites/Tile.png"
const PANEL_OFFSET := Vector2(18.0, 18.0)
const SCREEN_PAD := 12.0
const MAX_VISIBLE_ITEMS := 8
const ITEM_ROW_HEIGHT := 20
const ROW_SIDE_PAD := 2
const ROW_PREFIX_WIDTH := 16.0
const COL_SEPARATION := 8
const WEIGHT_COL_WIDTH := 56.0
const CONDITION_COL_WIDTH := 62.0
const TRANSFER_ACTION := &"container_peek_transfer"
const TAKE_ALL_ACTION := &"container_peek_take_all"
const RUMMAGE_TIME_KEY := "rummage_seconds_per_item"
const LOADING_FRAME_SECONDS := 0.2
const LOADING_DOTS := ["", ".", "..", "..."]

var _tracked: Dictionary = {}
var _game_data: Resource
var _selection_by_id: Dictionary = {}
var _rummage_progress_by_id: Dictionary = {}
var _current_target_id := -1
var _visible_item_names: Array = []
var _last_focus_node: Node3D
var _last_render_target_id := -1
var _last_render_selection := -1
var _last_render_visible_count := -1
var _last_render_total_count := -1
var _last_render_loading := false
var _last_render_rarity_colors := true
var _bootstrapped := false

var _canvas: CanvasLayer
var _panel: PanelContainer
var _title_label: Label
var _header_margin: MarginContainer
var _item_scroll: ScrollContainer
var _items_box: VBoxContainer
var _loading_label: Label
var _hint_label: Label
var _ui_host: Node
var _ui_theme: Theme
var _ui_tile: Texture2D
var _interactor: RayCast3D
var _hud: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _bootstrapped and not _runtime_ready():
		_teardown_runtime()
		return

	if not _bootstrapped:
		_try_bootstrap()
		return

	if _should_hide():
		_hide_panel()
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		_hide_panel()
		return

	var target := _target_from_interactor(cam)
	if target.is_empty():
		_hide_panel()
		return

	_show_panel(target, delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _bootstrapped:
		return
	if _panel == null:
		return
	if not _panel.visible or _current_target_id == -1:
		return

	if _is_action_event_pressed(event, TRANSFER_ACTION):
		if _try_transfer_selected():
			get_viewport().set_input_as_handled()
		return

	if _is_action_event_pressed(event, TAKE_ALL_ACTION):
		if _try_take_all_selected_container():
			get_viewport().set_input_as_handled()
		return

	if not (event is InputEventMouseButton):
		return

	var button := event as InputEventMouseButton
	if not button.pressed:
		return

	var direction := 0
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		direction = -1
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		direction = 1
	else:
		return

	var node := _tracked.get(_current_target_id, null)
	if not (node is Node):
		return

	var item_count := _visible_item_names.size()
	if item_count <= 0:
		return

	var current := int(_selection_by_id.get(_current_target_id, 0))
	_selection_by_id[_current_target_id] = posmod(current + direction, item_count)
	get_viewport().set_input_as_handled()


func _is_action_event_pressed(event: InputEvent, action_name: StringName) -> bool:
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	return event.is_action_pressed(action_name, false)


func _build_ui(host: Node) -> void:
	_ui_host = host
	_load_ui_assets()

	_canvas = CanvasLayer.new()
	_canvas.layer = 110
	_canvas.name = "ContainerPeekCanvas"
	host.add_child(_canvas)

	_panel = PanelContainer.new()
	_panel.theme = _ui_theme
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size = Vector2(320.0, 0.0)
	_canvas.add_child(_panel)

	var panel_style: StyleBox = _make_panel_style()
	_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	margin.add_child(root)

	var header := ColorRect.new()
	header.custom_minimum_size = Vector2(0.0, 28.0)
	header.color = Color(1.0, 1.0, 1.0, 0.05)
	root.add_child(header)

	_title_label = Label.new()
	_title_label.theme = _ui_theme
	_title_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 13)
	header.add_child(_title_label)

	_header_margin = MarginContainer.new()
	_header_margin.add_theme_constant_override("margin_left", ROW_SIDE_PAD)
	_header_margin.add_theme_constant_override("margin_right", ROW_SIDE_PAD)
	root.add_child(_header_margin)

	_header_margin.add_child(_make_header_row())

	_item_scroll = ScrollContainer.new()
	_item_scroll.theme = _ui_theme
	_item_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_item_scroll.custom_minimum_size = Vector2(0.0, float(MAX_VISIBLE_ITEMS * ITEM_ROW_HEIGHT))
	root.add_child(_item_scroll)

	_items_box = VBoxContainer.new()
	_items_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_box.add_theme_constant_override("separation", 2)
	_item_scroll.add_child(_items_box)

	_loading_label = Label.new()
	_loading_label.theme = _ui_theme
	_loading_label.visible = false
	_loading_label.add_theme_font_size_override("font_size", 12)
	_loading_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_loading_label)

	root.add_child(_make_divider())

	_hint_label = Label.new()
	_hint_label.theme = _ui_theme
	_hint_label.text = _hint_text()
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint_label)


func _load_ui_assets() -> void:
	if _ui_theme == null and ResourceLoader.exists(UI_THEME_RES):
		_ui_theme = load(UI_THEME_RES) as Theme
	if _ui_tile == null and ResourceLoader.exists(UI_TILE_RES):
		_ui_tile = load(UI_TILE_RES) as Texture2D


func _hint_text() -> String:
	return (
		"Wheel: Scroll   %s: Transfer   %s: Take All"
		% [
			ConfigSupport.binding_label(self, TRANSFER_ACTION),
			ConfigSupport.binding_label(self, TAKE_ALL_ACTION),
		]
	)


func _make_divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.color = Color(0.58, 0.65, 0.69, 0.25)
	divider.custom_minimum_size = Vector2(0.0, 1.0)
	return divider


func _make_panel_style() -> StyleBox:
	if _ui_tile != null:
		var style := StyleBoxTexture.new()
		style.texture = _ui_tile
		style.texture_margin_left = 1.0
		style.texture_margin_top = 1.0
		style.texture_margin_right = 1.0
		style.texture_margin_bottom = 1.0
		style.modulate_color = Color(1.0, 1.0, 1.0, 0.86)
		return style

	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.06, 0.06, 0.06, 0.92)
	fallback.border_color = Color(1.0, 1.0, 1.0, 0.18)
	fallback.border_width_left = 1
	fallback.border_width_top = 1
	fallback.border_width_right = 1
	fallback.border_width_bottom = 1
	return fallback


func _try_bootstrap() -> bool:
	var host := _resolve_ui_host()
	if host == null:
		return false

	if _canvas != null and is_instance_valid(_canvas):
		return false

	# The overlay only matters once the world UI and camera both exist.
	_build_ui(host)
	_interactor = _resolve_interactor()
	_bootstrapped = true
	return true


func _runtime_ready() -> bool:
	var host := _resolve_ui_host()
	if host == null:
		return false
	if _ui_host == null or host != _ui_host:
		return false
	if _canvas == null or not is_instance_valid(_canvas):
		return false
	return true


func _resolve_ui_host() -> Node:
	var tree := get_tree()
	if tree == null:
		return null

	var scene := tree.current_scene
	var interface_node := _resolve_interface_node()
	var camera := get_viewport().get_camera_3d()
	if scene == null or interface_node == null or camera == null:
		return null
	# Bind the overlay to the active scene so scene changes fully tear it down.
	if not scene.is_ancestor_of(interface_node):
		return null
	return scene


func _resolve_interactor() -> RayCast3D:
	if _interactor != null and is_instance_valid(_interactor):
		return _interactor

	var tree := get_tree()
	if tree == null:
		return null

	var scene := tree.current_scene
	if scene == null:
		return null

	var candidates := [
		"/root/Map/Core/Interactor",
		"Core/Interactor",
		"/root/Map/Core/Player/Interactor",
		"Core/Player/Interactor",
	]
	for path in candidates:
		var node := scene.get_node_or_null(path)
		if node is RayCast3D:
			_interactor = node as RayCast3D
			return _interactor

	_interactor = _find_interactor(scene)
	return _interactor


func _resolve_hud() -> Node:
	if _hud != null and is_instance_valid(_hud):
		return _hud

	var tree := get_tree()
	if tree == null:
		return null

	var scene := tree.current_scene
	if scene == null:
		return null

	var candidates := [
		"/root/Map/Core/UI/HUD",
		"Core/UI/HUD",
	]
	for path in candidates:
		var node := scene.get_node_or_null(path)
		if node != null:
			_hud = node
			return _hud

	return null


func _find_interactor(node: Node) -> RayCast3D:
	if node is RayCast3D and node.name == "Interactor":
		return node as RayCast3D
	for child in node.get_children():
		var found := _find_interactor(child)
		if found != null:
			return found
	return null


func _teardown_runtime() -> void:
	_hide_panel()
	_tracked.clear()
	_rummage_progress_by_id.clear()
	_last_focus_node = null
	_bootstrapped = false
	if _canvas != null and is_instance_valid(_canvas):
		_canvas.queue_free()
	_canvas = null
	_panel = null
	_title_label = null
	_header_margin = null
	_item_scroll = null
	_items_box = null
	_loading_label = null
	_hint_label = null
	_ui_host = null
	_interactor = null
	_hud = null


func _hide_panel() -> void:
	_current_target_id = -1
	_visible_item_names.clear()
	_last_focus_node = null
	_last_render_target_id = -1
	_last_render_selection = -1
	_last_render_visible_count = -1
	_last_render_total_count = -1
	_last_render_loading = false
	_last_render_rarity_colors = true
	if _panel == null:
		return
	_panel.visible = false
	if _loading_label != null:
		_loading_label.visible = false


func _show_panel(data: Dictionary, delta: float) -> void:
	if _panel == null or _title_label == null:
		return
	_current_target_id = int(data.get("id", -1))
	var focused := _tracked.get(_current_target_id, null)
	_last_focus_node = focused as Node3D if focused is Node3D else null
	_title_label.text = str(data.get("title", "Container"))
	if _hint_label != null:
		_hint_label.text = _hint_text()

	if _last_focus_node != null:
		var summaries := ItemSupport.item_summaries(_last_focus_node)
		_advance_rummage_progress(_current_target_id, summaries.size(), delta)
		if _should_rerender_rows(summaries.size()):
			_render_item_rows(_last_focus_node, summaries)
			_last_render_target_id = _current_target_id
			_last_render_selection = int(_selection_by_id.get(_current_target_id, 0))
			_last_render_visible_count = _visible_item_names.size()
			_last_render_total_count = summaries.size()
			_last_render_loading = _is_rummage_loading(_current_target_id, summaries.size())
			_last_render_rarity_colors = _rarity_colors_enabled()
		_update_loading_indicator(_visible_item_names.size(), summaries.size())
	else:
		_update_loading_indicator(0, 0)

	_panel.visible = true
	_panel.size = _panel.get_combined_minimum_size()
	_sync_header_alignment()

	var screen := get_viewport().get_visible_rect().size
	var pos := _cursor_screen_position() + PANEL_OFFSET
	pos.x = clampf(pos.x, SCREEN_PAD, screen.x - _panel.size.x - SCREEN_PAD)
	pos.y = clampf(pos.y, SCREEN_PAD, screen.y - _panel.size.y - SCREEN_PAD)
	_panel.position = pos


func _should_rerender_rows(total_item_count: int) -> bool:
	var visible_count := _revealed_item_count(_current_target_id, total_item_count)
	var loading := visible_count < total_item_count
	if _current_target_id != _last_render_target_id:
		return true
	if int(_selection_by_id.get(_current_target_id, 0)) != _last_render_selection:
		return true
	if visible_count != _last_render_visible_count:
		return true
	if total_item_count != _last_render_total_count:
		return true
	if loading != _last_render_loading:
		return true
	return _rarity_colors_enabled() != _last_render_rarity_colors


func _advance_rummage_progress(container_id: int, total_item_count: int, delta: float) -> void:
	if container_id == -1:
		return

	var delay := _rummage_seconds_per_item()
	var state := _rummage_progress_by_id.get(container_id, {})
	if delay <= 0.0 or total_item_count <= 0:
		state["elapsed"] = maxf(0.0, delay * float(total_item_count))
		state["completed"] = true
		_rummage_progress_by_id[container_id] = state
		return

	if bool(state.get("completed", false)):
		return

	var full_duration := delay * float(total_item_count)
	var elapsed := minf(full_duration, float(state.get("elapsed", 0.0)) + maxf(0.0, delta))
	state["elapsed"] = elapsed
	state["completed"] = elapsed >= full_duration
	_rummage_progress_by_id[container_id] = state


func _revealed_item_count(container_id: int, total_item_count: int) -> int:
	if total_item_count <= 0:
		return 0

	var delay := _rummage_seconds_per_item()
	if delay <= 0.0:
		return total_item_count

	var state := _rummage_progress_by_id.get(container_id, {})
	if bool(state.get("completed", false)):
		return total_item_count

	var elapsed := float(state.get("elapsed", 0.0))
	return clampi(int(floor(elapsed / delay)), 0, total_item_count)


func _is_rummage_loading(container_id: int, total_item_count: int) -> bool:
	return _revealed_item_count(container_id, total_item_count) < total_item_count


func _rummage_seconds_per_item() -> float:
	return maxf(0.0, ConfigSupport.float_setting(self, RUMMAGE_TIME_KEY, 0.0))


func _loading_animation_phase() -> int:
	return int(floor(float(Time.get_ticks_msec()) / (LOADING_FRAME_SECONDS * 1000.0))) % LOADING_DOTS.size()


func _loading_text(revealed_count: int, total_item_count: int) -> String:
	return "Rummaging%s  %d/%d" % [LOADING_DOTS[_loading_animation_phase()], revealed_count, total_item_count]


func _update_loading_indicator(revealed_count: int, total_item_count: int) -> void:
	if _loading_label == null:
		return
	var loading := revealed_count < total_item_count
	_loading_label.visible = loading
	if loading:
		_loading_label.text = _loading_text(revealed_count, total_item_count)


func _looks_like_container(node: Node) -> bool:
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


func _register_candidate(node: Node3D) -> void:
	var id := node.get_instance_id()
	_tracked[id] = node
	if not _selection_by_id.has(id):
		_selection_by_id[id] = 0


func _target_from_interactor(cam: Camera3D) -> Dictionary:
	var interactor := _resolve_interactor()
	if interactor == null:
		return {}
	if not interactor.is_colliding():
		return {}

	var collider: Variant = interactor.get_collider()
	if not (collider is Node):
		return {}

	var container_node := _resolve_container_from_node(collider as Node)
	if container_node == null:
		return {}

	var target_point := interactor.get_collision_point()
	var distance := cam.global_position.distance_to(target_point)
	if distance > ItemSupport.candidate_range(container_node):
		return {}
	if not _hud_allows_container(container_node):
		return {}

	return _build_target_data(container_node, distance)


func _hud_allows_container(container_node: Node3D) -> bool:
	var hud := _resolve_hud()
	if hud == null:
		return true

	var target_name := _normalize_prompt_text(_debug_name(container_node))
	if target_name.is_empty():
		return true

	return _hud_text_matches(hud, target_name)


func _hud_text_matches(node: Node, target_name: String) -> bool:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return false

	var text_value: Variant = node.get("text")
	if text_value is String:
		var text := _normalize_prompt_text(text_value as String)
		if not text.is_empty() and text.contains(target_name):
			return true

	for child in node.get_children():
		if _hud_text_matches(child, target_name):
			return true

	return false


func _normalize_prompt_text(text: String) -> String:
	return text.strip_edges().to_lower()


func _build_target_data(node: Node3D, distance: float) -> Dictionary:
	return {
		"id": node.get_instance_id(),
		"title": "%s  %.1fm" % [_debug_name(node), distance],
	}


func _tracked_container_ancestor(node: Node) -> Node3D:
	var current: Node = node
	var depth := 0
	while current != null and depth < 32:
		var tracked := _tracked.get(current.get_instance_id(), null)
		if tracked is Node3D and is_instance_valid(tracked):
			return tracked as Node3D
		current = current.get_parent()
		depth += 1
	return null


func _resolve_container_from_node(node: Node) -> Node3D:
	var tracked := _tracked_container_ancestor(node)
	if tracked != null:
		return tracked

	var current: Node = node
	var depth := 0
	while current != null and depth < 32:
		if current is Node3D and _looks_like_container(current):
			var container := current as Node3D
			_register_candidate(container)
			return container
		current = current.get_parent()
		depth += 1
	return null


func _render_item_rows(node: Node, summaries: Dictionary) -> void:
	if _items_box == null:
		return
	for child in _items_box.get_children():
		child.queue_free()

	if bool(node.get("locked")):
		_items_box.add_child(_make_row("LOCKED", false, true))

	if summaries.is_empty():
		_visible_item_names.clear()
		_items_box.add_child(_make_row("Empty", false, false))
		return

	var names: Array = summaries.keys()
	names.sort()
	var revealed_count := _revealed_item_count(node.get_instance_id(), names.size())
	var visible_names: Array = []
	for i in range(revealed_count):
		visible_names.append(names[i])
	_visible_item_names = visible_names

	var selected_index := int(_selection_by_id.get(node.get_instance_id(), 0))
	selected_index = clampi(selected_index, 0, maxi(visible_names.size() - 1, 0))
	_selection_by_id[node.get_instance_id()] = selected_index

	var selected_row: Control = null
	for i in range(visible_names.size()):
		var item_name := str(visible_names[i])
		var summary := summaries[item_name] as Dictionary
		var amount := int(summary.get("amount", 1))
		var line_text := "%s x%d" % [item_name, amount] if amount > 1 else item_name
		var row := _make_item_row(
			line_text,
			ItemSupport.format_weight(float(summary.get("weight", 0.0))),
			str(summary.get("condition", "--")),
			ItemSupport.rarity_color(
				str(summary.get("rarity", ItemSupport.RARITY_COMMON)), _rarity_colors_enabled()
			),
			i == selected_index
		)
		_items_box.add_child(row)
		if i == selected_index:
			selected_row = row

	if selected_row != null:
		call_deferred("_ensure_row_visible", selected_row)


func _make_row(text: String, selected: bool, status: bool) -> Control:
	var row := PanelContainer.new()
	row.theme = _ui_theme
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0.0, float(ITEM_ROW_HEIGHT))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style: StyleBox
	if selected:
		if _ui_tile != null:
			var textured := StyleBoxTexture.new()
			textured.texture = _ui_tile
			textured.texture_margin_left = 1.0
			textured.texture_margin_top = 1.0
			textured.texture_margin_right = 1.0
			textured.texture_margin_bottom = 1.0
			textured.modulate_color = Color(1.0, 1.0, 1.0, 0.32)
			style = textured
		else:
			var selected_fallback := StyleBoxFlat.new()
			selected_fallback.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style = selected_fallback
	else:
		var empty_style := StyleBoxEmpty.new()
		empty_style.content_margin_left = 2.0
		empty_style.content_margin_right = 2.0
		style = empty_style
	row.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.theme = _ui_theme
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = ("> " if selected else "  ") + text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	if status:
		label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.55, 1.0))
	elif selected:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
	row.add_child(label)
	return row


func _make_header_row() -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", COL_SEPARATION)

	var prefix_spacer := Control.new()
	prefix_spacer.custom_minimum_size = Vector2(ROW_PREFIX_WIDTH, 0.0)
	row.add_child(prefix_spacer)

	var item_label := Label.new()
	item_label.theme = _ui_theme
	item_label.text = "Item"
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_label.add_theme_font_size_override("font_size", 11)
	item_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	row.add_child(item_label)

	var weight_label := Label.new()
	weight_label.theme = _ui_theme
	weight_label.text = "Weight"
	weight_label.custom_minimum_size = Vector2(WEIGHT_COL_WIDTH, 0.0)
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weight_label.add_theme_font_size_override("font_size", 11)
	weight_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	row.add_child(weight_label)

	var condition_label := Label.new()
	condition_label.theme = _ui_theme
	condition_label.text = "Cond."
	condition_label.custom_minimum_size = Vector2(CONDITION_COL_WIDTH, 0.0)
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	condition_label.add_theme_font_size_override("font_size", 11)
	condition_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	row.add_child(condition_label)

	return row


func _make_item_row(
	text: String, weight_text: String, condition_text: String, rarity_color: Color, selected: bool
) -> Control:
	var row := PanelContainer.new()
	row.theme = _ui_theme
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0.0, float(ITEM_ROW_HEIGHT))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style: StyleBox
	if selected:
		if _ui_tile != null:
			var textured := StyleBoxTexture.new()
			textured.texture = _ui_tile
			textured.texture_margin_left = 1.0
			textured.texture_margin_top = 1.0
			textured.texture_margin_right = 1.0
			textured.texture_margin_bottom = 1.0
			textured.content_margin_left = ROW_SIDE_PAD
			textured.content_margin_right = ROW_SIDE_PAD
			textured.modulate_color = Color(1.0, 1.0, 1.0, 0.32)
			style = textured
		else:
			var selected_fallback := StyleBoxFlat.new()
			selected_fallback.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			selected_fallback.content_margin_left = ROW_SIDE_PAD
			selected_fallback.content_margin_right = ROW_SIDE_PAD
			style = selected_fallback
	else:
		var empty_style := StyleBoxEmpty.new()
		empty_style.content_margin_left = ROW_SIDE_PAD
		empty_style.content_margin_right = ROW_SIDE_PAD
		style = empty_style
	row.add_theme_stylebox_override("panel", style)

	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", COL_SEPARATION)
	row.add_child(box)

	var prefix_label := Label.new()
	prefix_label.theme = _ui_theme
	prefix_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prefix_label.text = ">" if selected else ""
	prefix_label.custom_minimum_size = Vector2(ROW_PREFIX_WIDTH, 0.0)
	prefix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prefix_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prefix_label.add_theme_font_size_override("font_size", 13)
	prefix_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.0)
	)
	box.add_child(prefix_label)

	var name_label := Label.new()
	name_label.theme = _ui_theme
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = text
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else rarity_color
	)
	box.add_child(name_label)

	var weight_label := Label.new()
	weight_label.theme = _ui_theme
	weight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weight_label.text = weight_text
	weight_label.custom_minimum_size = Vector2(WEIGHT_COL_WIDTH, 0.0)
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 12)
	weight_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.66)
	)
	box.add_child(weight_label)

	var condition_label := Label.new()
	condition_label.theme = _ui_theme
	condition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	condition_label.text = condition_text
	condition_label.custom_minimum_size = Vector2(CONDITION_COL_WIDTH, 0.0)
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	condition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	condition_label.add_theme_font_size_override("font_size", 12)
	condition_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.66)
	)
	box.add_child(condition_label)

	return row


func _sync_header_alignment() -> void:
	if _header_margin == null or _item_scroll == null:
		return

	var gutter := 0
	var v_scroll := _item_scroll.get_v_scroll_bar()
	if v_scroll != null and v_scroll.visible:
		gutter = int(ceil(v_scroll.size.x))

	_header_margin.add_theme_constant_override("margin_left", ROW_SIDE_PAD)
	_header_margin.add_theme_constant_override("margin_right", ROW_SIDE_PAD + gutter)


func _ensure_row_visible(row: Control) -> void:
	if row == null or not is_instance_valid(row) or _item_scroll == null:
		return

	await get_tree().process_frame
	if row == null or not is_instance_valid(row):
		return

	var row_top := row.position.y
	var row_bottom := row_top + row.size.y
	var visible_top := float(_item_scroll.scroll_vertical)
	var visible_bottom := visible_top + _item_scroll.size.y
	var target_scroll := _item_scroll.scroll_vertical

	if row_top < visible_top:
		target_scroll = int(row_top)
	elif row_bottom > visible_bottom:
		target_scroll = int(row_bottom - _item_scroll.size.y)

	_item_scroll.scroll_vertical = maxi(0, target_scroll)


func _rarity_colors_enabled() -> bool:
	return ConfigSupport.bool_setting(self, "rarity_colors", true)


func _cursor_screen_position() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return viewport.get_mouse_position()
	return viewport.get_visible_rect().size * 0.5


# Do not compete with the full inventory UI.
func _should_hide() -> bool:
	if get_tree().paused:
		return true
	return _interface_inventory_open()


func _interface_inventory_open() -> bool:
	if _game_data_interface_open():
		return true
	return _interface_node_is_open()


func _game_data_interface_open() -> bool:
	if not ResourceLoader.exists(GAME_DATA_RES):
		return false
	if _game_data == null:
		_game_data = load(GAME_DATA_RES) as Resource
	if _game_data == null:
		return false
	var flag: Variant = _game_data.get("interface")
	return flag != null and bool(flag)


func _interface_node_is_open() -> bool:
	var interface_node := _resolve_interface_node()
	if interface_node == null or not is_instance_valid(interface_node):
		return false
	if interface_node is CanvasItem:
		var canvas_item := interface_node as CanvasItem
		return canvas_item.visible and canvas_item.is_visible_in_tree()
	return false


func _debug_name(node: Node) -> String:
	var title := str(node.get("containerName")).strip_edges()
	if title.is_empty():
		title = str(node.name).strip_edges()
	if title.is_empty():
		title = "<unnamed>"
	return title


func _current_selected_item_name() -> String:
	if _current_target_id == -1 or _visible_item_names.is_empty():
		return ""

	var selected_index := int(_selection_by_id.get(_current_target_id, 0))
	selected_index = clampi(selected_index, 0, maxi(_visible_item_names.size() - 1, 0))
	return str(_visible_item_names[selected_index])


func _current_target_is_loading() -> bool:
	if _last_focus_node == null or not is_instance_valid(_last_focus_node) or _current_target_id == -1:
		return false
	return _is_rummage_loading(_current_target_id, ItemSupport.item_summaries(_last_focus_node).size())


func _try_transfer_selected() -> bool:
	if _last_focus_node != null and is_instance_valid(_last_focus_node):
		return _try_direct_selected_transfer(_last_focus_node)
	return false


# Stop on the first failed insert so partial take-all stays predictable when space runs out.
func _try_take_all_selected_container() -> bool:
	if _last_focus_node == null or not is_instance_valid(_last_focus_node):
		return false
	if _current_target_is_loading():
		return false

	var moved_any := false
	while true:
		var slots := ItemSupport.slot_source(_last_focus_node)
		if slots.is_empty():
			break
		if not _try_direct_slot_transfer(_last_focus_node, slots[0]):
			break
		moved_any = true

	if moved_any and _current_target_id != -1:
		_selection_by_id[_current_target_id] = 0
		_last_render_target_id = -1
	return moved_any


func _try_direct_selected_transfer(container_node: Node) -> bool:
	var item_name := _current_selected_item_name()
	var slot := ItemSupport.slot_for_item_name(container_node, item_name)
	if slot == null:
		return false
	return _try_direct_slot_transfer(container_node, slot)


# Reuse the game's Create path so item placement rules and failure feedback stay vanilla.
func _try_direct_slot_transfer(container_node: Node, slot: Variant) -> bool:
	var interface_node := _resolve_interface_node()
	if interface_node == null or slot == null:
		return false
	if not interface_node.has_method("Create"):
		return false

	var inventory_grid := _resolve_inventory_grid(interface_node)
	if inventory_grid == null:
		return false

	var created := bool(interface_node.call("Create", slot, inventory_grid, false))
	if not created:
		_play_error_beep(interface_node)
		return false

	ItemSupport.remove_slot_from_container(container_node, slot)
	_last_render_target_id = -1
	if interface_node.has_method("Reset"):
		interface_node.call("Reset")
	return true


func _play_error_beep(interface_node: Node) -> void:
	if interface_node.has_method("PlayError"):
		interface_node.call("PlayError")


func _resolve_interface_node() -> Node:
	var tree := get_tree()
	if tree == null:
		return null

	var scene := tree.current_scene
	if scene != null:
		var by_abs := scene.get_node_or_null("/root/Map/Core/UI/Interface")
		if by_abs != null:
			return by_abs
		var by_rel := scene.get_node_or_null("Core/UI/Interface")
		if by_rel != null:
			return by_rel

	var root := tree.root
	if root != null:
		return root.get_node_or_null("Map/Core/UI/Interface")
	return null


func _resolve_inventory_grid(interface_node: Node) -> Node:
	var by_prop: Variant = interface_node.get("inventoryGrid")
	if by_prop is Node:
		return by_prop as Node

	var inventory := interface_node.get_node_or_null("Inventory")
	if inventory != null:
		return inventory.get_node_or_null("Grid")
	return null
