extends Screen
## Room B. One suspect, one lamp. Ask (typed or by topic), choose a tone, show evidence.

var sid := ""
var sus: Dictionary
var tone := "neutral"
var busy := false

var portrait_a: TextureRect
var portrait_b: TextureRect
var mood_label: Label
var comp_bar: ProgressBar
var trust_bar: ProgressBar
var candle_label: Label
var log_scroll: ScrollContainer
var log_box: VBoxContainer
var chips: HFlowContainer
var input: LineEdit
var ask_btn: Button
var ev_btn: Button
var leave_btn: Button

# Streaming state for the current reply.
var _stream_label: RichTextLabel
var _stream_raw := ""
var _pending := {}
var _follow := true   # keep the transcript pinned to the newest line unless the player scrolls up


func setup(args: Dictionary) -> void:
	sid = args.get("suspect", "garon")
	sus = Story.suspect(sid)
	Audio.play(sus.music)
	add_background("room", 0.5)
	_build()
	AI.token.connect(_on_token)
	AI.finished.connect(_on_finished)
	AI.failed.connect(_on_failed)
	var first_ever := true
	for k in Game.history:
		if not Game.history[k].is_empty():
			first_ever = false
	if first_ever:
		_add_note(Story.ui("first_tip_" + Settings.mode), UI.GOLD)
	if Game.history[sid].is_empty():
		var g: Dictionary = sus.greeting
		_add_suspect_line(Story.t(g))
		Game.add_history(sid, "suspect", Story.t(g))
		_set_mood(g.get("mood", "calm"), true)
	else:
		for h in Game.history[sid].slice(maxi(0, Game.history[sid].size() - 16)):
			if h.role == "player":
				_add_player_line(h.text)
			else:
				_add_suspect_line(h.text)
		_set_mood("calm", true)
	_refresh()
	await get_tree().process_frame
	_scroll_end()
	if Settings.mode == "ai":
		input.grab_focus()


func _exit_tree() -> void:
	if AI.token.is_connected(_on_token):
		AI.token.disconnect(_on_token)
		AI.finished.disconnect(_on_finished)
		AI.failed.disconnect(_on_failed)
	if busy:
		AI.cancel()


# ---------------------------------------------------------------- layout

func _build() -> void:
	var row := UI.hbox(30)
	add_child(UI.full_rect(UI.margin(row, 40, 30, 40, 26)))

	# Left: the suspect.
	var left := UI.vbox(10)
	left.custom_minimum_size.x = 560
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(560, 680)
	frame.clip_contents = true
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_b = _portrait_rect()
	portrait_a = _portrait_rect()
	frame.add_child(portrait_b)
	frame.add_child(portrait_a)
	var edge := UI.full_rect(Vignette.new())
	frame.add_child(edge)
	var border := Panel.new()
	border.add_theme_stylebox_override("panel", UI.flat(Color.TRANSPARENT, 4, Color(sus.color, 0.45), 1, 0))
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(UI.full_rect(border))
	left.add_child(frame)
	var name_row := UI.hbox(14)
	var name_l := UI.label(Story.t(sus.name), 34, UI.PAPER, "title")
	name_row.add_child(name_l)
	var role_l := UI.label(Story.t(sus.role), 18, Color(sus.color))
	role_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(role_l)
	name_row.add_child(UI.spacer(false))
	mood_label = UI.label("", 18, UI.DIM, "serif_italic")
	mood_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(mood_label)
	left.add_child(name_row)
	var meters := UI.hbox(24)
	var cm := UI.meter(Story.ui("composure"), Game.composure(sid), UI.COLD, 260)
	comp_bar = cm.get_node("Bar")
	var tm := UI.meter(Story.ui("trust"), Game.trust(sid), UI.GENTLE, 260)
	trust_bar = tm.get_node("Bar")
	meters.add_child(cm)
	meters.add_child(tm)
	left.add_child(meters)
	row.add_child(left)

	# Right: the conversation.
	var right := UI.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := UI.hbox(12)
	candle_label = UI.label("", 18, UI.GOLD)
	candle_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(candle_label)
	top.add_child(UI.spacer(false))
	top.add_child(UI.button("📁  " + Story.ui("case_file"), func(): m().open_case_file(1), 17))
	leave_btn = UI.button("⎋  " + Story.ui("leave_room"), _leave, 17)
	top.add_child(leave_btn)
	right.add_child(top)

	log_scroll = ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbar := log_scroll.get_v_scroll_bar()
	vbar.changed.connect(func():
		if _follow:
			log_scroll.scroll_vertical = int(vbar.max_value))
	vbar.value_changed.connect(func(v): _follow = v >= vbar.max_value - vbar.page - 40.0)
	log_box = UI.vbox(16)
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(UI.margin(log_box, 22, 18, 22, 18))
	(log_scroll.get_child(0) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(UI.panel(log_scroll, UI.flat(Color(0.03, 0.03, 0.035, 0.82), 6, Color(1, 1, 1, 0.06), 1, 0)))
	right.get_child(1).size_flags_vertical = Control.SIZE_EXPAND_FILL

	chips = HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	right.add_child(chips)

	var controls := UI.hbox(10)
	controls.add_child(UI.label(Story.ui("tone") + ":", 16, UI.DIM))
	(controls.get_child(0) as Label).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var group := ButtonGroup.new()
	for t in ["gentle", "neutral", "press"]:
		var tb := UI.button(Story.ui("tone_" + t), _set_tone.bind(t), 17)
		tb.toggle_mode = true
		tb.button_group = group
		tb.button_pressed = t == tone
		tb.tooltip_text = Story.ui("tone_" + t + "_tip")
		var col: Color = {"gentle": UI.GENTLE, "neutral": UI.INK, "press": UI.PRESS}[t]
		tb.add_theme_color_override("font_pressed_color", col)
		tb.add_theme_stylebox_override("pressed", UI.flat(Color(col, 0.16), 4, col, 1, 16))
		controls.add_child(tb)
	controls.add_child(UI.spacer(false))
	ev_btn = UI.button("🗝  " + Story.ui("present"), _open_evidence, 18)
	controls.add_child(ev_btn)
	right.add_child(controls)

	var ask_row := UI.hbox(10)
	input = LineEdit.new()
	UI.rtl_input(input)
	input.placeholder_text = Story.ui("type_question")
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size.y = 52
	input.add_theme_font_size_override("font_size", 20)
	input.text_submitted.connect(func(_t): _ask_typed())
	input.max_length = 400
	ask_row.add_child(input)
	ask_btn = UI.button(Story.ui("ask"), _ask_typed, 20, 120)
	ask_row.add_child(ask_btn)
	right.add_child(ask_row)
	ask_row.visible = Settings.mode == "ai"
	row.add_child(right)
	_build_chips()


func _portrait_rect() -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	UI.full_rect(r)
	return r


func _build_chips() -> void:
	for c in chips.get_children():
		c.queue_free()
	for tp in Story.topics_for(sid):
		var done: bool = tp.id in Game.asked[sid]
		var b := UI.button(("✓ " if done else "") + Story.t(tp.label), _ask_topic.bind(tp), 16)
		b.tooltip_text = Story.t(tp.question)
		if done:
			b.add_theme_color_override("font_color", UI.DIM)
		chips.add_child(b)


func _refresh() -> void:
	candle_label.text = "🕯 " + Story.ui("night") + " " + Story.num(Game.night) + "  ·  " + Story.num(Game.candles) + " " + Story.ui("questions_left")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(comp_bar, "value", Game.composure(sid), 0.6)
	tw.tween_property(trust_bar, "value", Game.trust(sid), 0.6)
	var out := Game.candles <= 0
	for c in chips.get_children():
		(c as Button).disabled = busy or out
	ev_btn.disabled = busy or out
	ask_btn.disabled = busy or out
	input.editable = not busy and not out
	if out:
		leave_btn.add_theme_stylebox_override("normal", UI.flat(Color(UI.RED_DIM, 0.95), 4, UI.RED, 1, 16))


# ---------------------------------------------------------------- transcript

func _entry(speaker: String, color: Color) -> RichTextLabel:
	var v := UI.vbox(2)
	var who := UI.label(speaker, 15, color, "bold")
	v.add_child(who)
	var r := UI.rich("", 21)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(r)
	log_box.add_child(v)
	return r


func _add_player_line(text: String) -> void:
	var r := _entry(Story.ui("you"), UI.GOLD)
	r.text = "[color=#cfc6b4]" + UI.dialogue_bbcode(text) + "[/color]"


func _add_suspect_line(text: String) -> RichTextLabel:
	var r := _entry(Story.t(sus.name), Color(sus.color).lightened(0.2))
	r.text = UI.dialogue_bbcode(text)
	return r


func _add_note(text: String, color := UI.DIM) -> void:
	var r := UI.rich("[i]" + text + "[/i]", 17)
	r.add_theme_color_override("default_color", color)
	log_box.add_child(r)


func _add_testimony_card(text: String, unreliable := false) -> void:
	var v := UI.vbox(4)
	var head := UI.label("✎  " + Story.ui("new_testimony") + ("  —  " + Story.ui("unreliable") if unreliable else ""), 15, Color("6b2a1c") if not unreliable else UI.RED, "bold")
	v.add_child(head)
	var r := UI.rich(text, 18, "body")
	r.add_theme_color_override("default_color", UI.PAPER_INK)
	v.add_child(r)
	var p := UI.panel(UI.margin(v, 16, 12, 16, 12), UI.flat(UI.PAPER, 3, Color("8a7a5a"), 1, 0))
	p.modulate.a = 0.0
	log_box.add_child(p)
	create_tween().tween_property(p, "modulate:a", 1.0, 0.6)


func _scroll_end() -> void:
	_follow = true
	for i in 2:  # rich text lays out over a frame or two before its height is final
		await get_tree().process_frame
		log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


# ---------------------------------------------------------------- mood / portrait

func _set_mood(mood: String, instant := false) -> void:
	mood_label.text = Story.t(sus.moods.get(mood, sus.moods.calm))
	var t := UI.portrait(sid, mood)
	if t == portrait_a.texture:
		return
	portrait_b.texture = portrait_a.texture
	portrait_b.modulate.a = 1.0
	portrait_a.texture = t
	if instant:
		portrait_a.modulate.a = 1.0
		return
	portrait_a.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(portrait_a, "modulate:a", 1.0, 0.7)
	# A small push-in on strong emotions.
	if mood != "calm":
		portrait_a.pivot_offset = Vector2(280, 300)
		portrait_a.scale = Vector2.ONE * 1.04
		create_tween().tween_property(portrait_a, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)


# ---------------------------------------------------------------- asking

func _set_tone(t: String) -> void:
	tone = t


func _ask_typed() -> void:
	var q := input.text.strip_edges()
	if q == "" or busy:
		return
	input.text = ""
	_ask(q, Game.detect_topics(sid, q), "")


func _ask_topic(tp: Dictionary) -> void:
	if busy:
		return
	_ask(Story.t(tp.question), [tp.id], "")


func _open_evidence() -> void:
	if busy:
		return
	var box := UI.vbox(16)
	box.add_child(UI.label(Story.ui("choose_evidence"), 26, UI.PAPER, "title"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for ev_id in Game.evidence_owned:
		var ev := Story.evidence(ev_id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 190)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = Story.t(ev.desc)
		b.add_theme_stylebox_override("normal", UI.flat(Color(0.08, 0.08, 0.09, 0.95), 4, Color(1, 1, 1, 0.1), 1, 0))
		b.add_theme_stylebox_override("hover", UI.flat(Color(0.14, 0.07, 0.07, 1), 4, UI.RED, 2, 0))
		var v := UI.vbox(4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full_rect(v)
		var img := UI.cover(UI.evidence_tex(ev.image), 0.0)
		img.custom_minimum_size = Vector2(250, 140)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.clip_contents = true
		v.add_child(img)
		var l := UI.label(Story.t(ev.name), 17, UI.INK)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		b.add_child(v)
		b.pressed.connect(func():
			m().close_top_overlay()
			_present(ev_id))
		grid.add_child(b)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1060, 560)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(grid)
	box.add_child(sc)
	var cancel := UI.button(Story.ui("cancel"), func(): m().close_top_overlay(), 18)
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(cancel)
	var p := UI.panel(UI.margin(box, 30, 24, 30, 24), UI.flat(UI.PANEL, 8, Color(1, 1, 1, 0.1), 1, 0))
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	m().overlay(p)


func _present(ev_id: String) -> void:
	var ev := Story.evidence(ev_id)
	var q := input.text.strip_edges()
	input.text = ""
	if q == "":
		q = "What can you tell me about this?" if Settings.lang == "en" else "درباره‌ی این چه می‌دانی؟"
	var shown := "*" + ("You place the %s on the table." % Story.t(ev.name) if Settings.lang == "en" else "%s را روی میز می‌گذاری." % Story.t(ev.name)) + "* " + q
	_ask(shown, Game.detect_topics(sid, q), ev_id)


func _ask(text: String, topic_ids: Array, ev_id: String) -> void:
	if Game.candles <= 0:
		m().toast(Story.ui("no_candles"), UI.PRESS)
		return
	busy = true
	Game.spend_candle()
	Game.apply_tone(sid, tone)
	for tp in topic_ids:
		Game.mark_asked(sid, tp)
	_add_player_line(text)
	Game.add_history(sid, "player", text)

	# Decide what this question unlocks, and the scripted answer to fall back on.
	var confess := Game.check_false_confession(sid, tone)
	var ev := Game.evaluate(sid, topic_ids, ev_id) if not confess else {"secret": {}, "locked": {}}
	var secret: Dictionary = ev.secret
	var locked: Dictionary = ev.locked
	var scripted := {}
	var director := ""
	if confess:
		scripted = {"text": Story.t(Game.FALSE_CONFESSION.line), "mood": "fear"}
		director = Game.FALSE_CONFESSION.reveal
	elif not secret.is_empty():
		scripted = {"text": Story.t(secret.line), "mood": secret.line.get("mood", "grief")}
		director = "In this reply you finally reveal, clearly and in your own voice and manner: " + str(secret.reveal)
	else:
		scripted = _scripted_answer(topic_ids, ev_id)
		if not locked.is_empty():
			director = "Something in this question touches a secret you keep. This time you hold it back — show visible hesitation, start to say something and stop. Do not reveal it."
	_pending = {"secret": secret, "locked": locked, "scripted": scripted, "confess": confess}
	_refresh()
	_scroll_end()

	if Settings.mode == "ai":
		_stream_raw = ""
		_stream_label = _entry(Story.t(sus.name), Color(sus.color).lightened(0.2))
		_stream_label.text = "[color=#5a554d][i]" + Story.t(sus.name) + " " + Story.ui("thinking") + "[/i][/color]"
		_scroll_end()
		AI.chat(AI.build_messages(sid, text, tone, ev_id, director, topic_ids), 320, 0.7)
	else:
		var r := _add_suspect_line(scripted.text)
		r.visible_ratio = 0.0
		var secs := r.get_total_character_count() * 0.012 / maxf(Settings.text_speed, 0.01)
		var tw := create_tween()
		tw.tween_property(r, "visible_ratio", 1.0, secs if Settings.text_speed > 0 else 0.0)
		tw.tween_callback(func(): _complete(scripted.text, scripted.mood))
		_scroll_end()


## The authored answer for a topic or a piece of evidence.
func _scripted_answer(topic_ids: Array, ev_id: String) -> Dictionary:
	if ev_id != "":
		var reac: Dictionary = sus.evidence.get(ev_id, sus.evidence.default)
		return {"text": Story.t(reac), "mood": reac.get("mood", "calm")}
	for tp in topic_ids:
		if sus.topics.has(tp):
			return {"text": Story.t(sus.topics[tp]), "mood": sus.topics[tp].get("mood", "calm")}
	# A free question with no topic match, answered offline: a guarded non-answer.
	var dodge := {"en": "*A long silence.* ...Ask me something I can answer, detective.", "fa": "*سکوتی طولانی.* ...چیزی بپرس که بتوانم جواب بدهم، کارآگاه."}
	return {"text": Story.t(dodge), "mood": "calm"}


func _on_token(_piece: String) -> void:
	if not busy or _stream_label == null:
		return
	_stream_raw = AI._full
	var vis := AI.visible_stream(_stream_raw)
	_stream_label.text = UI.dialogue_bbcode(vis) + " [color=#c9a45a]▍[/color]"
	_scroll_end()


func _on_finished(raw: String) -> void:
	if not busy:
		return
	var parsed := AI.parse_reply(raw)
	if parsed.text == "":
		_on_failed("empty")
		return
	_stream_label.text = UI.dialogue_bbcode(parsed.text)
	_complete(parsed.text, parsed.mood)


func _on_failed(err: String) -> void:
	if not busy:
		return
	push_warning("AI failed: " + err)
	m().toast(Story.ui("ai_failed"), UI.PRESS, 6.0)
	var s: Dictionary = _pending.scripted
	if _stream_label:
		_stream_label.text = UI.dialogue_bbcode(s.text)
	_complete(s.text, s.mood)


func _complete(text: String, mood: String) -> void:
	Game.add_history(sid, "suspect", text)
	Game.apply_mood(sid, mood)
	_set_mood(mood)
	if _pending.get("confess", false):
		_add_testimony_card(Game.testimony_text(Game.testimonies[-1]), true)
	var secret: Dictionary = _pending.get("secret", {})
	if not secret.is_empty():
		Game.reveal(sid, secret)
		_add_testimony_card(Story.t(secret.note))
		m().toast("✎  " + Story.ui("new_testimony"), UI.GOLD)
		if secret.has("unlocks"):
			var ev := Story.evidence(secret.unlocks)
			m().toast("🗝  " + Story.ui("new_evidence") + ": " + Story.t(ev.name), UI.GENTLE, 5.0)
	elif not _pending.get("locked", {}).is_empty():
		_add_note(Story.t(_pending.locked.locked), UI.GOLD.darkened(0.15))
	busy = false
	_stream_label = null
	_pending = {}
	Game.save_game()
	_build_chips()
	_refresh()
	_scroll_end()
	if Game.candles <= 0:
		m().toast(Story.ui("no_candles"), UI.PRESS, 5.0)
	elif Settings.mode == "ai":
		input.grab_focus()


func _leave() -> void:
	if busy:
		AI.cancel()
		busy = false
	m().goto("hub")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if not m().open_overlays().is_empty():
		m().close_top_overlay()
	else:
		_leave()
