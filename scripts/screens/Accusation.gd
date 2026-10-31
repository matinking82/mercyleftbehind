extends Screen
## The final accusation: who, how, why.

var killer := ""
var means := ""
var motive := ""
var confirm_btn: Button
var killer_btns := {}
var forced := false


func setup(args: Dictionary) -> void:
	forced = args.get("forced", false)
	Audio.play("main_theme")
	add_background("accuse", 0.55)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(UI.full_rect(sc))
	var col := UI.vbox(18)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(UI.margin(col, 120, 36, 120, 36))
	(sc.get_child(0) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var t := UI.label(Story.ui("accusation"), 46, UI.PAPER, "title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)

	col.add_child(_heading("I.  " + Story.ui("acc_who")))
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for s in Story.suspects:
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(170, 240)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("pressed", UI.flat(Color(UI.RED_DIM, 0.9), 4, UI.RED, 3, 0))
		b.add_theme_stylebox_override("normal", UI.flat(Color(0.07, 0.07, 0.08, 0.9), 4, Color(1, 1, 1, 0.1), 1, 0))
		var v := UI.vbox(4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full_rect(v)
		var img := UI.cover(UI.portrait(s.id), 0.0)
		img.custom_minimum_size = Vector2(170, 196)
		img.clip_contents = true
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(img)
		var l := UI.label(Story.t(s.name), 18, UI.INK)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		b.add_child(v)
		b.pressed.connect(func():
			killer = s.id if b.button_pressed else ""
			for k in killer_btns:
				if k != s.id:
					killer_btns[k].button_pressed = false
			_update())
		killer_btns[s.id] = b
		row.add_child(b)
	col.add_child(row)

	col.add_child(_heading("II.  " + Story.ui("acc_how")))
	col.add_child(_options(Story.data.means, func(id): means = id; _update()))
	col.add_child(_heading("III.  " + Story.ui("acc_why")))
	col.add_child(_options(Story.data.motives, func(id): motive = id; _update()))

	var foot := UI.hbox(16)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	if not forced:
		foot.add_child(UI.button(Story.ui("not_yet"), func(): m().goto("hub"), 20, 180))
	foot.add_child(UI.button("📁  " + Story.ui("case_file"), func(): m().open_case_file(2), 20))
	confirm_btn = UI.button("⚖  " + Story.ui("acc_confirm"), _confirm, 24, 280)
	confirm_btn.add_theme_stylebox_override("normal", UI.flat(Color(UI.RED_DIM, 0.95), 4, UI.RED, 1, 16))
	foot.add_child(confirm_btn)
	col.add_child(UI.margin(foot, 0, 14, 0, 0))
	_update()


func _heading(text: String) -> Label:
	var l := UI.label(text, 26, UI.GOLD, "title")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _options(items: Array, on_pick: Callable) -> Control:
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	var group := ButtonGroup.new()
	for it in items:
		var b := UI.button(Story.t(it), on_pick.bind(it.id), 19)
		b.toggle_mode = true
		b.button_group = group
		b.add_theme_stylebox_override("pressed", UI.flat(Color(UI.RED_DIM, 0.9), 4, UI.RED, 2, 16))
		flow.add_child(b)
	return flow


func _update() -> void:
	confirm_btn.disabled = killer == "" or means == "" or motive == ""


func _confirm() -> void:
	m().confirm(Story.ui("acc_sure"), func():
		var ending := Game.accuse(killer, means, motive)
		m().goto("ending", {"ending": ending}, 1.2))
