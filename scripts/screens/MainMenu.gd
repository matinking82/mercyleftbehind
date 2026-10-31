extends Screen


func setup(_args: Dictionary) -> void:
	Audio.play("main_theme")
	var bg := add_background("menu", 0.25)
	if bg is TextureRect and Settings.is_rtl():
		(bg as TextureRect).flip_h = true  # keep the figures on the side away from the menu
	add_slow_zoom(bg)

	# Darken the side the menu sits on so the text stays readable over any art.
	var side := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(0, 0, 0, 0.85))
	grad.gradient.set_color(1, Color(0, 0, 0, 0))
	grad.fill_from = Vector2(1, 0) if Settings.is_rtl() else Vector2(0, 0)
	grad.fill_to = Vector2(0.45, 0) if Settings.is_rtl() else Vector2(0.55, 0)
	side.texture = grad
	side.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(UI.full_rect(side))

	var row := UI.hbox(0)
	add_child(UI.full_rect(UI.margin(row, 110, 0, 110, 60)))
	var col := UI.vbox(14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size = Vector2(620, 0)
	row.add_child(col)
	row.add_child(UI.spacer(false))

	var title := UI.label(Story.t(Story.data.title), 64 if Settings.lang == "en" else 72, UI.PAPER, "title")
	col.add_child(title)
	var sub := UI.label(Story.t(Story.data.subtitle), 24, UI.RED, "serif_italic")
	col.add_child(sub)
	col.add_child(UI.margin(null, 0, 26, 0, 0))

	if Game.active:
		var cont := Story.ui("continue") + "  ·  " + Story.ui("night") + " " + Story.num(Game.night)
		col.add_child(_menu_button(cont, func(): m().goto("hub")))
	col.add_child(_menu_button(Story.ui("new_case"), _new_case))
	col.add_child(_menu_button(Story.ui("how_to"), func(): m().goto("howto")))
	col.add_child(_menu_button(Story.ui("settings"), func(): m().goto("settings")))
	col.add_child(_menu_button(Story.ui("quit"), func(): get_tree().quit()))

	var credit := UI.label(Story.ui("credits"), 14, UI.FAINT)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	credit.offset_top = -40
	credit.offset_bottom = -14
	add_child(credit)


func _menu_button(text: String, cb: Callable) -> Button:
	var b := UI.button(text, cb, 24)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT if not Settings.is_rtl() else HORIZONTAL_ALIGNMENT_RIGHT
	b.custom_minimum_size = Vector2(380, 54)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return b


func _new_case() -> void:
	if Game.active:
		m().confirm(Story.ui("overwrite"), _start)
	else:
		_start()


func _start() -> void:
	Game.new_game()
	m().goto("intro")
