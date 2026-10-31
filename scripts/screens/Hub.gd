extends Screen
## The corridor outside Room B: the six suspects, the candle, and the night's choices.


func setup(_args: Dictionary) -> void:
	Audio.play("main_theme")
	add_background("hub", 0.55)
	if Game.candles <= 0 and not Game.ended:
		m().toast(Story.ui("no_candles"), UI.PRESS, 5.0)

	var root := UI.vbox(18)
	UI.full_rect(root)
	add_child(UI.full_rect(UI.margin(root, 60, 34, 60, 30)))

	# Header: night, candle, case title.
	var head := UI.hbox(24)
	var night_box := UI.vbox(0)
	night_box.add_child(UI.label(Story.ui("night") + " " + Story.num(Game.night) + " " + Story.ui("of") + " " + Story.num(Game.nights_total()), 40, UI.PAPER, "title"))
	var tagline := Story.t(Story.data.nights[mini(Game.night, Story.data.nights.size()) - 1]).split("\n")
	night_box.add_child(UI.label(tagline[tagline.size() - 1], 18, UI.DIM, "serif_italic", true))
	night_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(night_box)
	head.add_child(_candle())
	root.add_child(head)

	# Suspect cards, 3 x 2.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for s in Story.suspects:
		grid.add_child(_card(s))
	root.add_child(grid)

	# Footer actions.
	var foot := UI.hbox(14)
	foot.add_child(UI.button("☰  " + Story.ui("menu"), func(): m().goto("menu"), 18))
	var badge := UI.button(Story.ui("mode_badge_ai") % Settings.ai_model if Settings.mode == "ai" else Story.ui("mode_badge_classic"), func(): m().goto("settings"), 15)
	badge.add_theme_color_override("font_color", UI.DIM)
	badge.flat = true
	badge.tooltip_text = Story.ui("settings")
	foot.add_child(badge)
	foot.add_child(UI.spacer(false))
	foot.add_child(UI.button("📁  " + Story.ui("case_file"), func(): m().open_case_file(1), 20))
	foot.add_child(UI.button("✦  " + Story.ui("instinct"), _instinct, 20))
	foot.add_child(UI.button("☾  " + Story.ui("end_night"), func(): m().goto("night_end"), 20))
	var acc := UI.button("⚖  " + Story.ui("accuse"), func(): m().goto("accuse"), 22)
	acc.disabled = not Game.can_accuse()
	acc.tooltip_text = "" if Game.can_accuse() else Story.ui("accuse_locked")
	if Game.can_accuse():
		acc.add_theme_stylebox_override("normal", UI.flat(Color(UI.RED_DIM, 0.95), 4, UI.RED, 1, 16))
	foot.add_child(acc)
	root.add_child(foot)


func _candle() -> Control:
	var box := UI.vbox(4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var row := UI.hbox(5)
	row.alignment = BoxContainer.ALIGNMENT_END
	var total := int(Story.data.get("candles_per_night", 14))
	for i in total:
		var c := ColorRect.new()
		c.custom_minimum_size = Vector2(9, 30)
		c.color = UI.GOLD if i < Game.candles else Color(1, 1, 1, 0.08)
		row.add_child(c)
	box.add_child(row)
	var l := UI.label(Story.num(Game.candles) + " " + Story.ui("questions_left"), 16, UI.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(l)
	return box


func _card(s: Dictionary) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(480, 300)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.clip_contents = true
	btn.add_theme_stylebox_override("normal", UI.flat(Color(0.06, 0.06, 0.07, 0.88), 6, Color(1, 1, 1, 0.08), 1, 0))
	# Hover keeps the card's own colour (a tinted fill only showed beside the portrait) and lights the border.
	btn.add_theme_stylebox_override("hover", UI.flat(Color(0.06, 0.06, 0.07, 0.88), 6, Color(s.color), 2, 0))
	btn.add_theme_stylebox_override("pressed", UI.flat(Color(0.06, 0.06, 0.07, 0.88), 6, UI.RED, 2, 0))
	btn.add_theme_stylebox_override("focus", UI.flat(Color.TRANSPARENT, 6, Color(s.color, 0.5), 1, 0))
	btn.disabled = Game.candles <= 0
	btn.pressed.connect(func(): m().goto("room", {"suspect": s.id}))

	var row := UI.hbox(0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(row)
	btn.add_child(row)

	var pic_holder := Control.new()
	pic_holder.custom_minimum_size = Vector2(190, 0)
	pic_holder.clip_contents = true
	pic_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := UI.full_rect(UI.cover(UI.portrait(s.id), 0.1))
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if pic is TextureRect:
		(pic as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic_holder.add_child(pic)
	row.add_child(pic_holder)
	var dim := pic.modulate
	btn.mouse_entered.connect(func():
		if btn.disabled:
			return
		pic.pivot_offset = pic.size / 2.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(pic, "modulate", Color(1.12, 1.12, 1.12), 0.18)
		tw.tween_property(pic, "scale", Vector2.ONE * 1.04, 0.25).set_trans(Tween.TRANS_SINE))
	btn.mouse_exited.connect(func():
		var tw := create_tween().set_parallel(true)
		tw.tween_property(pic, "modulate", dim, 0.25)
		tw.tween_property(pic, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE))

	var info := UI.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_l := UI.label(Story.t(s.name), 28, UI.PAPER, "title")
	info.add_child(name_l)
	info.add_child(UI.label(Story.t(s.role) + "  ·  " + Story.num(int(s.age)), 17, Color(s.color)))
	var summ := UI.label(Story.t(s.summary), 16, UI.DIM, "body", true)
	summ.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(summ)
	var meters := UI.hbox(14)
	meters.add_child(UI.meter(Story.ui("composure"), Game.composure(s.id), UI.COLD, 120))
	meters.add_child(UI.meter(Story.ui("trust"), Game.trust(s.id), UI.GENTLE, 120))
	info.add_child(meters)
	var found := 0
	for e in Game.testimonies:
		if e.suspect == s.id:
			found += 1
	var stat := UI.label("✎ " + Story.num(found) + " / " + Story.num(s.secrets.size()) + "   " + Story.ui("testimony"), 15, UI.GOLD if found > 0 else UI.FAINT)
	info.add_child(stat)
	for c in info.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		for cc in c.get_children():
			if cc is Control:
				(cc as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UI.margin(info, 18, 14, 18, 14))
	row.get_child(1).mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn


func _instinct() -> void:
	var h := Game.hint()
	var box := UI.vbox(18)
	box.add_child(UI.label("✦  " + Story.ui("instinct"), 28, UI.GOLD, "title"))
	var r := UI.rich("[i]" + h + "[/i]", 22)
	r.custom_minimum_size.x = 640
	box.add_child(r)
	var close := UI.button(Story.ui("close"), func(): m().close_top_overlay(), 18)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(close)
	var p := UI.panel(UI.margin(box, 36, 28, 36, 28), UI.flat(UI.PANEL, 8, Color(UI.GOLD, 0.5), 1, 0))
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	m().overlay(p)
