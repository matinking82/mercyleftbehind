extends Screen
## Language, interrogation mode, AI server, audio and display.

var url_edit: LineEdit
var key_edit: LineEdit
var model_edit: LineEdit
var models_row: HFlowContainer
var status: Label
var _testing := false


func setup(_args: Dictionary) -> void:
	add_background("menu", 0.7)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(UI.full_rect(sc))
	var col := UI.vbox(16)
	col.custom_minimum_size.x = 900
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(UI.margin(col, 0, 40, 0, 40))
	sc.add_child(center)

	col.add_child(UI.label(Story.ui("settings"), 44, UI.PAPER, "title"))

	col.add_child(_section(Story.ui("language")))
	var lang_row := UI.hbox(12)
	var lg := ButtonGroup.new()
	for pair in [["fa", "فارسی"], ["en", "English"]]:
		var b := UI.button(pair[1], func(): _set_lang(pair[0]), 20, 160)
		b.toggle_mode = true
		b.button_group = lg
		b.button_pressed = Settings.lang == pair[0]
		lang_row.add_child(b)
	col.add_child(lang_row)

	col.add_child(_section(Story.ui("game_mode")))
	var mg := ButtonGroup.new()
	for md in ["ai", "classic"]:
		var cb := CheckBox.new()
		cb.text = Story.ui("mode_" + md)
		cb.button_group = mg
		cb.button_pressed = Settings.mode == md
		cb.add_theme_font_size_override("font_size", 19)
		cb.toggled.connect(func(on): if on: Settings.mode = md)
		col.add_child(cb)

	col.add_child(_section("AI"))
	col.add_child(UI.label(Story.ui("ai_server"), 16, UI.DIM))
	url_edit = _edit(Settings.ai_base_url)
	col.add_child(url_edit)
	col.add_child(UI.label(Story.ui("ai_model"), 16, UI.DIM))
	model_edit = _edit(Settings.ai_model)
	var model_line := UI.hbox(10)
	model_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	model_line.add_child(model_edit)
	model_line.add_child(UI.button(Story.ui("find_models"), _find_models, 17))
	col.add_child(model_line)
	models_row = HFlowContainer.new()
	models_row.add_theme_constant_override("h_separation", 8)
	models_row.add_theme_constant_override("v_separation", 8)
	col.add_child(models_row)
	col.add_child(UI.label(Story.ui("ai_key"), 16, UI.DIM))
	key_edit = _edit(Settings.ai_key)
	key_edit.secret = true
	col.add_child(key_edit)
	var ai_row := UI.hbox(12)
	ai_row.add_child(UI.button(Story.ui("preset_ollama"), func():
		url_edit.text = "http://127.0.0.1:11434/v1"
		key_edit.text = ""
		model_edit.text = "gemma3n:latest", 17))
	ai_row.add_child(UI.button(Story.ui("ai_test"), _test, 17))
	status = UI.label("", 17, UI.DIM, "body", true)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_row.add_child(status)
	col.add_child(ai_row)

	col.add_child(_section(Story.ui("music")))
	var vol := HSlider.new()
	vol.min_value = 0
	vol.max_value = 1
	vol.step = 0.05
	vol.value = Settings.music_volume
	vol.custom_minimum_size = Vector2(400, 24)
	vol.value_changed.connect(func(v): Settings.music_volume = v; Audio._apply_volume())
	col.add_child(vol)

	col.add_child(_section(Story.ui("text_speed")))
	var spd := HSlider.new()
	spd.min_value = 0
	spd.max_value = 2
	spd.step = 0.25
	spd.value = Settings.text_speed
	spd.custom_minimum_size = Vector2(400, 24)
	spd.value_changed.connect(func(v): Settings.text_speed = v)
	col.add_child(spd)

	var fs := CheckBox.new()
	fs.text = Story.ui("fullscreen")
	fs.button_pressed = Settings.fullscreen
	fs.add_theme_font_size_override("font_size", 19)
	fs.toggled.connect(func(on): Settings.fullscreen = on)
	col.add_child(fs)

	var foot := UI.hbox(14)
	foot.add_child(UI.button(Story.ui("back"), _back, 20, 160))
	foot.add_child(UI.button(Story.ui("save"), _save, 20, 200))
	col.add_child(UI.margin(foot, 0, 20, 0, 0))


func _section(text: String) -> Label:
	var l := UI.label(text, 22, UI.GOLD, "title")
	return l


func _edit(value: String) -> LineEdit:
	var e := LineEdit.new()
	e.text = value
	e.custom_minimum_size = Vector2(0, 44)
	e.add_theme_font_size_override("font_size", 18)
	e.text_direction = Control.TEXT_DIRECTION_LTR
	return e


func _set_lang(l: String) -> void:
	if Settings.lang == l:
		return
	_store()
	Settings.lang = l
	Settings.save_settings()
	m().goto("settings", {}, 0.2)


func _store() -> void:
	Settings.ai_base_url = url_edit.text.strip_edges()
	Settings.ai_key = key_edit.text.strip_edges()
	Settings.ai_model = model_edit.text.strip_edges()


func _save() -> void:
	_store()
	Settings.save_settings()
	m().goto("menu")


func _back() -> void:
	Settings.load_settings()
	m().goto("menu")


func _test() -> void:
	if _testing:
		return
	_store()
	_testing = true
	status.text = Story.ui("ai_testing")
	status.add_theme_color_override("font_color", UI.DIM)
	AI.finished.connect(_test_ok, CONNECT_ONE_SHOT)
	AI.failed.connect(_test_fail, CONNECT_ONE_SHOT)
	AI.chat([{"role": "user", "content": "Reply with the single word: ready"}], 12, 0.0)


func _test_ok(_text: String) -> void:
	if AI.failed.is_connected(_test_fail):
		AI.failed.disconnect(_test_fail)
	_testing = false
	status.text = Story.ui("ai_ok")
	status.add_theme_color_override("font_color", UI.GENTLE)


func _test_fail(err: String) -> void:
	if AI.finished.is_connected(_test_ok):
		AI.finished.disconnect(_test_ok)
	_testing = false
	status.text = Story.ui("ai_bad") % err
	status.add_theme_color_override("font_color", UI.PRESS)


## Ask a local Ollama which models are installed and offer them as buttons.
func _find_models() -> void:
	for c in models_row.get_children():
		c.queue_free()
	var base := url_edit.text.strip_edges().trim_suffix("/").trim_suffix("/v1").replace("localhost", "127.0.0.1")
	var req := HTTPRequest.new()
	req.timeout = 6.0
	add_child(req)
	req.request_completed.connect(func(result, code, _h, body):
		req.queue_free()
		var d = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
		if not d is Dictionary or not d.has("models") or d.models.is_empty():
			status.text = Story.ui("no_models")
			status.add_theme_color_override("font_color", UI.PRESS)
			return
		for mdl in d.models:
			var name: String = mdl.get("name", "")
			var b := UI.button(name, func(): model_edit.text = name, 16)
			if name == model_edit.text:
				b.add_theme_color_override("font_color", UI.GOLD)
			models_row.add_child(b))
	req.request(base + "/api/tags")
