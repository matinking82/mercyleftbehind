extends Screen
## Endings: illustrated pages, then the case tally.

var pages: Array
var index := 0
var text: RichTextLabel
var title: Label
var data: Dictionary
var tw: Tween


func setup(args: Dictionary) -> void:
	var id: String = args.get("ending", Game.ending_id if Game.ending_id != "" else "half")
	if not Story.data.endings.has(id):
		id = "half"
	data = Story.data.endings[id]
	pages = data.pages
	Audio.play("sara" if id == "true" else "main_theme")
	var bg := add_background(data.image, 0.35)
	add_slow_zoom(bg, 0.05, 25.0)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.full_rect(shade))

	var col := UI.vbox(26)
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	col.custom_minimum_size = Vector2(1100, 0)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(col)
	title = UI.label(Story.t(data.title), 52, UI.PAPER if id == "true" else UI.RED, "title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	text = UI.rich("", 25)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.custom_minimum_size = Vector2(1100, 0)
	col.add_child(text)
	var next := UI.button(Story.ui("next") + "  ▸", _advance, 20, 200)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.name = "Next"
	col.add_child(next)
	_show(0)


func _show(i: int) -> void:
	index = i
	text.text = "[center]" + Story.t(pages[i]).replace("\n", "\n\n") + "[/center]"
	text.visible_ratio = 0.0
	if tw:
		tw.kill()
	tw = create_tween()
	tw.tween_property(text, "visible_ratio", 1.0, text.get_total_character_count() * 0.02 / maxf(Settings.text_speed, 0.05))


func _advance() -> void:
	if text.visible_ratio < 1.0:
		tw.kill()
		text.visible_ratio = 1.0
		return
	if index + 1 < pages.size():
		_show(index + 1)
	else:
		_final()


func _final() -> void:
	var col := text.get_parent()
	col.get_node("Next").queue_free()
	title.text = Story.ui("the_end")
	var total_ev := Story.all_evidence().size()
	text.text = "[center]" + Story.ui("stats") % [Story.num(Game.evidence_owned.size()), Story.num(total_ev),
		Story.num(Game.revealed.size()), Story.num(Story.total_secrets()), Story.num(Game.night)] + "[/center]"
	text.visible_ratio = 1.0
	var b := UI.button(Story.ui("to_menu"), func():
		Game.active = false
		Game.save_game()
		m().goto("menu"), 22, 320)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(b)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and index < pages.size():
		_advance()
