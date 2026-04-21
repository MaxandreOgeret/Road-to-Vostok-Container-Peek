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


static func make_header_row(
	ui_theme: Theme,
	row_prefix_width: float,
	item_col_min_width: float,
	col_separation: int,
	weight_col_width: float,
	condition_col_width: float
) -> Dictionary:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", col_separation)

	var prefix_spacer := Control.new()
	prefix_spacer.custom_minimum_size = Vector2(row_prefix_width, 0.0)
	row.add_child(prefix_spacer)

	var item_label := Label.new()
	item_label.theme = ui_theme
	item_label.text = "Item"
	item_label.custom_minimum_size = Vector2(item_col_min_width, 0.0)
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_label.add_theme_font_size_override("font_size", 11)
	item_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	row.add_child(item_label)

	var weight_label := Label.new()
	weight_label.theme = ui_theme
	weight_label.text = "Weight"
	weight_label.custom_minimum_size = Vector2(weight_col_width, 0.0)
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weight_label.add_theme_font_size_override("font_size", 11)
	weight_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	row.add_child(weight_label)

	var condition_label := Label.new()
	condition_label.theme = ui_theme
	condition_label.text = "Cond."
	condition_label.custom_minimum_size = Vector2(condition_col_width, 0.0)
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	condition_label.add_theme_font_size_override("font_size", 11)
	condition_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	row.add_child(condition_label)

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

	var style: StyleBox
	if selected:
		if ui_tile != null:
			var textured := StyleBoxTexture.new()
			textured.texture = ui_tile
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
	label.theme = ui_theme
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


static func make_selected_row_style(ui_tile: Texture2D, row_side_pad: int) -> StyleBox:
	if ui_tile != null:
		var textured := StyleBoxTexture.new()
		textured.texture = ui_tile
		textured.texture_margin_left = 1.0
		textured.texture_margin_top = 1.0
		textured.texture_margin_right = 1.0
		textured.texture_margin_bottom = 1.0
		textured.content_margin_left = row_side_pad
		textured.content_margin_right = row_side_pad
		textured.modulate_color = Color(1.0, 1.0, 1.0, 0.32)
		return textured

	var selected_fallback := StyleBoxFlat.new()
	selected_fallback.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	selected_fallback.content_margin_left = row_side_pad
	selected_fallback.content_margin_right = row_side_pad
	return selected_fallback


static func make_plain_row_style(row_side_pad: int) -> StyleBox:
	var empty_style := StyleBoxEmpty.new()
	empty_style.content_margin_left = row_side_pad
	empty_style.content_margin_right = row_side_pad
	return empty_style


static func make_placeholder_row(
	ui_theme: Theme,
	item_row_height: int,
	row_side_pad: int,
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
	style.content_margin_left = row_side_pad
	style.content_margin_right = row_side_pad
	row.add_theme_stylebox_override("panel", style)

	var margins := MarginContainer.new()
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.add_theme_constant_override("margin_top", 5)
	margins.add_theme_constant_override("margin_bottom", 5)
	row.add_child(margins)

	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", col_separation)
	margins.add_child(box)

	var prefix_spacer := Control.new()
	prefix_spacer.custom_minimum_size = Vector2(row_prefix_width, 0.0)
	box.add_child(prefix_spacer)

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
	selected: bool
) -> Control:
	var row := PanelContainer.new()
	row.theme = ui_theme
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0.0, float(item_row_height))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", selected_style if selected else plain_style)

	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", col_separation)
	row.add_child(box)

	var prefix_label := Label.new()
	prefix_label.theme = ui_theme
	prefix_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prefix_label.text = ">" if selected else ""
	prefix_label.custom_minimum_size = Vector2(row_prefix_width, 0.0)
	prefix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prefix_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prefix_label.add_theme_font_size_override("font_size", 13)
	prefix_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.0)
	)
	box.add_child(prefix_label)

	var name_label := Label.new()
	name_label.theme = ui_theme
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = text
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(item_col_width, 0.0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", rarity_color)
	box.add_child(name_label)

	var weight_label := Label.new()
	weight_label.theme = ui_theme
	weight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weight_label.text = weight_text
	weight_label.custom_minimum_size = Vector2(weight_col_width, 0.0)
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 12)
	weight_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.66)
	)
	box.add_child(weight_label)

	var condition_label := Label.new()
	condition_label.theme = ui_theme
	condition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	condition_label.text = condition_text
	condition_label.custom_minimum_size = Vector2(condition_col_width, 0.0)
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	condition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	condition_label.add_theme_font_size_override("font_size", 12)
	condition_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 1.0) if selected else Color(1.0, 1.0, 1.0, 0.66)
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
