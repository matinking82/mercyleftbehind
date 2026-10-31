extends Screen
## The cold open: illustrated pages with typewriter text. Click/Space to advance, Skip to jump in.

var pages: Array
var index := 0
var art_holder: Control
var text: RichTextLabel
var typing_tween: Tween


func setup(_args: Dictionary) -> void:
	Audio.play("main_theme")
	pages = Story.data.intro
	# Every layer is click-through so a click anywhere advances the story.
	art_holder = UI.full_rect(Control.new())
	art_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art_holder)
	add_child(UI.full_rect(Vignette.new()))

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	shade.offset_top = -300
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	text = UI.rich("", 26, "type" if Settings.lang == "en" else "")
	text.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text.offset_left = 160
	text.offset_right = -160
	text.offset_top = -270
	text.offset_bottom = -60
	text.fit_content = false
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text)

	var bar := UI.hbox(12)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT if not Settings.is_rtl() else Control.PRESET_TOP_LEFT)
	bar.position = Vector2(1600 - 220, 24) if not Settings.is_rtl() else Vector2(24, 24)
	bar.add_child(UI.button(Story.ui("skip"), _finish, 18))
	add_child(bar)

	var hint := UI.label(("click to continue  ▸" if Settings.lang == "en" else "◂  برای ادامه کلیک کن"), 17, UI.GOLD)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT if not Settings.is_rtl() else Control.PRESET_BOTTOM_LEFT)
	hint.position += Vector2(-230 if not Settings.is_rtl() else 60, -50)
	add_child(hint)
	var blink := create_tween().set_loops()
	blink.tween_property(hint, "modulate:a", 0.2, 0.7)
	blink.tween_property(hint, "modulate:a", 1.0, 0.7)
	_show(clampi(int(_args.get("page", 0)), 0, pages.size() - 1))


func _show(i: int) -> void:
	index = i
	var page: Dictionary = pages[i]
	for c in art_holder.get_children():
		var old := c as Control
		var fade_out := create_tween()
		fade_out.tween_property(old, "modulate:a", 0.0, 0.8)
		fade_out.tween_callback(old.queue_free)
	var art := UI.full_rect(UI.cover_fit(UI.scene_tex(page.get("image", "")), 0.15))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate.a = 0.0
	art_holder.add_child(art)
	create_tween().tween_property(art, "modulate:a", 1.0, 1.0)
	add_slow_zoom(art, 0.05, 20.0)
	text.text = Story.t(page).replace("\n", "\n\n")
	text.visible_ratio = 0.0
	if typing_tween:
		typing_tween.kill()
	var secs := text.get_total_character_count() * 0.028 / maxf(Settings.text_speed, 0.01)
	if Settings.text_speed <= 0.0:
		text.visible_ratio = 1.0
	else:
		typing_tween = create_tween()
		typing_tween.tween_property(text, "visible_ratio", 1.0, secs)


func _advance() -> void:
	if text.visible_ratio < 1.0:
		if typing_tween:
			typing_tween.kill()
		text.visible_ratio = 1.0
		return
	if index + 1 < pages.size():
		_show(index + 1)
	else:
		_finish()


func _finish() -> void:
	m().goto("hub")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance()
	elif event.is_action_pressed("ui_cancel"):
		_finish()
