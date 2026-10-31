extends Control
## Root: swaps full screens with a fade, hosts overlays (case file, dialogs) and toasts.

const SCREENS := {
	"menu": preload("res://scripts/screens/MainMenu.gd"),
	"language": preload("res://scripts/screens/LanguageSelect.gd"),
	"intro": preload("res://scripts/screens/Intro.gd"),
	"hub": preload("res://scripts/screens/Hub.gd"),
	"room": preload("res://scripts/screens/Interrogation.gd"),
	"night_end": preload("res://scripts/screens/NightEnd.gd"),
	"accuse": preload("res://scripts/screens/Accusation.gd"),
	"ending": preload("res://scripts/screens/Ending.gd"),
	"settings": preload("res://scripts/screens/SettingsScreen.gd"),
	"howto": preload("res://scripts/screens/HowTo.gd"),
}

var screen_layer: Control
var overlay_layer: Control
var toast_box: VBoxContainer
var fade: ColorRect
var current: Control
var current_name := ""


func _ready() -> void:
	theme = UI.theme()
	var bg := ColorRect.new()
	bg.color = UI.BG
	add_child(UI.full_rect(bg))
	screen_layer = UI.full_rect(Control.new())
	add_child(screen_layer)
	overlay_layer = UI.full_rect(Control.new())
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay_layer)
	toast_box = UI.vbox(8)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_box.position.y = 24
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(toast_box)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.full_rect(fade))
	Settings.changed.connect(_apply_direction)
	_apply_direction()
	goto("language" if Settings.first_run else "menu", {}, 0.0)
	_maybe_autotest()


func _apply_direction() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_RTL if Settings.is_rtl() else Control.LAYOUT_DIRECTION_LTR


func goto(name: String, args := {}, fade_time := 0.45) -> void:
	close_overlays()
	if fade_time > 0.0:
		var tw := create_tween()
		tw.tween_property(fade, "modulate:a", 1.0, fade_time)
		await tw.finished
	if current:
		current.queue_free()
	current = SCREENS[name].new()
	current_name = name
	current.set_meta("main", self)
	UI.full_rect(current)
	screen_layer.add_child(current)
	if current.has_method("setup"):
		current.setup(args)
	fade.modulate.a = 1.0
	var tw2 := create_tween()
	tw2.tween_property(fade, "modulate:a", 0.0, maxf(fade_time, 0.25))


## Put a modal control above the current screen, with a dim backdrop. Returns the backdrop.
func overlay(content: Control, dim := 0.72) -> Control:
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var back := ColorRect.new()
	back.color = Color(0, 0, 0, dim)
	UI.full_rect(back)
	overlay_layer.add_child(back)
	back.add_child(content)
	# A click on the dim backdrop (outside the panel) dismisses it, like Cancel.
	back.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			close_overlay(back))
	back.modulate.a = 0.0
	create_tween().tween_property(back, "modulate:a", 1.0, 0.2)
	return back


func open_overlays() -> Array[Node]:
	return overlay_layer.get_children().filter(func(c): return not c.is_queued_for_deletion())


## Hide at once (so it stops catching the mouse this very frame) and free later. Safe to call from button lambdas.
func close_overlay(back: Control) -> void:
	if is_instance_valid(back) and not back.is_queued_for_deletion():
		back.hide()
		back.queue_free()
	if open_overlays().is_empty():
		overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_hover.call_deferred()


## Close the most recently opened overlay (dialogs, pickers).
func close_top_overlay() -> void:
	var open := open_overlays()
	if not open.is_empty():
		close_overlay(open.back())


func close_overlays() -> void:
	for c in overlay_layer.get_children():
		c.hide()
		c.queue_free()
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Godot only re-picks the control under the mouse when the mouse moves; nudge it so the screen
## beneath a closed overlay hovers at once instead of looking dead until the next wiggle.
func _refresh_hover() -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = get_viewport().get_mouse_position()
	mm.global_position = mm.position
	get_viewport().push_input(mm, true)


func _unhandled_input(event: InputEvent) -> void:
	# Escape closes the top overlay on any screen (screens with their own Escape handling see it first).
	if event.is_action_pressed("ui_cancel") and not open_overlays().is_empty():
		get_viewport().set_input_as_handled()
		close_top_overlay()


## A yes/no dialog.
func confirm(text: String, on_yes: Callable) -> void:
	var box := UI.vbox(20)
	var l := UI.label(text, 22, UI.INK, "body", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 520
	box.add_child(l)
	var row := UI.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.button(Story.ui("yes"), func(): close_top_overlay(); on_yes.call(), 20, 140))
	row.add_child(UI.button(Story.ui("no"), func(): close_top_overlay(), 20, 140))
	box.add_child(row)
	var p := UI.panel(UI.margin(box, 36, 30, 36, 30), UI.flat(UI.PANEL, 8, Color(UI.RED, 0.6), 1, 0))
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay(p)


func toast(text: String, color := UI.GOLD, seconds := 4.0) -> void:
	var l := UI.label(text, 19, color, "bold")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var p := UI.panel(UI.margin(l, 22, 10, 22, 10), UI.flat(Color(0.05, 0.05, 0.06, 0.95), 6, Color(color, 0.7), 1, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_child(p)
	p.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.25)
	tw.tween_interval(seconds)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


func open_case_file(tab := 0) -> void:
	var cf := preload("res://scripts/screens/CaseFile.gd").new()
	cf.set_meta("main", self)
	var back := overlay(cf, 0.8)
	cf.setup({"tab": tab, "back": back})


# ---------------------------------------------------------------- automated checks for development

## Plays the intended solution through the real rules (scripted mode) and reports what unlocked.
func _selftest() -> void:
	Game.new_game()
	var used := 0
	# [suspect, tone, topics, evidence]
	var steps := [
		["garon", "neutral", [], "dagger"],
		["branko", "neutral", [], "true_mark"],
		["branko", "neutral", [], "ledger"],
		["dragan", "gentle", ["self"], ""], ["dragan", "gentle", ["beggar"], ""],
		["dragan", "gentle", [], "draught"],
		["dragan", "gentle", ["night"], "log"],
		["sara", "neutral", [], "log"],
		["ronan", "neutral", [], "cloak"],
		["ronan", "press", ["self"], ""], ["ronan", "press", ["night"], ""],
		["mikail", "gentle", ["self"], ""], ["mikail", "gentle", ["beggar"], ""], ["mikail", "gentle", ["past"], ""],
		["mikail", "gentle", ["special"], ""],
		["ronan", "neutral", [], "crescent"],
		["branko", "press", ["self"], ""], ["branko", "press", ["past"], ""],
		["sara", "neutral", [], "offering"],
		["mikail", "gentle", ["others"], ""], ["mikail", "gentle", ["night"], ""],
		["garon", "gentle", ["self"], ""], ["garon", "gentle", ["past"], ""], ["garon", "gentle", ["beggar"], ""],
	]
	for st in steps:
		if st[3] != "" and not st[3] in Game.evidence_owned:
			print("  MISSING EVIDENCE ", st[3], " before asking ", st[0])
			continue
		used += 1
		Game.apply_tone(st[0], st[1])
		var r := Game.evaluate(st[0], st[2], st[3])
		if not r.secret.is_empty():
			Game.reveal(st[0], r.secret)
			print("  + ", r.secret.id, "  (", st[0], ")")
		elif not r.locked.is_empty():
			print("  . locked ", r.locked.id, " comp=", Game.composure(st[0]), " trust=", Game.trust(st[0]))
		else:
			print("  - nothing from ", st[0], " ", st[2], " ", st[3])
	print("SELFTEST questions used: ", used, " / ", Game.nights_total() * int(Story.data.candles_per_night))
	print("SELFTEST secrets: ", Game.revealed.size(), " / ", Story.total_secrets(), "  evidence: ", Game.evidence_owned.size(), " / ", Story.all_evidence().size())
	print("SELFTEST ending: ", Game.accuse("sara", "draught_dagger", "prince"))
	Game.active = false
	Game.save_game()


## Presses real buttons in the evidence picker and dialogs and reports whether they close.
func _uitest() -> void:
	Settings.mode = "classic"
	Game.new_game()
	goto("room", {"suspect": "garon"}, 0.0)
	await get_tree().create_timer(0.4).timeout
	current._open_evidence()
	await get_tree().create_timer(0.3).timeout
	print("UITEST picker open: ", overlay_layer.get_child_count())
	_find_button(overlay_layer, Story.ui("cancel")).pressed.emit()
	await get_tree().create_timer(0.3).timeout
	print("UITEST after cancel: ", overlay_layer.get_child_count())
	current._open_evidence()
	await get_tree().create_timer(0.3).timeout
	var card: Button = _find_button(overlay_layer, "", true)
	card.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	print("UITEST after choosing evidence: ", overlay_layer.get_child_count(), "  candles: ", Game.candles)
	for tp in Story.topics_for("garon"):
		while current.busy:
			await get_tree().create_timer(0.2).timeout
		current._ask_topic(tp)
	while current.busy:
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.5).timeout
	var bar: VScrollBar = current.log_scroll.get_v_scroll_bar()
	print("UITEST scroll at bottom: ", current.log_scroll.scroll_vertical >= int(bar.max_value - bar.page) - 2, " (", current.log_scroll.scroll_vertical, "/", bar.max_value - bar.page, ")")
	confirm("test?", func(): pass)
	await get_tree().create_timer(0.3).timeout
	_find_button(overlay_layer, Story.ui("no")).pressed.emit()
	await get_tree().create_timer(0.3).timeout
	print("UITEST after confirm No: ", overlay_layer.get_child_count())
	# Hub overlays: every way of closing must leave the suspect cards hoverable and clickable.
	for way in ["case_file_x", "instinct_close", "instinct_escape", "instinct_backdrop"]:
		goto("hub", {}, 0.0)
		await get_tree().create_timer(0.3).timeout
		if way == "case_file_x":
			open_case_file(1)
		else:
			current._instinct()
		await get_tree().create_timer(0.3).timeout
		match way:
			"case_file_x":
				await _click(_find_button(overlay_layer, "✕  " + Story.ui("close")).get_global_rect().get_center())
			"instinct_close":
				await _click(_find_button(overlay_layer, Story.ui("close")).get_global_rect().get_center())
			"instinct_escape":
				var k := InputEventKey.new()
				k.keycode = KEY_ESCAPE
				k.pressed = true
				Input.parse_input_event(k)
				await get_tree().process_frame
			"instinct_backdrop":
				await _click(Vector2(60, 860))
		await get_tree().create_timer(0.1).timeout
		var hov := get_viewport().gui_get_hovered_control()
		var card_ok := false
		await _click(Vector2(400, 300))  # a suspect card: should open the room
		await get_tree().create_timer(0.8).timeout
		card_ok = current_name == "room"
		print("UITEST hub ", way, ": overlays ", open_overlays().size(), "  hovered ", hov.get_class() if hov else "none", "  card opens room ", card_ok)
	Game.active = false
	Game.save_game()


func _click(pos: Vector2) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = pos
	mm.global_position = pos
	get_viewport().push_input(mm, true)
	await get_tree().process_frame
	for down in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = down
		mb.position = pos
		mb.global_position = pos
		get_viewport().push_input(mb, true)
		await get_tree().process_frame


func _find_button(root: Node, text: String, with_tooltip := false) -> Button:
	for c in root.get_children():
		if c is Button and not c.is_queued_for_deletion() and ((with_tooltip and c.tooltip_text != "") or (not with_tooltip and c.text == text)):
			return c
		var found := _find_button(c, text, with_tooltip)
		if found:
			return found
	return null


# ---------------------------------------------------------------- automated screenshots for development

## `godot -- --shot=<screen>[,<screen>...]` renders each listed screen, saves PNGs to user://shots and quits.
func _maybe_autotest() -> void:
	var shots := ""
	var lang := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shots = a.substr(7)
		elif a.begins_with("--mode="):
			Settings.mode = a.substr(7)
		elif a.begins_with("--lang="):
			lang = a.substr(7)
	if "--uitest" in OS.get_cmdline_user_args():
		await _uitest()
		get_tree().quit()
		return
	if "--selftest" in OS.get_cmdline_user_args():
		_selftest()
		get_tree().quit()
		return
	if shots == "":
		return
	if lang != "":
		Settings.lang = lang
		_apply_direction()
	if not Game.active:
		Game.new_game()
	DirAccess.make_dir_recursive_absolute("user://shots")
	for s in shots.split(","):
		var parts := s.split(":")
		var args := {}
		if parts.size() > 1:
			args = {"suspect": parts[1], "page": int(parts[1]) if parts[1].is_valid_int() else 0, "ending": parts[1]}
		if parts[0] == "ask":
			# ask:<suspect>:<question>[:<evidence>[:<tone>]] — run one real exchange, then screenshot.
			goto("room", {"suspect": parts[1]}, 0.0)
			await get_tree().create_timer(0.5).timeout
			var ev_id := parts[3] if parts.size() > 3 else ""
			if parts.size() > 4:
				current.tone = parts[4]
			current._ask(parts[2], Game.detect_topics(parts[1], parts[2]), ev_id)
			var waited := 0.0
			while current.busy and waited < 180.0:
				await get_tree().create_timer(0.5).timeout
				waited += 0.5
			print("REPLY: ", Game.history[parts[1]][-1].text)
			current.input.text = parts[2]  # show typed text in the field too, to check its direction
		elif parts[0] == "casefile":
			goto("hub", {}, 0.0)
			await get_tree().create_timer(0.6).timeout
			open_case_file(int(parts[1]) if parts.size() > 1 else 1)
		else:
			goto(parts[0], args, 0.0)
		await get_tree().create_timer(1.6).timeout
		var img := get_viewport().get_texture().get_image()
		var fname := s.get_slice(":", 0) + "_" + s.get_slice(":", 1) if s.contains(":") else s
		img.save_png("user://shots/%s_%s.png" % [fname, Settings.lang])
	get_tree().quit()
