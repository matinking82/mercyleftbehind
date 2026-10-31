extends Screen
## Judgement of the night: record a provisional suspect, then on to the next night (or the final accusation).

var chosen := ""
var buttons := {}
var notes: TextEdit


func setup(_args: Dictionary) -> void:
	Audio.play("main_theme")
	add_background("hub", 0.75)
	var col := UI.vbox(20)
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	col.custom_minimum_size = Vector2(1100, 0)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(col)
	var t := UI.label(Story.ui("judgement_title") + "  ·  " + Story.ui("night") + " " + Story.num(Game.night), 40, UI.PAPER, "title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var d := UI.label(Story.ui("judgement_text"), 20, UI.DIM, "serif_italic", true)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(d)

	var row := UI.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for s in Story.suspects:
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(160, 250)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("pressed", UI.flat(Color(UI.RED_DIM, 0.9), 4, UI.RED, 3, 0))
		b.add_theme_stylebox_override("normal", UI.flat(Color(0.07, 0.07, 0.08, 0.9), 4, Color(1, 1, 1, 0.1), 1, 0))
		var v := UI.vbox(6)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full_rect(v)
		var img := UI.cover(UI.portrait(s.id), 0.0)
		img.custom_minimum_size = Vector2(160, 200)
		img.clip_contents = true
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(img)
		var l := UI.label(Story.t(s.name), 18, UI.INK)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		b.add_child(v)
		b.pressed.connect(_pick.bind(s.id))
		buttons[s.id] = b
		row.add_child(b)
	col.add_child(row)

	notes = TextEdit.new()
	UI.rtl_input(notes)
	notes.placeholder_text = Story.ui("notes_hint")
	notes.custom_minimum_size = Vector2(0, 120)
	notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	notes.text = Game.notes.get(str(Game.night), "")
	col.add_child(notes)

	var foot := UI.hbox(16)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_child(UI.button(Story.ui("back"), func(): m().goto("hub"), 20, 160))
	foot.add_child(UI.button(Story.ui("seal_night"), _seal, 22, 260))
	col.add_child(foot)


func _pick(id: String) -> void:
	chosen = id if buttons[id].button_pressed else ""
	for k in buttons:
		if k != id:
			buttons[k].button_pressed = false


func _seal() -> void:
	Game.notes[str(Game.night)] = notes.text
	if Game.end_night(chosen):
		m().goto("hub")
		m().toast(Story.t(Story.data.nights[Game.night - 1]).replace("\n", "  —  "), UI.PAPER, 6.0)
	else:
		m().goto("accuse", {"forced": true})
