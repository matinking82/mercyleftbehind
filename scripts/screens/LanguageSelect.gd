extends Screen
## First launch: pick the language before anything else.


func setup(_args: Dictionary) -> void:
	add_background("menu", 0.6)
	var box := UI.vbox(28)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.full_rect(box)
	add_child(box)
	var t := UI.label("رحمتی که جا ماند  ·  The Mercy Left Behind", 34, UI.PAPER, "title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var row := UI.hbox(24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.button("فارسی", func(): _pick("fa"), 28, 220))
	row.add_child(UI.button("English", func(): _pick("en"), 28, 220))
	box.add_child(row)


func _pick(lang: String) -> void:
	Settings.lang = lang
	Settings.first_run = false
	Settings.save_settings()
	m().goto("menu")
