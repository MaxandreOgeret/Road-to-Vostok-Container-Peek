extends Node

const ConfigSupport = preload("res://ContainerPeek/ConfigSupport.gd")
const ItemSupport = preload("res://ContainerPeek/ItemSupport.gd")
const ItemListState = preload("res://ContainerPeek/ItemListState.gd")
const PanelSupport = preload("res://ContainerPeek/PanelSupport.gd")
const TargetSupport = preload("res://ContainerPeek/TargetSupport.gd")
const XPSkillsCompat = preload("res://ContainerPeek/Compat/XPSkillsCompat.gd")
const GAME_DATA_RES := "res://Resources/GameData.tres"
const AUDIO_INSTANCE_2D_SCENE := preload("res://Resources/AudioInstance2D.tscn")
const RUMMAGE_AUDIO_EVENT := preload("res://Audio/Crafting/Craft_Generic.tres")
const CORPSE_RUMMAGE_AUDIO_FILE := "res://ContainerPeek/audio/container_peek_rummage_corpse.mp3"
const CORPSE_ZIPPER_AUDIO_FILES := [
	"res://ContainerPeek/audio/container_peek_zipper_0.mp3",
	"res://ContainerPeek/audio/container_peek_zipper_1.mp3",
	"res://ContainerPeek/audio/container_peek_zipper_2.mp3",
]
const AMMO_ICON_SVG_RES := "res://ContainerPeek/img/ammo.svg"
const UI_THEME_RES := "res://UI/Themes/Theme.tres"
const UI_TILE_RES := "res://UI/Sprites/Tile.png"
const CATEGORY_ICON_RES := {
	"consumables": "res://UI/Sprites/Icon_Starvation.png",
	"medical": "res://UI/Sprites/Icon_Health.png",
	"equipment": "res://UI/Sprites/Icon_Insulation.png",
	"weapons": "res://UI/Sprites/Icon_Weapon.png",
	"electronics": "res://UI/Sprites/Icon_Electronics.png",
	"misc": "res://UI/Sprites/Icon_Items.png",
	"furniture": "res://UI/Sprites/Icon_Object.png",
}
const PANEL_OFFSET := Vector2(18.0, 18.0)
const SCREEN_PAD := 12.0
const MAX_VISIBLE_ITEMS := 8
const ITEM_ROW_HEIGHT := 20
const ITEM_LIST_SEPARATION := 2
const ROW_SIDE_PAD := 2
const ICON_COL_WIDTH := 16.0
const ROW_PREFIX_WIDTH := 16.0
const ITEM_COL_MIN_WIDTH := 120.0
const COL_SEPARATION := 8
const WEIGHT_COL_WIDTH := 56.0
const CONDITION_COL_WIDTH := 62.0
const VALUE_COL_WIDTH := 60.0
const TRANSFER_ACTION := &"container_peek_transfer"
const TAKE_ALL_ACTION := &"container_peek_take_all"
const SORT_ACTION := &"container_peek_sort"
const RUMMAGE_TIME_KEY := "rummage_seconds_per_item"
const RUMMAGE_AUDIO_KEY := "rummage_audio"
const ENABLE_IN_SHELTER_KEY := "enable_in_shelter"
const RUMMAGE_IN_SHELTER_KEY := "rummage_in_shelter"
const PANEL_OPACITY_KEY := "panel_opacity"
const XP_SKILLS_COMPAT_KEY := "xp_skills_compat"
const SHOW_CATEGORY_ICONS_KEY := "show_category_icons"
const RARITY_COMMON_COLOR_KEY := "rarity_common_color"
const RARITY_RARE_COLOR_KEY := "rarity_rare_color"
const RARITY_LEGENDARY_COLOR_KEY := "rarity_legendary_color"
const LOADING_FRAME_SECONDS := 0.2
const LOADING_SPINNER_FRAMES := ["|", "/", "-", "\\"]
const PLACEHOLDER_BAR_HEIGHT := 8.0
const RUMMAGE_AUDIO_MIN_OFFSET := 1.0
const RUMMAGE_AUDIO_END_PAD := 0.05
const SORT_MODE_NAME := 0
const SORT_MODE_RARITY := 1
const SORT_MODE_WEIGHT := 2
const SORT_MODE_VALUE := 3
const SORT_MODE_SECTION := "State"
const SORT_MODE_KEY := "sort_mode"
const DEBUG_CURSOR_LOG := true
const DEBUG_CURSOR_LOG_PATH := "user://containerpeek_cursor.log"

var _tracked: Dictionary = {}
var _game_data: Resource
var _item_list := ItemListState.new()
var _item_list_model: Dictionary = {}
var _rummage_progress_by_id: Dictionary = {}
var _xp_skills_notified_by_id: Dictionary = {}
var _placeholder_blocks: Array = []
var _current_target_id := -1
var _visible_item_names: Array = []
var _rendered_item_rows: Array = []
var _rendered_placeholder_row: Control
var _last_focus_node: Node3D
var _last_focus_title := ""
var _last_render_target_id := -1
var _last_render_selection := -1
var _last_render_state: Dictionary = {}
var _cached_summary_target_id := -1
var _cached_summary_signature := ""
var _cached_summaries: Dictionary = {}
var _cached_item_col_width := -1.0
var _bootstrapped := false
var _sort_mode := SORT_MODE_NAME
var _rendered_row_start := -1
var _rendered_row_end := -1
var _scroll_to_top_on_render := false
var _last_panel_opacity := -1.0
var _last_hint_text := ""
var _last_title_text := ""
var _last_header_gutter := -1
var _last_icons_enabled := true
var _layout_dirty := true
var _debug_last_target_scroll := -1
var _debug_last_scroll_control_name := ""
var _debug_last_scroll_control_index := -1
var _debug_last_scroll_control_role := ""
var _debug_last_top_spacer_height := 0.0
var _debug_last_bottom_spacer_height := 0.0
var _debug_last_render_window_size := 0
var _debug_last_visible_window_size := 0

var _canvas: CanvasLayer
var _panel: PanelContainer
var _title_label: Label
var _header_bar: ColorRect
var _header_margin: MarginContainer
var _header_item_label: Label
var _header_row: Control
var _item_scroll: ScrollContainer
var _items_box: VBoxContainer
var _loading_row: HBoxContainer
var _loading_label: Label
var _loading_spinner_label: Label
var _divider_bar: ColorRect
var _hint_label: Label
var _ui_host: Node
var _ui_theme: Theme
var _ui_tile: Texture2D
var _category_icons: Dictionary = {}
var _item_font: Font
var _numeric_font: Font
var _item_font_size := 13
var _item_text_width_cache: Dictionary = {}
var _interactor: RayCast3D
var _hud: Node
var _hud_text_nodes: Array = []
var _rummage_audio: AudioStreamPlayer
var _corpse_rummage_stream: AudioStream
var _corpse_zipper_streams: Array = []
var _selected_row_style: StyleBox
var _plain_row_style: StyleBox
var _scroll_request_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_item_list.set_debug_enabled(DEBUG_CURSOR_LOG, DEBUG_CURSOR_LOG_PATH)
	_sort_mode = clampi(
		ConfigSupport.int_setting(self, SORT_MODE_SECTION, SORT_MODE_KEY, SORT_MODE_NAME),
		SORT_MODE_NAME,
		SORT_MODE_VALUE
	)


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
	if _shelter_disables_mod():
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
	elif _is_action_event_pressed(event, TAKE_ALL_ACTION):
		if _try_take_all_selected_container():
			get_viewport().set_input_as_handled()
	elif _is_action_event_pressed(event, SORT_ACTION):
		_cycle_sort_mode()
		get_viewport().set_input_as_handled()
	else:
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
		if direction == 0:
			return

		var node := _tracked.get(_current_target_id, null)
		if not (node is Node) or _visible_item_names.is_empty():
			return

		_debug_append_cursor_log(
			(
				"[ContainerPeek][Input] wheel id=%d dir=%d visible=%d selected='%s'"
				% [
					_current_target_id,
					direction,
					_visible_item_names.size(),
					str(_item_list_model.get("selected_name", "")),
				]
			)
		)
		if not _item_list.move_selection(
			_current_target_id, _visible_item_names, direction, MAX_VISIBLE_ITEMS
		):
			return
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

	var panel_style: StyleBox = PanelSupport.make_panel_style(_ui_tile, _panel_opacity())
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

	_header_bar = ColorRect.new()
	_header_bar.custom_minimum_size = Vector2(0.0, 28.0)
	root.add_child(_header_bar)

	_title_label = Label.new()
	_title_label.theme = _ui_theme
	_title_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 13)
	_header_bar.add_child(_title_label)

	_header_margin = MarginContainer.new()
	_header_margin.add_theme_constant_override("margin_left", ROW_SIDE_PAD)
	_header_margin.add_theme_constant_override("margin_right", ROW_SIDE_PAD)
	root.add_child(_header_margin)

	var header_data := PanelSupport.make_header_row(
		_ui_theme,
		_icon_col_width(),
		ROW_PREFIX_WIDTH,
		ITEM_COL_MIN_WIDTH,
		COL_SEPARATION,
		WEIGHT_COL_WIDTH,
		CONDITION_COL_WIDTH,
		VALUE_COL_WIDTH,
		_numeric_column_font()
	)
	_header_item_label = header_data.get("item_label", null) as Label
	_header_row = header_data.get("row") as Control
	_header_margin.add_child(_header_row)

	_item_scroll = ScrollContainer.new()
	_item_scroll.theme = _ui_theme
	_item_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_item_scroll.custom_minimum_size = Vector2(0.0, float(MAX_VISIBLE_ITEMS * ITEM_ROW_HEIGHT))
	_item_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_item_scroll)

	_items_box = VBoxContainer.new()
	_items_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_box.add_theme_constant_override("separation", ITEM_LIST_SEPARATION)
	_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_scroll.add_child(_items_box)

	_loading_row = HBoxContainer.new()
	_loading_row.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_loading_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_loading_row.add_theme_constant_override("separation", 6)
	root.add_child(_loading_row)

	_loading_label = Label.new()
	_loading_label.theme = _ui_theme
	_loading_label.text = "Rummaging"
	_loading_label.add_theme_font_size_override("font_size", 12)
	_loading_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	_loading_row.add_child(_loading_label)

	_loading_spinner_label = Label.new()
	_loading_spinner_label.theme = _ui_theme
	_loading_spinner_label.text = LOADING_SPINNER_FRAMES[0]
	_loading_spinner_label.custom_minimum_size = Vector2(10.0, 0.0)
	_loading_spinner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_spinner_label.add_theme_font_size_override("font_size", 12)
	_loading_spinner_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.72))
	_loading_row.add_child(_loading_spinner_label)

	_divider_bar = PanelSupport.make_divider()
	root.add_child(_divider_bar)

	_hint_label = Label.new()
	_hint_label.theme = _ui_theme
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint_label)
	_refresh_panel_style_if_needed()
	_refresh_hint_if_needed()


func _load_ui_assets() -> void:
	if _ui_theme == null and ResourceLoader.exists(UI_THEME_RES):
		_ui_theme = load(UI_THEME_RES) as Theme
	if _ui_tile == null and ResourceLoader.exists(UI_TILE_RES):
		_ui_tile = load(UI_TILE_RES) as Texture2D
	_load_category_icons()


func _load_category_icons() -> void:
	if not _category_icons.has("ammo"):
		var ammo_icon := _load_svg_icon(AMMO_ICON_SVG_RES)
		if ammo_icon != null:
			_category_icons["ammo"] = ammo_icon
	for key in CATEGORY_ICON_RES.keys():
		if _category_icons.has(key):
			continue
		var path := str(CATEGORY_ICON_RES[key])
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				_category_icons[key] = texture


func _load_svg_icon(path: String) -> Texture2D:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var svg_text := file.get_as_text()
	if svg_text.is_empty():
		return null
	return DPITexture.create_from_string(svg_text)


func _row_icon_for_item_type(item_type: String) -> Texture2D:
	if not _show_category_icons():
		return null
	var category := _item_category(item_type)
	if category.is_empty():
		return null
	return _category_icons.get(category, null) as Texture2D


func _icon_col_width() -> float:
	return ICON_COL_WIDTH if _show_category_icons() else 0.0


func _item_category(item_type: String) -> String:
	match item_type:
		"Consumable", "Consumables", "Fish":
			return "consumables"
		"Medical":
			return "medical"
		"Armor", "Backpack", "Belt Pouch", "Clothing", "Helmet", "Rig":
			return "equipment"
		"Ammo":
			return "ammo"
		"Attachment", "Grenade", "Knife", "Weapon":
			return "weapons"
		"Electronics":
			return "electronics"
		"Furniture":
			return "furniture"
		"Fishing", "Instrument", "Key", "Literature", "Lore", "Misc", " Misc":
			return "misc"
		_:
			return "misc"


func _hint_text() -> String:
	return (
		"Wheel: Scroll   %s: Take   %s: Take All   %s: Sort (%s)"
		% [
			ConfigSupport.binding_label(self, TRANSFER_ACTION),
			ConfigSupport.binding_label(self, TAKE_ALL_ACTION),
			ConfigSupport.binding_label(self, SORT_ACTION),
			_sort_mode_label(),
		]
	)


func _panel_opacity() -> float:
	return clampf(ConfigSupport.float_setting(self, PANEL_OPACITY_KEY, 0.9), 0.1, 1.0)


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
			_hud_text_nodes.clear()
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
	_xp_skills_notified_by_id.clear()
	_placeholder_blocks.clear()
	_last_focus_node = null
	_last_focus_title = ""
	_bootstrapped = false
	if _canvas != null and is_instance_valid(_canvas):
		_canvas.queue_free()
	_canvas = null
	_panel = null
	_title_label = null
	_header_margin = null
	_header_item_label = null
	_header_row = null
	_item_scroll = null
	_items_box = null
	_loading_row = null
	_loading_label = null
	_loading_spinner_label = null
	_hint_label = null
	_ui_host = null
	_interactor = null
	_hud = null
	_hud_text_nodes.clear()
	_rummage_audio = null
	_corpse_rummage_stream = null
	_corpse_zipper_streams.clear()
	_item_font = null
	_numeric_font = null
	_item_text_width_cache.clear()
	_selected_row_style = null
	_plain_row_style = null
	_last_panel_opacity = -1.0
	_last_hint_text = ""
	_last_title_text = ""
	_last_header_gutter = -1
	_last_icons_enabled = true
	_scroll_to_top_on_render = false
	_item_list.reset()
	_item_list_model.clear()
	_layout_dirty = true


func _hide_panel() -> void:
	_current_target_id = -1
	_visible_item_names.clear()
	_rendered_item_rows.clear()
	_rendered_placeholder_row = null
	_placeholder_blocks.clear()
	_rendered_row_start = -1
	_rendered_row_end = -1
	_scroll_to_top_on_render = false
	_item_list.reset()
	_item_list_model.clear()
	_stop_rummage_sound()
	_last_focus_node = null
	_last_render_target_id = -1
	_last_render_selection = -1
	_last_render_state.clear()
	_invalidate_summary_cache()
	if _panel == null:
		return
	_panel.visible = false
	if _loading_row != null:
		_loading_row.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _show_panel(data: Dictionary, delta: float) -> void:
	if _panel == null or _title_label == null:
		return
	_refresh_panel_style_if_needed()
	var next_target_id := int(data.get("id", -1))
	var target_changed := _current_target_id != next_target_id
	_current_target_id = next_target_id
	if target_changed:
		_invalidate_summary_cache()
		_reset_view_for_target_change(_current_target_id)
	var focused := _tracked.get(_current_target_id, null)
	_last_focus_node = focused as Node3D if focused is Node3D else null
	_last_focus_title = str(data.get("title", "Container"))
	_refresh_title(_last_focus_title)
	_refresh_hint_if_needed()
	_refresh_header_if_needed()

	if _last_focus_node != null:
		var summaries := _current_summaries(_last_focus_node)
		_advance_rummage_progress(_current_target_id, summaries.size(), delta)
		_maybe_notify_xp_skills_open(_last_focus_node)
		_item_list_model = _item_list.derive_state(
			_current_target_id,
			summaries,
			_cached_summary_signature,
			_revealed_item_count(_current_target_id, summaries.size()),
			_sort_mode,
			MAX_VISIBLE_ITEMS
		)
		_visible_item_names = _item_list_model.get("visible_names", []) as Array
		var selection_changed := (
			int(_item_list_model.get("selected_index", -1)) != _last_render_selection
		)
		var render_state := _build_render_state(summaries, _cached_summary_signature)
		if _should_rerender_rows(render_state) or selection_changed:
			_render_item_rows(_last_focus_node, summaries)
			_last_render_target_id = _current_target_id
			_remember_render_state(render_state)
		_last_render_selection = int(_item_list_model.get("selected_index", -1))
		_update_loading_indicator(summaries.size())
	else:
		_item_list_model.clear()
		_update_loading_indicator(0)

	_panel.visible = true
	_refresh_layout_if_needed()
	_position_panel()


func _refresh_panel_style_if_needed() -> void:
	var panel_opacity := _panel_opacity()
	if is_equal_approx(panel_opacity, _last_panel_opacity):
		return

	_last_panel_opacity = panel_opacity
	if _panel != null:
		_panel.add_theme_stylebox_override(
			"panel", PanelSupport.make_panel_style(_ui_tile, panel_opacity)
		)
	if _header_bar != null:
		_header_bar.color = Color(1.0, 1.0, 1.0, 0.05 * panel_opacity)
	if _divider_bar != null:
		_divider_bar.color = Color(0.58, 0.65, 0.69, 0.25 * panel_opacity)
	_layout_dirty = true


func _refresh_title(title: String) -> void:
	if _title_label == null or _last_title_text == title:
		return
	_last_title_text = title
	_title_label.text = title
	_layout_dirty = true


func _refresh_hint_if_needed() -> void:
	if _hint_label == null:
		return

	var hint_text := _hint_text()
	if _last_hint_text == hint_text:
		return

	_last_hint_text = hint_text
	_hint_label.text = hint_text
	_layout_dirty = true


func _refresh_header_if_needed() -> void:
	var icons_enabled := _show_category_icons()
	if icons_enabled == _last_icons_enabled:
		return
	_last_icons_enabled = icons_enabled
	_rebuild_header_row()
	_layout_dirty = true


func _rebuild_header_row() -> void:
	if _header_margin == null:
		return
	if _header_row != null and is_instance_valid(_header_row):
		_header_margin.remove_child(_header_row)
		_header_row.queue_free()

	var header_data := PanelSupport.make_header_row(
		_ui_theme,
		_icon_col_width(),
		ROW_PREFIX_WIDTH,
		maxf(_cached_item_col_width, ITEM_COL_MIN_WIDTH),
		COL_SEPARATION,
		WEIGHT_COL_WIDTH,
		CONDITION_COL_WIDTH,
		VALUE_COL_WIDTH,
		_numeric_column_font()
	)
	_header_item_label = header_data.get("item_label", null) as Label
	_header_row = header_data.get("row") as Control
	_header_margin.add_child(_header_row)


func _refresh_layout_if_needed() -> void:
	if _panel == null:
		return
	if _layout_dirty:
		_panel.reset_size()
		_panel.size = _panel.get_combined_minimum_size()
		_sync_header_alignment()
		_layout_dirty = false


func _position_panel() -> void:
	if _panel == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var pos := _cursor_screen_position() + PANEL_OFFSET
	pos.x = clampf(pos.x, SCREEN_PAD, screen.x - _panel.size.x - SCREEN_PAD)
	pos.y = clampf(pos.y, SCREEN_PAD, screen.y - _panel.size.y - SCREEN_PAD)
	_panel.position = pos


func _queue_clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _build_render_state(summaries: Dictionary, summary_signature: String) -> Dictionary:
	return {
		"visible_count": _visible_item_names.size(),
		"total_count": summaries.size(),
		"window_start": int(_item_list_model.get("window_start", 0)),
		"window_end": int(_item_list_model.get("window_end", 0)),
		"render_placeholder": bool(_item_list_model.get("render_placeholder", false)),
		"summary_signature": summary_signature,
		"loading": _is_rummage_loading(_current_target_id),
		"rarity_colors": _rarity_colors_enabled(),
		"show_icons": _show_category_icons(),
		"rarity_signature": _rarity_color_signature(),
		"sort_mode": _sort_mode,
	}


func _remember_render_state(render_state: Dictionary) -> void:
	_last_render_state = render_state.duplicate(true)


func _current_summaries(node: Node) -> Dictionary:
	if _cached_summary_target_id != _current_target_id:
		_cached_summaries = ItemSupport.item_summaries(node)
		_cached_summary_target_id = _current_target_id
		_cached_summary_signature = _summaries_signature(_cached_summaries)
	return _cached_summaries


func _invalidate_summary_cache() -> void:
	_cached_summary_target_id = -1
	_cached_summary_signature = ""
	_cached_summaries.clear()
	_cached_item_col_width = -1.0


func _should_rerender_rows(render_state: Dictionary) -> bool:
	if _current_target_id != _last_render_target_id:
		return true
	for key in render_state.keys():
		if render_state.get(key) != _last_render_state.get(key):
			return true
	return false


func _advance_rummage_progress(container_id: int, total_item_count: int, delta: float) -> void:
	if container_id == -1:
		_stop_rummage_sound()
		return

	var delay := _rummage_seconds_per_item()
	var state := _rummage_state(container_id)
	var progress_units := _rummage_progress_units(total_item_count)
	if delay <= 0.0:
		_stop_rummage_sound()
		state["elapsed"] = 0.0 if total_item_count <= 0 else delay * float(progress_units)
		state["completed"] = true
		_store_rummage_state(container_id, state)
		return

	if bool(state.get("completed", false)):
		_stop_rummage_sound()
		return

	_ensure_rummage_sound_playing()

	var full_duration := delay * float(progress_units)
	var previous_elapsed := float(state.get("elapsed", 0.0))
	var elapsed := minf(full_duration, previous_elapsed + maxf(0.0, delta))
	state["elapsed"] = elapsed
	_maybe_play_rummage_zipper(state, total_item_count, previous_elapsed, elapsed, delay)
	state["completed"] = elapsed >= full_duration
	if bool(state.get("completed", false)):
		_stop_rummage_sound()
	_store_rummage_state(container_id, state)


func _rummage_state(container_id: int) -> Dictionary:
	return _rummage_progress_by_id.get(container_id, {})


func _store_rummage_state(container_id: int, state: Dictionary) -> void:
	_rummage_progress_by_id[container_id] = state


func _revealed_item_count(container_id: int, total_item_count: int) -> int:
	if total_item_count <= 0:
		return 0

	var delay := _rummage_seconds_per_item()
	if delay <= 0.0:
		return total_item_count

	var state := _rummage_state(container_id)
	if bool(state.get("completed", false)):
		return total_item_count

	var elapsed := float(state.get("elapsed", 0.0))
	return clampi(int(floor(elapsed / delay)), 0, total_item_count)


func _is_rummage_loading(container_id: int) -> bool:
	if _rummage_seconds_per_item() <= 0.0:
		return false
	var state := _rummage_state(container_id)
	return not bool(state.get("completed", false))


func _rummage_progress_units(total_item_count: int) -> int:
	return maxi(1, total_item_count)


func _rummage_seconds_per_item() -> float:
	if _shelter_bypasses_rummaging():
		return 0.0
	return maxf(0.0, ConfigSupport.float_setting(self, RUMMAGE_TIME_KEY, 0.5))


func _shelter_disables_mod() -> bool:
	return _in_shelter() and not ConfigSupport.bool_setting(self, ENABLE_IN_SHELTER_KEY, true)


func _shelter_bypasses_rummaging() -> bool:
	return _in_shelter() and not ConfigSupport.bool_setting(self, RUMMAGE_IN_SHELTER_KEY, false)


func _in_shelter() -> bool:
	if not ResourceLoader.exists(GAME_DATA_RES):
		return false
	if _game_data == null:
		_game_data = load(GAME_DATA_RES) as Resource
	if _game_data == null:
		return false

	var shelter: Variant = _game_data.get("shelter")
	return shelter != null and bool(shelter)


func _ensure_rummage_sound_playing() -> void:
	if _rummage_audio != null and is_instance_valid(_rummage_audio) and _rummage_audio.is_playing():
		return
	_play_rummage_sound()


func _maybe_play_rummage_zipper(
	state: Dictionary, total_item_count: int, previous_elapsed: float, elapsed: float, delay: float
) -> void:
	if not _is_corpse_focus():
		return
	if total_item_count <= 0 or delay <= 0.0:
		return
	var previous_revealed := clampi(int(floor(previous_elapsed / delay)), 0, total_item_count)
	var revealed := clampi(int(floor(elapsed / delay)), 0, total_item_count)
	if revealed <= previous_revealed:
		return
	var last_zipper_reveal := int(state.get("last_zipper_reveal", 0))
	var start_reveal := maxi(previous_revealed, last_zipper_reveal)
	for reveal_index in range(start_reveal, revealed):
		if randf() < 0.1:
			_play_random_zipper_sound()
	state["last_zipper_reveal"] = revealed


func _play_rummage_sound() -> void:
	if not ConfigSupport.bool_setting(self, RUMMAGE_AUDIO_KEY, true):
		_stop_rummage_sound()
		return

	if _rummage_audio != null and is_instance_valid(_rummage_audio):
		if _rummage_audio.is_playing():
			return
		_rummage_audio.queue_free()
		_rummage_audio = null

	var tree := get_tree()
	if tree == null:
		return

	var audio := AUDIO_INSTANCE_2D_SCENE.instantiate()
	if audio == null:
		return

	if _is_corpse_focus():
		var corpse_stream := _load_corpse_rummage_stream()
		if corpse_stream == null:
			_stop_rummage_sound()
			return
		var corpse_audio := AudioStreamPlayer.new()
		if corpse_audio == null:
			return
		tree.get_root().add_child(corpse_audio)
		_rummage_audio = corpse_audio
		_rummage_audio.stream = corpse_stream
		_rummage_audio.play()
		_seek_rummage_sound_random_offset()
		return

	if AUDIO_INSTANCE_2D_SCENE == null or RUMMAGE_AUDIO_EVENT == null:
		_stop_rummage_sound()
		return
	tree.get_root().add_child(audio)
	_rummage_audio = audio as AudioStreamPlayer
	if audio.has_method("PlayInstance"):
		audio.call("PlayInstance", RUMMAGE_AUDIO_EVENT)
		_seek_rummage_sound_random_offset()


func _stop_rummage_sound() -> void:
	if _rummage_audio == null or not is_instance_valid(_rummage_audio):
		_rummage_audio = null
		return

	_rummage_audio.stop()
	_rummage_audio.queue_free()
	_rummage_audio = null


func _maybe_notify_xp_skills_open(container_node: Node3D) -> void:
	if not _xp_skills_compat_enabled():
		return
	if container_node == null or not is_instance_valid(container_node):
		return

	var container_id := container_node.get_instance_id()
	if bool(_xp_skills_notified_by_id.get(container_id, false)):
		return
	if _is_rummage_loading(container_id):
		return

	_xp_skills_notified_by_id[container_id] = true
	if XPSkillsCompat.notify_container_open(container_node, _resolve_ui_root()):
		_invalidate_summary_cache()


func _seek_rummage_sound_random_offset() -> void:
	if _rummage_audio == null or not is_instance_valid(_rummage_audio):
		return
	if _rummage_audio.stream == null:
		return

	var clip_length := _rummage_audio.stream.get_length()
	var max_offset := clip_length - RUMMAGE_AUDIO_END_PAD
	if max_offset <= RUMMAGE_AUDIO_MIN_OFFSET:
		return

	_rummage_audio.seek(randf_range(RUMMAGE_AUDIO_MIN_OFFSET, max_offset))


func _load_corpse_rummage_stream() -> AudioStream:
	if _corpse_rummage_stream != null:
		return _corpse_rummage_stream
	_corpse_rummage_stream = _load_mp3_stream(CORPSE_RUMMAGE_AUDIO_FILE)
	if _corpse_rummage_stream != null:
		return _corpse_rummage_stream
	return null


func _random_zipper_stream() -> AudioStream:
	if _corpse_zipper_streams.is_empty():
		for path in CORPSE_ZIPPER_AUDIO_FILES:
			var stream := _load_mp3_stream(path)
			if stream != null:
				_corpse_zipper_streams.append(stream)
	if _corpse_zipper_streams.is_empty():
		return null
	return _corpse_zipper_streams[randi() % _corpse_zipper_streams.size()] as AudioStream


func _play_random_zipper_sound() -> void:
	var stream := _random_zipper_stream()
	if stream == null:
		return
	var tree := get_tree()
	if tree == null:
		return
	var audio := AudioStreamPlayer.new()
	if audio == null:
		return
	audio.stream = stream
	tree.get_root().add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


func _load_mp3_stream(path: String) -> AudioStreamMP3:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	return stream


func _is_corpse_focus() -> bool:
	if _last_focus_node != null and TargetSupport.is_corpse(_last_focus_node):
		return true
	return TargetSupport.is_corpse_title(_last_focus_title)


func _loading_animation_phase() -> int:
	return (
		int(floor(float(Time.get_ticks_msec()) / (LOADING_FRAME_SECONDS * 1000.0)))
		% LOADING_SPINNER_FRAMES.size()
	)


func _loading_spinner_text() -> String:
	return LOADING_SPINNER_FRAMES[_loading_animation_phase()]


func _update_loading_indicator(_total_item_count: int) -> void:
	if _loading_row == null or _loading_label == null or _loading_spinner_label == null:
		return
	var loading := _is_rummage_loading(_current_target_id)
	if not loading:
		_stop_rummage_sound()
	_loading_row.modulate = Color(1.0, 1.0, 1.0, 1.0 if loading else 0.0)
	if loading:
		_loading_spinner_label.text = _loading_spinner_text()
		_sync_placeholder_animation()


func _summaries_signature(summaries: Dictionary) -> String:
	if summaries.is_empty():
		return ""

	var names: Array = summaries.keys()
	names.sort()
	var signature := ""
	for item_name in names:
		var summary := summaries[item_name] as Dictionary
		signature += (
			"%s|%d|%.3f|%d|%s|%s|%s\n"
			% [
				str(item_name),
				int(summary.get("amount", 0)),
				float(summary.get("weight", 0.0)),
				int(summary.get("value", 0)),
				str(summary.get("condition", "")),
				str(summary.get("rarity", ItemSupport.RARITY_COMMON)),
				str(summary.get("type", "")),
			]
		)
	return signature


func _sync_placeholder_animation() -> void:
	var tint := _placeholder_tint()
	for block in _placeholder_blocks:
		if block is ColorRect and is_instance_valid(block):
			(block as ColorRect).color = tint


func _placeholder_tint() -> Color:
	var pulse := 0.22 + 0.08 * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008))
	return Color(1.0, 1.0, 1.0, pulse)


func _register_candidate(node: Node3D) -> void:
	var id := node.get_instance_id()
	_tracked[id] = node


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

	return _build_target_data(container_node)


func _hud_allows_container(container_node: Node3D) -> bool:
	var hud := _resolve_hud()
	if hud == null:
		return true

	var target_name := TargetSupport.normalize_prompt_text(_debug_name(container_node))
	if target_name.is_empty():
		return true

	_ensure_hud_text_nodes(hud)
	return _hud_text_matches(target_name)


func _ensure_hud_text_nodes(hud: Node) -> void:
	if not _hud_text_nodes.is_empty():
		return
	TargetSupport.collect_hud_text_nodes(hud, _hud_text_nodes)


func _hud_text_matches(target_name: String) -> bool:
	for candidate_variant in _hud_text_nodes:
		if not (candidate_variant is Node):
			continue
		var candidate := candidate_variant as Node
		if not is_instance_valid(candidate):
			continue
		if candidate is CanvasItem and not (candidate as CanvasItem).is_visible_in_tree():
			continue
		var text_value: Variant = candidate.get("text")
		if text_value is String:
			var text := TargetSupport.normalize_prompt_text(text_value as String)
			if not text.is_empty() and text.contains(target_name):
				return true
	return false


func _build_target_data(node: Node3D) -> Dictionary:
	return {
		"id": node.get_instance_id(),
		"title": _debug_name(node),
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
		if current is Node3D and TargetSupport.looks_like_container(current):
			var container := current as Node3D
			_register_candidate(container)
			return container
		current = current.get_parent()
		depth += 1
	return null


func _render_item_rows(node: Node, summaries: Dictionary) -> void:
	if _items_box == null:
		return
	_rendered_item_rows.clear()
	_rendered_placeholder_row = null
	_placeholder_blocks.clear()
	_rendered_row_start = int(_item_list_model.get("window_start", 0))
	_rendered_row_end = int(_item_list_model.get("window_end", 0))
	_debug_last_top_spacer_height = 0.0
	_debug_last_bottom_spacer_height = 0.0
	_debug_last_visible_window_size = mini(_visible_item_names.size(), MAX_VISIBLE_ITEMS)
	_debug_last_render_window_size = maxi(0, _rendered_row_end - _rendered_row_start)
	_queue_clear_children(_items_box)
	_layout_dirty = true

	if bool(node.get("locked")):
		_items_box.add_child(
			PanelSupport.make_row(_ui_theme, _ui_tile, ITEM_ROW_HEIGHT, "LOCKED", false, true)
		)

	if summaries.is_empty():
		_set_item_column_width(ITEM_COL_MIN_WIDTH)
		_visible_item_names.clear()
		if _is_rummage_loading(node.get_instance_id()):
			_rendered_placeholder_row = PanelSupport.make_placeholder_row(
				_ui_theme,
				ITEM_ROW_HEIGHT,
				ROW_SIDE_PAD,
				_icon_col_width(),
				ROW_PREFIX_WIDTH,
				COL_SEPARATION,
				WEIGHT_COL_WIDTH,
				CONDITION_COL_WIDTH,
				VALUE_COL_WIDTH,
				0,
				ITEM_COL_MIN_WIDTH,
				_placeholder_blocks,
				_placeholder_tint()
			)
			_items_box.add_child(_rendered_placeholder_row)
			return
		_items_box.add_child(
			PanelSupport.make_row(_ui_theme, _ui_tile, ITEM_ROW_HEIGHT, "Empty", false, false)
		)
		return

	var item_col_width := _item_name_column_width(summaries)
	_set_item_column_width(item_col_width)
	var selected_index := int(_item_list_model.get("selected_index", -1))
	var rendered_names := _item_list_model.get("rendered_names", []) as Array
	var has_placeholder := _visible_item_names.size() < summaries.size()

	for item_name_variant in rendered_names:
		var item_name := str(item_name_variant)
		var i := _visible_item_names.find(item_name)
		if i < 0:
			continue
		var summary := summaries[item_name] as Dictionary
		var item_type := str(summary.get("type", "")).strip_edges()
		var row_icon := _row_icon_for_item_type(item_type)
		var show_row_icon := row_icon != null
		var amount := int(summary.get("amount", 1))
		var line_text := "%s x%d" % [item_name, amount] if amount > 1 else item_name
		var row := PanelSupport.make_item_row(
			_ui_theme,
			ITEM_ROW_HEIGHT,
			_icon_col_width(),
			ROW_PREFIX_WIDTH,
			COL_SEPARATION,
			WEIGHT_COL_WIDTH,
			CONDITION_COL_WIDTH,
			VALUE_COL_WIDTH,
			_row_style(true),
			_row_style(false),
			line_text,
			item_col_width,
			ItemSupport.format_weight(float(summary.get("weight", 0.0))),
			str(summary.get("condition", "--")),
			ItemSupport.format_value(int(summary.get("value", 0))),
			ItemSupport.rarity_color(
				str(summary.get("rarity", ItemSupport.RARITY_COMMON)),
				_rarity_colors_enabled(),
				_rarity_color_map()
			),
			i == selected_index,
			row_icon,
			show_row_icon,
			_numeric_column_font()
		)
		row.set_meta(&"peek_item_index", i)
		_rendered_item_rows.append(row)
		_items_box.add_child(row)

	if has_placeholder and bool(_item_list_model.get("render_placeholder", false)):
		_rendered_placeholder_row = PanelSupport.make_placeholder_row(
			_ui_theme,
			ITEM_ROW_HEIGHT,
			ROW_SIDE_PAD,
			_icon_col_width(),
			ROW_PREFIX_WIDTH,
			COL_SEPARATION,
			WEIGHT_COL_WIDTH,
			CONDITION_COL_WIDTH,
			VALUE_COL_WIDTH,
			_visible_item_names.size(),
			item_col_width,
			_placeholder_blocks,
			_placeholder_tint()
		)
		_items_box.add_child(_rendered_placeholder_row)

	var selected_row := _rendered_row_for_index(selected_index)
	if _scroll_to_top_on_render or bool(_item_list_model.get("snap_to_top", false)):
		_scroll_to_top_on_render = false
		_queue_scroll_top()
	elif selected_row != null:
		_queue_scroll_control_visible(selected_row)
	_debug_log_list_model("render-rows")
	_debug_queue_scroll_report("render-rows")


func _cycle_sort_mode() -> void:
	_sort_mode = posmod(_sort_mode + 1, SORT_MODE_VALUE + 1)
	_store_sort_mode()
	_refresh_hint_if_needed()
	_reset_view_for_sort_change()
	_last_render_target_id = -1


func _reset_view_for_target_change(target_id: int) -> void:
	_item_list.reset_target(target_id)
	_item_list_model.clear()
	_visible_item_names.clear()
	_rendered_row_start = -1
	_rendered_row_end = -1
	_scroll_to_top_on_render = true
	_debug_append_cursor_log("[ContainerPeek][Reset] target-change id=%d" % target_id)


func _reset_view_for_sort_change() -> void:
	if _current_target_id != -1:
		_item_list.reset_for_sort_change(_current_target_id)
	_item_list_model.clear()
	_visible_item_names.clear()
	_rendered_row_start = -1
	_rendered_row_end = -1
	_scroll_to_top_on_render = true
	_debug_append_cursor_log(
		"[ContainerPeek][Reset] sort-change id=%d mode=%d" % [_current_target_id, _sort_mode]
	)


func _store_sort_mode() -> void:
	var config_node := get_node_or_null("/root/ContainerPeekConfig")
	if config_node != null and config_node.has_method("set_int"):
		config_node.call("set_int", SORT_MODE_SECTION, SORT_MODE_KEY, _sort_mode)
		return
	var config := ConfigFile.new()
	if config.load(ConfigSupport.CONFIG_PATH) != OK:
		config = ConfigFile.new()
	config.set_value(SORT_MODE_SECTION, SORT_MODE_KEY, _sort_mode)
	config.save(ConfigSupport.CONFIG_PATH)


func _sort_mode_label() -> String:
	match _sort_mode:
		SORT_MODE_RARITY:
			return "Rarity"
		SORT_MODE_WEIGHT:
			return "Weight"
		SORT_MODE_VALUE:
			return "Value"
		_:
			return "Name"


func _item_name_column_width(summaries: Dictionary) -> float:
	if _cached_item_col_width > 0.0:
		return _cached_item_col_width

	var width := ITEM_COL_MIN_WIDTH
	for item_name in summaries.keys():
		var summary := summaries[item_name] as Dictionary
		var amount := int(summary.get("amount", 1))
		var line_text := "%s x%d" % [str(item_name), amount] if amount > 1 else str(item_name)
		width = maxf(width, _measure_item_text_width(line_text))
	_cached_item_col_width = width
	return _cached_item_col_width


func _measure_item_text_width(text: String) -> float:
	if _item_text_width_cache.has(text):
		return float(_item_text_width_cache[text])

	var font := _item_row_font()
	var font_size := _item_font_size
	var width := maxf(ITEM_COL_MIN_WIDTH, float(text.length() * 7))
	if font != null:
		width = ceil(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)

	_item_text_width_cache[text] = width
	return width


func _item_row_font() -> Font:
	if _item_font != null:
		return _item_font

	var probe := Label.new()
	probe.theme = _ui_theme
	probe.add_theme_font_size_override("font_size", _item_font_size)
	_item_font = probe.get_theme_font("font")
	_item_font_size = probe.get_theme_font_size("font_size")
	return _item_font


func _numeric_column_font() -> Font:
	if _numeric_font != null:
		return _numeric_font

	var base_font := _item_row_font()
	if base_font == null:
		return null

	var text_server := TextServerManager.get_primary_interface()
	if text_server == null:
		return base_font

	var numeric_font := FontVariation.new()
	numeric_font.base_font = base_font
	numeric_font.opentype_features = {text_server.name_to_tag("tnum"): 1}
	_numeric_font = numeric_font
	return _numeric_font


func _set_item_column_width(item_col_width: float) -> void:
	if _header_item_label == null:
		return
	_header_item_label.custom_minimum_size = Vector2(maxf(ITEM_COL_MIN_WIDTH, item_col_width), 0.0)


func _sync_header_alignment() -> void:
	if _header_margin == null or _item_scroll == null:
		return

	var gutter := 0
	var v_scroll := _item_scroll.get_v_scroll_bar()
	if v_scroll != null and v_scroll.visible:
		gutter = int(ceil(v_scroll.size.x))
	if gutter == _last_header_gutter:
		return

	_header_margin.add_theme_constant_override("margin_left", ROW_SIDE_PAD)
	_header_margin.add_theme_constant_override("margin_right", ROW_SIDE_PAD + gutter)
	_last_header_gutter = gutter


func _rendered_row_for_index(item_index: int) -> Control:
	if item_index < 0:
		return null
	for row_variant in _rendered_item_rows:
		if not (row_variant is Control):
			continue
		var row := row_variant as Control
		if int(row.get_meta(&"peek_item_index", -1)) == item_index:
			return row
	return null


func _row_style(selected: bool) -> StyleBox:
	if selected:
		if _selected_row_style != null:
			return _selected_row_style
		_selected_row_style = PanelSupport.make_row_style(_ui_tile, ROW_SIDE_PAD, true)
		return _selected_row_style

	if _plain_row_style == null:
		_plain_row_style = PanelSupport.make_row_style(_ui_tile, ROW_SIDE_PAD, false)
	return _plain_row_style


func _scroll_top_now() -> void:
	if _item_scroll == null:
		return
	_debug_last_target_scroll = 0
	_debug_last_scroll_control_name = "<top>"
	_debug_last_scroll_control_index = 0
	_debug_last_scroll_control_role = "top"
	_item_scroll.scroll_vertical = 0


func _queue_scroll_top() -> void:
	_scroll_request_id += 1
	call_deferred("_deferred_scroll_top", _scroll_request_id)


func _deferred_scroll_top(request_id: int) -> void:
	if request_id != _scroll_request_id:
		return
	_scroll_top_now()


func _queue_scroll_control_visible(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	_scroll_request_id += 1
	call_deferred("_deferred_scroll_control_visible", control, _scroll_request_id)


func _deferred_scroll_control_visible(control: Control, request_id: int) -> void:
	if request_id != _scroll_request_id:
		return
	if control == null or not is_instance_valid(control):
		return
	_scroll_control_visible(control)


func _scroll_control_visible(control: Control) -> void:
	if _item_scroll == null or control == null or not is_instance_valid(control):
		return
	var row_top := control.position.y
	var row_bottom := row_top + control.size.y
	var visible_top := float(_item_scroll.scroll_vertical)
	var viewport_height := _item_scroll.size.y
	if viewport_height <= 0.0:
		viewport_height = _item_scroll.custom_minimum_size.y
	var visible_bottom := visible_top + viewport_height
	var target_scroll := _item_scroll.scroll_vertical

	if row_top < visible_top:
		target_scroll = int(row_top)
	elif row_bottom > visible_bottom:
		target_scroll = int(row_bottom - viewport_height)

	_debug_last_target_scroll = maxi(0, target_scroll)
	_debug_capture_scroll_control(control)
	_item_scroll.scroll_vertical = maxi(0, target_scroll)


func _debug_queue_scroll_report(reason: String) -> void:
	if not DEBUG_CURSOR_LOG:
		return
	call_deferred("_debug_report_scroll_state", reason)


func _debug_report_scroll_state(reason: String) -> void:
	if not DEBUG_CURSOR_LOG:
		return
	if _item_scroll == null or _items_box == null:
		return
	if _current_target_id == -1:
		return

	var selected_index := -1
	if not _item_list_model.is_empty():
		selected_index = int(_item_list_model.get("selected_index", -1))
	var selected_row := _rendered_row_for_index(selected_index)
	var viewport_height := _item_scroll.size.y
	if viewport_height <= 0.0:
		viewport_height = _item_scroll.custom_minimum_size.y

	var selected_top := -1.0
	var selected_bottom := -1.0
	var selected_name := "<none>"
	if selected_index >= 0 and selected_index < _visible_item_names.size():
		selected_name = str(_visible_item_names[selected_index])
	if selected_row != null:
		selected_top = selected_row.position.y
		selected_bottom = selected_top + selected_row.size.y

	var child_count := _items_box.get_child_count()
	var first_child_name := "<none>"
	var last_child_name := "<none>"
	if child_count > 0:
		first_child_name = str(_items_box.get_child(0).name)
		last_child_name = str(_items_box.get_child(child_count - 1).name)

	var first_rendered_index := -1
	var last_rendered_index := -1
	if _rendered_item_rows.size() > 0:
		var first_row := _rendered_item_rows[0] as Control
		var last_row := _rendered_item_rows[_rendered_item_rows.size() - 1] as Control
		if first_row != null and first_row.has_meta(&"peek_item_index"):
			first_rendered_index = int(first_row.get_meta(&"peek_item_index"))
		if last_row != null and last_row.has_meta(&"peek_item_index"):
			last_rendered_index = int(last_row.get_meta(&"peek_item_index"))

	var v_scroll := _item_scroll.get_v_scroll_bar()
	var scroll_max := -1.0
	var scroll_page := -1.0
	if v_scroll != null:
		scroll_max = float(v_scroll.max_value)
		scroll_page = float(v_scroll.page)

		var line := (
			(
				"[ContainerPeek][Scroll] %s id=%s sel=%d name='%s' visible=%d scroll=%d "
				+ "target_scroll=%d viewport=%.1f selected_top=%.1f selected_bottom=%.1f "
				+ "items_box_y=%.1f items_box_h=%.1f layout_dirty=%s last_render_sel=%d "
				+ "children=%d first='%s' last='%s' "
				+ "rendered_first=%d rendered_last=%d control='%s' control_index=%d "
				+ "control_role='%s' scroll_max=%.1f scroll_page=%.1f"
			)
			% [
				reason,
				_current_target_id,
				selected_index,
				selected_name,
				_visible_item_names.size(),
				_item_scroll.scroll_vertical,
				_debug_last_target_scroll,
				viewport_height,
				selected_top,
				selected_bottom,
				_items_box.position.y,
				_items_box.size.y,
				str(_layout_dirty),
				_last_render_selection,
				child_count,
				first_child_name,
				last_child_name,
				first_rendered_index,
				last_rendered_index,
				_debug_last_scroll_control_name,
				_debug_last_scroll_control_index,
				_debug_last_scroll_control_role,
				scroll_max,
				scroll_page,
			]
		)
		_debug_append_cursor_log(line)

	if selected_row == null:
		_debug_append_cursor_log(
			"[ContainerPeek][Scroll] selected row missing from rendered window"
		)
		return

	var visible_top := float(_item_scroll.scroll_vertical)
	var visible_bottom := visible_top + viewport_height
	if selected_top < visible_top or selected_bottom > visible_bottom:
		_debug_append_cursor_log(
			(
				"[ContainerPeek][Scroll] selected row not visible after scroll "
				+ "visible_top=%.1f visible_bottom=%.1f" % [visible_top, visible_bottom]
			)
		)


func _debug_append_cursor_log(line: String) -> void:
	if not DEBUG_CURSOR_LOG:
		return

	var file := FileAccess.open(DEBUG_CURSOR_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(DEBUG_CURSOR_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(line)


func _debug_log_list_model(reason: String) -> void:
	if not DEBUG_CURSOR_LOG or _item_list_model.is_empty():
		return

	_debug_append_cursor_log(
		(
			(
				"[ContainerPeek][Model] %s id=%d selected='%s' index=%d viewport_row=%d "
				+ "window=%d..%d visible=%d rendered=%d anchored=%s full=%s placeholder=%s"
			)
			% [
				reason,
				_current_target_id,
				str(_item_list_model.get("selected_name", "")),
				int(_item_list_model.get("selected_index", -1)),
				int(_item_list_model.get("selected_viewport_row", -1)),
				int(_item_list_model.get("window_start", 0)),
				int(_item_list_model.get("window_end", 0)),
				_visible_item_names.size(),
				(_item_list_model.get("rendered_names", []) as Array).size(),
				str(_item_list_model.get("anchored", false)),
				str(_item_list_model.get("viewport_full", false)),
				str(_item_list_model.get("render_placeholder", false)),
			]
		)
	)


func _debug_capture_scroll_control(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		_debug_last_scroll_control_name = "<none>"
		_debug_last_scroll_control_index = -1
		_debug_last_scroll_control_role = ""
		return

	_debug_last_scroll_control_name = str(control.name)
	_debug_last_scroll_control_index = -1
	if control.has_meta(&"peek_item_index"):
		_debug_last_scroll_control_index = int(control.get_meta(&"peek_item_index"))

	if control == _rendered_placeholder_row:
		_debug_last_scroll_control_role = "placeholder"
	elif control in _rendered_item_rows:
		_debug_last_scroll_control_role = "row"
	else:
		_debug_last_scroll_control_role = "control"


func _rarity_colors_enabled() -> bool:
	return ConfigSupport.bool_setting(self, "rarity_colors", true)


func _show_category_icons() -> bool:
	return ConfigSupport.bool_setting(self, SHOW_CATEGORY_ICONS_KEY, true)


func _rarity_color_map() -> Dictionary:
	return {
		"common":
		ConfigSupport.color_setting(self, RARITY_COMMON_COLOR_KEY, Color(1.0, 1.0, 1.0, 0.78)),
		"rare": ConfigSupport.color_setting(self, RARITY_RARE_COLOR_KEY, Color.RED),
		"legendary":
		ConfigSupport.color_setting(self, RARITY_LEGENDARY_COLOR_KEY, Color.DARK_VIOLET),
	}


func _rarity_color_signature() -> String:
	var colors := _rarity_color_map()
	var parts := PackedStringArray()
	for rarity in ["common", "rare", "legendary"]:
		var color := colors.get(rarity, Color.WHITE)
		if color is Color:
			var rarity_color := color as Color
			parts.append(
				(
					"%s=%.3f,%.3f,%.3f,%.3f"
					% [rarity, rarity_color.r, rarity_color.g, rarity_color.b, rarity_color.a]
				)
			)
	return "|".join(parts)


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
	return str(_item_list_model.get("selected_name", ""))


func _current_target_is_loading() -> bool:
	if (
		_last_focus_node == null
		or not is_instance_valid(_last_focus_node)
		or _current_target_id == -1
	):
		return false
	return _is_rummage_loading(_current_target_id)


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
		_item_list.reset_target(_current_target_id)
		_item_list_model.clear()
		_invalidate_summary_cache()
		_last_render_target_id = -1
	return moved_any


func _try_direct_selected_transfer(container_node: Node) -> bool:
	var item_name := _current_selected_item_name()
	var slot := ItemSupport.slot_for_item_name(container_node, item_name)
	if slot == null:
		return false
	return _try_direct_slot_transfer(container_node, slot)


# Mirrors res://Scripts/Interface.gd FastTransfer()/ContextTransfer(): try AutoStack()
# into inventory first, then Create()/AutoPlace(), while preserving click/error feedback.
func _try_direct_slot_transfer(container_node: Node, slot: Variant) -> bool:
	var interface_node := _resolve_interface_node()
	if interface_node == null or slot == null:
		return false
	if not interface_node.has_method("Create"):
		return false

	var inventory_grid := _resolve_inventory_grid(interface_node)
	if inventory_grid == null:
		return false

	var moved := false
	if interface_node.has_method("AutoStack"):
		moved = bool(interface_node.call("AutoStack", slot, inventory_grid))

	if not moved:
		moved = bool(interface_node.call("Create", slot, inventory_grid, false))

	if not moved:
		_play_error_beep(interface_node)
		return false

	ItemSupport.remove_slot_from_container(container_node, slot)
	_invalidate_summary_cache()
	_refresh_interface_state(interface_node)
	_last_render_target_id = -1
	if interface_node.has_method("Reset"):
		interface_node.call("Reset")
	if interface_node.has_method("PlayClick"):
		interface_node.call("PlayClick")
	return true


func _play_error_beep(interface_node: Node) -> void:
	if interface_node.has_method("PlayError"):
		interface_node.call("PlayError")


func _refresh_interface_state(interface_node: Node) -> void:
	# Popup transfers bypass the native inventory loop, so force the same weight/overweight refresh.
	if interface_node.has_method("UpdateStats"):
		interface_node.call("UpdateStats", bool(interface_node.visible))


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


func _resolve_ui_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null

	var scene := tree.current_scene
	if scene != null:
		var by_abs := scene.get_node_or_null("/root/Map/Core/UI")
		if by_abs != null:
			return by_abs
		var by_rel := scene.get_node_or_null("Core/UI")
		if by_rel != null:
			return by_rel

	var root := tree.root
	if root != null:
		return root.get_node_or_null("Map/Core/UI")
	return null


func _xp_skills_compat_enabled() -> bool:
	return ConfigSupport.bool_setting(self, XP_SKILLS_COMPAT_KEY, true)


func _resolve_inventory_grid(interface_node: Node) -> Node:
	var by_prop: Variant = interface_node.get("inventoryGrid")
	if by_prop is Node:
		return by_prop as Node

	var inventory := interface_node.get_node_or_null("Inventory")
	if inventory != null:
		return inventory.get_node_or_null("Grid")
	return null
