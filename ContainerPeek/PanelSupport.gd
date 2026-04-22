extends RefCounted


static func make_divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0.0, 1.0)
	return divider


static func make_panel_style(ui_tile: Texture2D, panel_opacity: float) -> StyleBox:
	if ui_tile != null:
		var style := StyleBoxTexture.new()
		style.texture = ui_tile
		style.texture_margin_left = 1.0
		style.texture_margin_top = 1.0
		style.texture_margin_right = 1.0
		style.texture_margin_bottom = 1.0
		style.modulate_color = Color(1.0, 1.0, 1.0, 0.86 * panel_opacity)
		return style

	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.06, 0.06, 0.06, 0.92 * panel_opacity)
	fallback.border_color = Color(1.0, 1.0, 1.0, 0.18 * panel_opacity)
	fallback.border_width_left = 1
	fallback.border_width_top = 1
	fallback.border_width_right = 1
	fallback.border_width_bottom = 1
	return fallback


static func make_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(0.0, maxf(0.0, height))
	return spacer


static func _fixed_spacer(width: float) -> Control:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(width, 0.0)
	return spacer


static func _row_box(col_separation: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", col_separation)
	return box


static func _label(
	ui_theme: Theme,
	text: String,
	font_size: int,
	font_color: Color,
	width: float = 0.0,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	expand: bool = false
) -> Label:
	var label := Label.new()
	label.theme = ui_theme
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	if width > 0.0:
		label.custom_minimum_size = Vector2(width, 0.0)
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


static func _set_row_padding(style: StyleBox, row_side_pad: int) -> void:
	style.content_margin_left = row_side_pad
	style.content_margin_top = 0.0
	style.content_margin_right = row_side_pad
	style.content_margin_bottom = 0.0


static func make_header_row(
	ui_theme: Theme,
	icon_col_width: float,
	row_prefix_width: float,
	item_col_min_width: float,
	col_separation: int,
	weight_col_width: float,
	condition_col_width: float
) -> Dictionary:
	var row := _row_box(col_separation)
	var dim := Color(1.0, 1.0, 1.0, 0.5)

	row.add_child(_fixed_spacer(icon_col_width))
	row.add_child(_fixed_spacer(row_prefix_width))

	var item_label := _label(
		ui_theme, "Item", 11, dim, item_col_min_width, HORIZONTAL_ALIGNMENT_LEFT, true
	)
	row.add_child(item_label)
	row.add_child(_label(ui_theme, "Weight", 11, dim, weight_col_width, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_label(ui_theme, "Cond.", 11, dim, condition_col_width, HORIZONTAL_ALIGNMENT_RIGHT))

	return {"row": row, "item_label": item_label}


static func make_row(
	ui_theme: Theme,
	ui_tile: Texture2D,
	item_row_height: int,
	text: String,
	selected: bool,
	status: bool
) -> Control:
	var row := PanelContainer.new()
	row.theme = ui_theme
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0.0, float(item_row_height))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", make_row_style(ui_tile, 2, selected))

	var color := Color(1.0, 0.87, 0.55, 1.0) if status else (
		Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.78)
	)
	row.add_child(
		_label(
			ui_theme,
			("> " if selected else "  ") + text,
			13,
			color,
			0.0,
			HORIZONTAL_ALIGNMENT_LEFT,
			true
		)
	)
	return row


static func make_row_style(ui_tile: Texture2D, row_side_pad: int, selected: bool) -> StyleBox:
	if not selected:
		var empty_style := StyleBoxEmpty.new()
		_set_row_padding(empty_style, row_side_pad)
		return empty_style

	if ui_tile != null:
		var textured := StyleBoxTexture.new()
		textured.texture = ui_tile
		textured.texture_margin_left = 1.0
		textured.texture_margin_top = 1.0
		textured.texture_margin_right = 1.0
		textured.texture_margin_bottom = 1.0
		textured.modulate_color = Color(1.0, 1.0, 1.0, 0.32)
		_set_row_padding(textured, row_side_pad)
		return textured

	var selected_fallback := StyleBoxFlat.new()
	selected_fallback.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	_set_row_padding(selected_fallback, row_side_pad)
	return selected_fallback


static func make_placeholder_row(
	ui_theme: Theme,
	item_row_height: int,
	row_side_pad: int,
	icon_col_width: float,
	row_prefix_width: float,
	col_separation: int,
	weight_col_width: float,
	condition_col_width: float,
	index: int,
	item_col_width: float,
	placeholder_blocks: Array,
	tint: Color
) -> Control:
	var row := PanelContainer.new()
	row.theme = ui_theme
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0.0, float(item_row_height))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxEmpty.new()
	_set_row_padding(style, row_side_pad)
	row.add_theme_stylebox_override("panel", style)

	var margins := MarginContainer.new()
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.add_theme_constant_override("margin_top", 5)
	margins.add_theme_constant_override("margin_bottom", 5)
	row.add_child(margins)

	var box := _row_box(col_separation)
	margins.add_child(box)

	box.add_child(_fixed_spacer(icon_col_width))
	box.add_child(_fixed_spacer(row_prefix_width))

	var item_widths := [0.92, 0.76, 1.0, 0.84]
	box.add_child(
		make_placeholder_bar(
			item_col_width * float(item_widths[index % item_widths.size()]),
			placeholder_blocks,
			tint
		)
	)

	var item_filler := Control.new()
	item_filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(item_filler)

	box.add_child(make_placeholder_bar(weight_col_width - 12.0, placeholder_blocks, tint))
	box.add_child(make_placeholder_bar(condition_col_width - 14.0, placeholder_blocks, tint))

	return row


static func make_placeholder_bar(width: float, placeholder_blocks: Array, tint: Color) -> ColorRect:
	var bar := ColorRect.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.color = tint
	bar.custom_minimum_size = Vector2(maxf(12.0, width), 8.0)
	placeholder_blocks.append(bar)
	return bar


static func make_item_row(
	ui_theme: Theme,
	item_row_height: int,
	icon_col_width: float,
	row_prefix_width: float,
	col_separation: int,
	weight_col_width: float,
	condition_col_width: float,
	selected_style: StyleBox,
	plain_style: StyleBox,
	text: String,
	item_col_width: float,
	weight_text: String,
	condition_text: String,
	rarity_color: Color,
	selected: bool,
	left_icon: Texture2D,
	show_left_icon: bool
) -> Control:
	var row := PanelContainer.new()
	row.theme = ui_theme
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0.0, float(item_row_height))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", selected_style if selected else plain_style)

	var box := _row_box(col_separation)
	row.add_child(box)

	var icon_slot := CenterContainer.new()
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.custom_minimum_size = Vector2(icon_col_width, float(item_row_height))
	box.add_child(icon_slot)

	if left_icon != null and show_left_icon:
		var icon_margin := MarginContainer.new()
		icon_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_margin.add_theme_constant_override("margin_left", 1)
		icon_margin.add_theme_constant_override("margin_top", 1)
		icon_margin.add_theme_constant_override("margin_right", 1)
		icon_margin.add_theme_constant_override("margin_bottom", 1)
		icon_slot.add_child(icon_margin)

		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = left_icon
		icon.modulate = rarity_color
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.custom_minimum_size = Vector2(icon_col_width - 2.0, item_row_height - 2.0)
		icon_margin.add_child(icon)

	var prefix_label := _label(
		ui_theme,
		">" if selected else "",
		13,
		Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.0),
		row_prefix_width,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	box.add_child(prefix_label)

	var name_label := _label(
		ui_theme, text, 13, rarity_color, item_col_width, HORIZONTAL_ALIGNMENT_LEFT, true
	)
	box.add_child(name_label)

	var dim := Color(1.0, 1.0, 1.0, 0.66)
	var bright := Color(1.0, 1.0, 1.0, 1.0)
	var weight_label := _label(
		ui_theme,
		weight_text,
		12,
		bright if selected else dim,
		weight_col_width,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	box.add_child(weight_label)

	var condition_label := _label(
		ui_theme,
		condition_text,
		12,
		bright if selected else dim,
		condition_col_width,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	box.add_child(condition_label)

	row.set_meta(&"peek_prefix_label", prefix_label)
	row.set_meta(&"peek_name_label", name_label)
	row.set_meta(&"peek_weight_label", weight_label)
	row.set_meta(&"peek_condition_label", condition_label)
	row.set_meta(&"peek_rarity_color", rarity_color)

	return row


static func apply_item_row_selection(
	row: Control, selected: bool, selected_style: StyleBox, plain_style: StyleBox
) -> void:
	if row == null or not is_instance_valid(row):
		return
	if not (row is PanelContainer):
		return

	var panel_row := row as PanelContainer
	panel_row.add_theme_stylebox_override("panel", selected_style if selected else plain_style)

	var prefix_label := row.get_meta(&"peek_prefix_label", null)
	if prefix_label is Label:
		(prefix_label as Label).text = ">" if selected else ""
		(prefix_label as Label).add_theme_color_override(
			"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.0)
		)

	var rarity_color := row.get_meta(&"peek_rarity_color", Color(1.0, 1.0, 1.0, 0.78))
	var name_label := row.get_meta(&"peek_name_label", null)
	if name_label is Label:
		(name_label as Label).add_theme_color_override("font_color", rarity_color)

	var weight_label := row.get_meta(&"peek_weight_label", null)
	if weight_label is Label:
		(weight_label as Label).add_theme_color_override(
			"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.66)
		)

	var condition_label := row.get_meta(&"peek_condition_label", null)
	if condition_label is Label:
		(condition_label as Label).add_theme_color_override(
			"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.66)
		)
