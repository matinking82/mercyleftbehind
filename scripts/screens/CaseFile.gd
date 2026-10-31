extends Control
## The case file overlay: victim, evidence, testimony (auto-recorded), suspect dossiers, and your notebook.

var back: Control
var body: Control
var tabs_row: HBoxContainer
var current_tab := 0
var notes_edit: TextEdit

const TABS := ["victim", "evidence", "testimony", "suspects", "notebook"]


func m() -> Node:
	return get_meta("main")


func setup(args: Dictionary) -> void:
	back = args.back
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.flat(Color(0.06, 0.055, 0.05, 0.98), 8, Color(UI.GOLD, 0.35), 1, 0))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 80
	p.offset_right = -80
	p.offset_top = 50
	p.offset_bottom = -50
	add_child(p)
	var v := UI.vbox(14)
	p.add_child(UI.margin(v, 30, 22, 30, 22))
	var head := UI.hbox(10)
	head.add_child(UI.label(Story.ui("case_file"), 32, UI.PAPER, "title"))
	head.add_child(UI.spacer(false))
	head.add_child(UI.button("✕  " + Story.ui("close"), _close, 18))
	v.add_child(head)
	tabs_row = UI.hbox(8)
	v.add_child(tabs_row)
	for i in TABS.size():
		var b := UI.button(Story.ui(TABS[i]), _show.bind(i), 18)
		b.toggle_mode = true
		tabs_row.add_child(b)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body = UI.vbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(UI.margin(body, 6, 6, 18, 6))
	(sc.get_child(0) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	_show(int(args.get("tab", 1)))


func _close() -> void:
	_save_notes()
	m().close_overlay(back)


func _save_notes() -> void:
	if notes_edit and is_instance_valid(notes_edit):
		Game.notes[str(Game.night)] = notes_edit.text
		Game.save_game()


func _show(i: int) -> void:
	_save_notes()
	notes_edit = null
	current_tab = i
	for j in tabs_row.get_child_count():
		(tabs_row.get_child(j) as Button).button_pressed = j == i
	for c in body.get_children():
		c.queue_free()
	match TABS[i]:
		"victim": _victim()
		"evidence": _evidence()
		"testimony": _testimony()
		"suspects": _suspects()
		"notebook": _notebook()


func _paper(child: Control) -> PanelContainer:
	return UI.panel(UI.margin(child, 22, 16, 22, 16), UI.flat(UI.PAPER, 3, Color("8a7a5a"), 1, 0))


func _paper_text(bb: String, size := 19) -> RichTextLabel:
	var r := UI.rich(bb, size, "body")
	r.add_theme_color_override("default_color", UI.PAPER_INK)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r


func _victim() -> void:
	var vic: Dictionary = Story.data.victim
	var row := UI.hbox(24)
	var img := UI.cover(UI.scene_tex(vic.image), 0.0)
	img.custom_minimum_size = Vector2(360, 480)
	img.clip_contents = true
	row.add_child(img)
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(Story.t(vic.name), 30, UI.PAPER_INK, "title"))
	v.add_child(_paper_text(Story.t(vic.dossier).replace("\n\n", "\n\n"), 20))
	row.add_child(v)
	body.add_child(_paper(row))


func _evidence() -> void:
	for ev in Story.all_evidence():
		var owned: bool = ev.id in Game.evidence_owned
		var row := UI.hbox(20)
		var img := UI.cover(UI.evidence_tex(ev.image) if owned else null, 0.0)
		img.custom_minimum_size = Vector2(200, 150)
		img.clip_contents = true
		row.add_child(img)
		var v := UI.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if owned:
			v.add_child(UI.label(Story.t(ev.name), 24, UI.PAPER_INK, "title"))
			v.add_child(_paper_text(Story.t(ev.desc)))
		else:
			v.add_child(UI.label("? ? ?", 24, Color(UI.PAPER_INK, 0.35), "title"))
			v.add_child(_paper_text("[i]" + ("Not yet found." if Settings.lang == "en" else "هنوز پیدا نشده.") + "[/i]"))
		row.add_child(v)
		var p := _paper(row)
		if not owned:
			p.modulate = Color(1, 1, 1, 0.45)
		body.add_child(p)


func _testimony() -> void:
	if Game.testimonies.is_empty():
		body.add_child(UI.label(Story.ui("no_testimony"), 20, UI.DIM, "serif_italic", true))
		return
	for s in Story.suspects:
		var entries := Game.testimonies.filter(func(e): return e.suspect == s.id)
		if entries.is_empty():
			continue
		var v := UI.vbox(8)
		v.add_child(UI.label(Story.t(s.name) + "  ·  " + Story.t(s.role), 24, Color(s.color).darkened(0.35), "title"))
		for e in entries:
			var night_tag := Story.ui("night") + " " + Story.num(e.night) + " — "
			var txt := Game.testimony_text(e)
			if e.get("unreliable", false):
				txt = "[color=#a3262c][b]" + Story.ui("unreliable") + "[/b][/color]\n" + txt
			v.add_child(_paper_text("[color=#6b5a3a]" + night_tag + "[/color]" + txt))
		body.add_child(_paper(v))


func _suspects() -> void:
	for s in Story.suspects:
		var row := UI.hbox(20)
		var img := UI.cover(UI.portrait(s.id), 0.0)
		img.custom_minimum_size = Vector2(170, 226)
		img.clip_contents = true
		row.add_child(img)
		var v := UI.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label(Story.t(s.name) + "  ·  " + Story.t(s.role), 24, UI.PAPER_INK, "title"))
		v.add_child(_paper_text(Story.t(s.dossier), 18))
		row.add_child(v)
		body.add_child(_paper(row))


func _notebook() -> void:
	# Past judgements and notes, then an editable page for tonight.
	for i in Game.judgements.size():
		var sus_id: String = Game.judgements[i]
		var who := Story.t(Story.suspect(sus_id).name) if sus_id != "" else Story.ui("no_one")
		var txt := "[b]" + Story.ui("night") + " " + Story.num(i + 1) + "[/b] — " + Story.ui("judged") + ": " + who
		var n: String = Game.notes.get(str(i + 1), "")
		if n.strip_edges() != "":
			txt += "\n[i]" + n.replace("[", "(") + "[/i]"
		body.add_child(_paper(_paper_text(txt)))
	var head := UI.label(Story.ui("night") + " " + Story.num(Game.night), 24, UI.PAPER, "title")
	body.add_child(head)
	notes_edit = TextEdit.new()
	UI.rtl_input(notes_edit)
	notes_edit.placeholder_text = Story.ui("notes_hint")
	notes_edit.custom_minimum_size = Vector2(0, 320)
	notes_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	notes_edit.add_theme_font_size_override("font_size", 20)
	notes_edit.text = Game.notes.get(str(Game.night), "")
	body.add_child(notes_edit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
