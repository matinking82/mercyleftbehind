class_name UI
extends RefCounted
## Shared look: palette, fonts, theme and small widget builders. Screens are built in code with these.

const BG := Color("0a0a0c")
const PANEL := Color(0.07, 0.07, 0.08, 0.92)
const PANEL_SOFT := Color(0.06, 0.06, 0.07, 0.72)
const INK := Color("e8e2d6")
const DIM := Color("8f897e")
const FAINT := Color("4a4640")
const PAPER := Color("d9cfbb")
const PAPER_INK := Color("2a221a")
const RED := Color("a3262c")
const RED_DIM := Color("5e1a1d")
const GOLD := Color("c9a45a")
const GENTLE := Color("9fc4a0")
const PRESS := Color("d08a6a")
const COLD := Color("7d97a8")

static var _fonts := {}
static var _theme: Theme


static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var vazir: FontFile = load("res://assets/fonts/Vazirmatn.ttf")
	var f: Font
	match kind:
		"title":
			# Cinzel for Latin capitals; Persian falls through to Rooznameh, then Vazirmatn.
			var c: FontFile = load("res://assets/fonts/Cinzel.ttf")
			var fv := FontVariation.new()
			fv.base_font = c
			fv.variation_opentype = {"wght": 600}
			fv.fallbacks = [load("res://assets/fonts/Rooznameh.ttf"), vazir]
			f = fv
		"serif":
			var s: FontFile = load("res://assets/fonts/IMFellEnglish-Regular.ttf")
			s.fallbacks = [vazir]
			f = s
		"serif_italic":
			var si: FontFile = load("res://assets/fonts/IMFellEnglish-Italic.ttf")
			si.fallbacks = [vazir]
			f = si
		"type":
			var t: FontFile = load("res://assets/fonts/SpecialElite-Regular.ttf")
			t.fallbacks = [vazir]
			f = t
		"bold":
			var fb := FontVariation.new()
			fb.base_font = vazir
			fb.variation_opentype = {"wght": 700}
			f = fb
		_:
			f = vazir
	_fonts[kind] = f
	return f


## Body text font: Persian reads best in Vazirmatn; English dialogue gets the old-print serif.
static func body_font() -> Font:
	return font("body") if Settings.lang == "fa" else font("serif")


static func flat(color: Color, radius := 6, border := Color.TRANSPARENT, bw := 0, pad := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.6
	sb.content_margin_bottom = pad * 0.6
	sb.anti_aliasing = true
	return sb


static func theme() -> Theme:
	if _theme:
		return _theme
	var th := Theme.new()
	th.default_font = font("body")
	th.default_font_size = 20
	th.set_color("font_color", "Label", INK)
	# Buttons: dark slabs with a thin border that warms to red on hover.
	th.set_stylebox("normal", "Button", flat(Color(0.09, 0.09, 0.1, 0.9), 4, Color(1, 1, 1, 0.12), 1, 16))
	th.set_stylebox("hover", "Button", flat(Color(0.16, 0.07, 0.08, 0.95), 4, RED, 1, 16))
	th.set_stylebox("pressed", "Button", flat(Color(0.22, 0.06, 0.07, 1), 4, RED, 2, 16))
	th.set_stylebox("disabled", "Button", flat(Color(0.06, 0.06, 0.06, 0.6), 4, Color(1, 1, 1, 0.05), 1, 16))
	th.set_stylebox("focus", "Button", flat(Color.TRANSPARENT, 4, Color(GOLD, 0.6), 1, 16))
	th.set_color("font_color", "Button", INK)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", FAINT)
	th.set_color("font_focus_color", "Button", INK)
	th.set_stylebox("normal", "LineEdit", flat(Color(0.04, 0.04, 0.05, 0.95), 4, Color(1, 1, 1, 0.15), 1, 14))
	th.set_stylebox("focus", "LineEdit", flat(Color(0.05, 0.05, 0.06, 1), 4, Color(GOLD, 0.7), 1, 14))
	th.set_stylebox("read_only", "LineEdit", flat(Color(0.04, 0.04, 0.05, 0.6), 4, Color(1, 1, 1, 0.05), 1, 14))
	th.set_color("font_color", "LineEdit", INK)
	th.set_color("font_placeholder_color", "LineEdit", Color(DIM, 0.7))
	th.set_color("caret_color", "LineEdit", GOLD)
	th.set_stylebox("normal", "TextEdit", flat(Color(0.04, 0.04, 0.05, 0.95), 4, Color(1, 1, 1, 0.15), 1, 14))
	th.set_stylebox("focus", "TextEdit", flat(Color(0.05, 0.05, 0.06, 1), 4, Color(GOLD, 0.7), 1, 14))
	th.set_color("font_color", "TextEdit", INK)
	th.set_color("font_placeholder_color", "TextEdit", Color(DIM, 0.7))
	th.set_stylebox("panel", "Panel", flat(PANEL, 6))
	th.set_stylebox("panel", "PanelContainer", flat(PANEL, 6))
	th.set_stylebox("panel", "TooltipPanel", flat(Color(0.05, 0.05, 0.06, 0.97), 4, Color(GOLD, 0.5), 1, 10))
	th.set_color("font_color", "TooltipLabel", INK)
	th.set_font_size("font_size", "TooltipLabel", 17)
	th.set_color("default_color", "RichTextLabel", INK)
	th.set_stylebox("scroll", "VScrollBar", flat(Color(1, 1, 1, 0.03), 3, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("grabber", "VScrollBar", flat(Color(1, 1, 1, 0.18), 3, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("grabber_highlight", "VScrollBar", flat(Color(GOLD, 0.5), 3, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("grabber_pressed", "VScrollBar", flat(Color(GOLD, 0.8), 3, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("slider", "HSlider", flat(Color(1, 1, 1, 0.12), 3, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("grabber_area", "HSlider", flat(Color(RED, 0.8), 3, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("grabber_area_highlight", "HSlider", flat(RED, 3, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("normal", "OptionButton", flat(Color(0.09, 0.09, 0.1, 0.9), 4, Color(1, 1, 1, 0.12), 1, 14))
	th.set_stylebox("hover", "OptionButton", flat(Color(0.14, 0.08, 0.08, 0.95), 4, RED, 1, 14))
	th.set_stylebox("panel", "PopupMenu", flat(Color(0.07, 0.07, 0.08, 0.98), 4, Color(1, 1, 1, 0.12), 1, 8))
	th.set_color("font_color", "PopupMenu", INK)
	th.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	th.set_stylebox("hover", "PopupMenu", flat(Color(RED, 0.5), 2, Color.TRANSPARENT, 0, 6))
	th.set_color("font_color", "CheckBox", INK)
	th.set_color("font_hover_color", "CheckBox", Color.WHITE)
	th.set_stylebox("normal", "CheckBox", flat(Color.TRANSPARENT, 0, Color.TRANSPARENT, 0, 4))
	th.set_stylebox("hover", "CheckBox", flat(Color(1, 1, 1, 0.04), 4, Color.TRANSPARENT, 0, 4))
	th.set_stylebox("pressed", "CheckBox", flat(Color.TRANSPARENT, 0, Color.TRANSPARENT, 0, 4))
	th.set_stylebox("focus", "CheckBox", flat(Color.TRANSPARENT, 0, Color.TRANSPARENT, 0, 4))
	_theme = th
	return th


# ---------------------------------------------------------------- builders

static func label(text: String, size := 20, color := INK, kind := "body", wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func rich(bbcode: String, size := 20, kind := "") -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.selection_enabled = false
	var f := body_font() if kind == "" else font(kind)
	r.add_theme_font_override("normal_font", f)
	r.add_theme_font_override("italics_font", font("serif_italic") if Settings.lang == "en" else font("body"))
	r.add_theme_font_override("bold_font", font("bold"))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	if Settings.is_rtl():
		# Persian paragraphs read right to left. With an RTL direction, Godot's "left" alignment means
		# "line start", i.e. the right edge, so short lines hug the right side as Persian should.
		r.text_direction = Control.TEXT_DIRECTION_RTL
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	r.text = bbcode
	return r


static func button(text: String, cb: Callable, size := 20, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	b.pressed.connect(cb)
	return b


static func vbox(sep := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func margin(child: Control, l := 0, t := 0, r := 0, b := 0) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	if child:
		m.add_child(child)
	return m


static func panel(child: Control, style: StyleBox = null) -> PanelContainer:
	var p := PanelContainer.new()
	if style:
		p.add_theme_stylebox_override("panel", style)
	if child:
		p.add_child(child)
	return p


static func spacer(vertical := true) -> Control:
	var c := Control.new()
	if vertical:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## A meter bar (0..100) with a caption.
static func meter(caption: String, value: float, color: Color, width := 160) -> VBoxContainer:
	var v := vbox(2)
	var l := label(caption, 14, DIM)
	v.add_child(l)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 6)
	bar.add_theme_stylebox_override("background", flat(Color(1, 1, 1, 0.08), 3, Color.TRANSPARENT, 0, 0))
	bar.add_theme_stylebox_override("fill", flat(color, 3, Color.TRANSPARENT, 0, 0))
	bar.name = "Bar"
	v.add_child(bar)
	return v


# ---------------------------------------------------------------- art

static func tex(path: String) -> Texture2D:
	for ext in ["", ".jpg", ".png", ".webp"]:
		var p: String = path + ext
		if ResourceLoader.exists(p):
			return load(p)
	return null


static func scene_tex(key: String) -> Texture2D:
	return tex("res://assets/art/scenes/" + key)


static func evidence_tex(key: String) -> Texture2D:
	return tex("res://assets/art/evidence/" + key)


static func portrait(suspect_id: String, mood := "calm") -> Texture2D:
	var t := tex("res://assets/art/portraits/%s_%s" % [suspect_id, mood])
	if t == null:
		t = tex("res://assets/art/portraits/%s_calm" % suspect_id)
	return t


## An image that covers its rect, with a dark gradient fallback when the art is missing.
static func cover(t: Texture2D, dim := 0.0) -> Control:
	if t == null:
		var g := ColorRect.new()
		g.color = Color(0.05, 0.05, 0.06)
		return g
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.modulate = Color(1 - dim, 1 - dim, 1 - dim)
	return r


## Like cover(), but a tall image on a wide screen is shown whole, over a darkened blow-up of itself.
static func cover_fit(t: Texture2D, dim := 0.0) -> Control:
	if t == null or float(t.get_width()) / t.get_height() >= 1.3:
		return cover(t, dim)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := full_rect(cover(t, 0.82))
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(back)
	var front := TextureRect.new()
	front.texture = t
	front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	front.modulate = Color(1 - dim, 1 - dim, 1 - dim)
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(full_rect(front))
	return holder


## Convert the suspect's "*action*" convention into styled bbcode. Nothing is removed:
## square brackets in the text are escaped so they show exactly as written.
static func dialogue_bbcode(text: String) -> String:
	var safe := text.replace("[", "\u0001").replace("]", "[rb]").replace("\u0001", "[lb]")
	var re := RegEx.create_from_string("\\*([^*]+)\\*")
	return re.sub(safe, "[i][color=#8f897e]$1[/color][/i]", true)


## Text fields typed in Persian must run right to left (URLs and keys stay left to right).
static func rtl_input(c: Control) -> void:
	if not Settings.is_rtl():
		return
	if c is LineEdit:
		(c as LineEdit).text_direction = Control.TEXT_DIRECTION_RTL
		(c as LineEdit).alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif c is TextEdit:
		(c as TextEdit).text_direction = Control.TEXT_DIRECTION_RTL
	# Godot moves the caret in reading order, so in RTL ← would step right. Swap the arrows while focused.
	c.focus_entered.connect(mirror_text_keys.bind(true))
	c.focus_exited.connect(mirror_text_keys.bind(false))
	c.tree_exiting.connect(mirror_text_keys.bind(false))


const _MIRRORED_KEYS := [["ui_text_caret_left", "ui_text_caret_right"], ["ui_text_caret_word_left", "ui_text_caret_word_right"]]
static var _keys_mirrored := false


static func mirror_text_keys(on: bool) -> void:
	if on == _keys_mirrored:
		return
	_keys_mirrored = on
	for pair in _MIRRORED_KEYS:
		var a := InputMap.action_get_events(pair[0])
		var b := InputMap.action_get_events(pair[1])
		InputMap.action_erase_events(pair[0])
		InputMap.action_erase_events(pair[1])
		for e in b:
			InputMap.action_add_event(pair[0], e)
		for e in a:
			InputMap.action_add_event(pair[1], e)
