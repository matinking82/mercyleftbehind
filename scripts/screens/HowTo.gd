extends Screen


func setup(_args: Dictionary) -> void:
	add_background("hub", 0.7)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(UI.full_rect(sc))
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(center)
	var col := UI.vbox(18)
	col.custom_minimum_size.x = 1000
	center.add_child(UI.margin(col, 0, 40, 0, 40))
	col.add_child(UI.label(Story.ui("how_to"), 42, UI.PAPER, "title"))
	var r := UI.rich(Story.ui("how_to_text").replace("[b]", "[b][color=#c9a45a]").replace("[/b]", "[/color][/b]"), 19, "body")
	r.custom_minimum_size.x = 1000
	col.add_child(r)
	col.add_child(UI.button(Story.ui("back"), func(): m().goto("menu"), 20, 180))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		m().goto("menu")
