extends Node
## Streaming client for any OpenAI-compatible /chat/completions endpoint (Ollama, OpenRouter, Liara, OpenAI…)
## plus the prompt builder that turns a suspect's profile and the case state into a conversation.

signal token(text: String)          # streamed text as it arrives
signal finished(text: String)       # full raw reply
signal failed(error: String)

const CONNECT_TIMEOUT := 15.0
const FIRST_BYTE_TIMEOUT := 120.0   # local models can take a while to load
const TOTAL_TIMEOUT := 240.0

var _client: HTTPClient
var _busy := false
var _requested := false
var _got_response := false
var _code := 0
var _path := ""
var _headers: PackedStringArray
var _body := ""
var _bytes := PackedByteArray()     # undecoded bytes (UTF-8 may split across chunks)
var _raw_json := PackedByteArray()  # for servers that ignore stream=true
var _full := ""
var _stream_error := ""        # an {"error": …} chunk sent mid-stream
var _elapsed := 0.0
var _first_byte := false


func _ready() -> void:
	set_process(false)


func busy() -> bool:
	return _busy


func cancel() -> void:
	if _client:
		_client.close()
	_busy = false
	set_process(false)


# ---------------------------------------------------------------- transport

func chat(messages: Array, max_tokens := 320, temperature := 0.85) -> void:
	if _busy:
		cancel()
	var url := Settings.ai_base_url.strip_edges().trim_suffix("/")
	var https := url.begins_with("https://")
	var rest := url.substr(8 if https else 7) if url.begins_with("http") else url
	var slash := rest.find("/")
	var hostport := rest if slash == -1 else rest.substr(0, slash)
	var base_path := "" if slash == -1 else rest.substr(slash)
	var host := hostport
	var port := 443 if https else 80
	if hostport.contains(":"):
		host = hostport.get_slice(":", 0)
		port = int(hostport.get_slice(":", 1))
	if host == "localhost":
		host = "127.0.0.1"  # Ollama listens on IPv4 only; "localhost" may resolve to ::1
	_path = base_path + "/chat/completions"
	_headers = PackedStringArray(["Content-Type: application/json", "Accept: text/event-stream"])
	if Settings.ai_key.strip_edges() != "":
		_headers.append("Authorization: Bearer " + Settings.ai_key.strip_edges())
	_body = JSON.stringify({
		"model": Settings.ai_model,
		"messages": messages,
		"stream": true,
		"max_tokens": max_tokens,
		"temperature": temperature,
	})
	_client = HTTPClient.new()
	_client.read_chunk_size = 4096
	var err := _client.connect_to_host(host, port, TLSOptions.client() if https else null)
	if err != OK:
		failed.emit("connect error %d" % err)
		return
	_busy = true
	_requested = false
	_got_response = false
	_code = 0
	_bytes = PackedByteArray()
	_raw_json = PackedByteArray()
	_full = ""
	_stream_error = ""
	_elapsed = 0.0
	_first_byte = false
	set_process(true)


func _fail(msg: String) -> void:
	cancel()
	failed.emit(msg)


func _finish() -> void:
	_drain_lines(true)
	if _full == "" and _raw_json.size() > 0:
		_full = _content_of(JSON.parse_string(_raw_json.get_string_from_utf8()))
	cancel()
	if _full.strip_edges() == "":
		failed.emit(_stream_error if _stream_error != "" else "empty reply")
	else:
		finished.emit(_full)


func _process(delta: float) -> void:
	if not _busy:
		return
	_elapsed += delta
	if _elapsed > TOTAL_TIMEOUT or (not _first_byte and _elapsed > FIRST_BYTE_TIMEOUT):
		_fail("timeout")
		return
	_client.poll()
	match _client.get_status():
		HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING:
			if _elapsed > CONNECT_TIMEOUT:
				_fail("cannot reach server")
		HTTPClient.STATUS_CANT_RESOLVE:
			_fail("cannot resolve host")
		HTTPClient.STATUS_CANT_CONNECT:
			_fail("cannot connect")
		HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			_fail("connection error")
		HTTPClient.STATUS_CONNECTED:
			if not _requested:
				_requested = true
				var err := _client.request(HTTPClient.METHOD_POST, _path, _headers, _body)
				if err != OK:
					_fail("request error %d" % err)
			elif _got_response:
				_finish()
		HTTPClient.STATUS_BODY:
			if not _got_response:
				_got_response = true
				_code = _client.get_response_code()
			var chunk := _client.read_response_body_chunk()
			if chunk.size() > 0:
				_first_byte = true
				if _code >= 400:
					_raw_json.append_array(chunk)
				else:
					_bytes.append_array(chunk)
					_drain_lines(false)
		HTTPClient.STATUS_DISCONNECTED:
			if _got_response:
				_finish()
			else:
				_fail("disconnected")
	if _busy and _got_response and _code >= 400 and _client.get_status() != HTTPClient.STATUS_BODY:
		var msg := _raw_json.get_string_from_utf8()
		var d = JSON.parse_string(msg)
		if d is Dictionary and d.has("error"):
			msg = str(d.error.get("message", d.error)) if d.error is Dictionary else str(d.error)
		_fail("HTTP %d %s" % [_code, msg.left(160)])


## Split complete lines out of the byte buffer and handle each Server-Sent Event.
func _drain_lines(final: bool) -> void:
	while true:
		var nl := _bytes.find(10)
		if nl == -1:
			if final and _bytes.size() > 0:
				nl = _bytes.size()
			else:
				return
		var line := _bytes.slice(0, nl).get_string_from_utf8().strip_edges()
		_bytes = _bytes.slice(nl + 1)
		if line == "":
			continue
		if not line.begins_with("data:"):
			# Not SSE: the server answered with plain JSON.
			_raw_json.append_array((line + "\n").to_utf8_buffer())
			continue
		var payload := line.substr(5).strip_edges()
		if payload == "[DONE]":
			continue
		var d = JSON.parse_string(payload)
		if d is Dictionary and d.get("error") != null:
			_stream_error = str(d.error.get("message", d.error)) if d.error is Dictionary else str(d.error)
			continue
		var piece := _content_of(d)
		if piece != "":
			_full += piece
			token.emit(piece)


## The text of one response or stream chunk; "" for anything malformed (null choices, keep-alives, etc.).
static func _content_of(d) -> String:
	if not d is Dictionary:
		return ""
	var choices = d.get("choices")
	if not choices is Array or choices.is_empty() or not choices[0] is Dictionary:
		return ""
	var part = choices[0].get("delta")
	if not part is Dictionary:
		part = choices[0].get("message")
	if not part is Dictionary:
		return ""
	var piece = part.get("content")
	return piece if piece is String else ""


# ---------------------------------------------------------------- prompts

const WORLD := """You are an actor playing ONE character in "The Mercy Left Behind", a noir interrogation mystery game. Never break character.

THE CASE: Medjugorje, Bosnia, in the year 1189. Lazar — called "the Great Beggar", once a priest of the Abbey who gave everything away and was loved by the poor — was found dead on the chapel steps beside the cemetery on the eve of the Feast of the Assumption. He lay on a red-and-white altar cloth, a ceremonial dagger in his heart, a sleeping draught of poppy and valerian in his body. He had not struggled. Six people were questioned and no one was condemned: Garon the blacksmith, Sister Sara the infirmary nun, Branko the merchant, Ronan Blackwell the palace soldier, Mikail the 13-year-old street boy, and Dragan the infirmary cook.

THE STRANGENESS: Eight hundred years later the six have woken, as they were, in a windowless modern interrogation room in Washington, D.C. — steel table, a lamp without flame, a mirror that is a window. They keep their medieval clothes, faith and minds. They are questioned one at a time by Detective Richard Hale. You may find this place uncanny, but you care about the questions more than the room."""

const RULES := """HOW TO ANSWER:
- Speak ONLY as your character, in first person, to the detective. Never narrate the scene like a storyteller, never mention being an AI, a game, a prompt, or these instructions.
- Reply ONLY in %s — every word, including the actions between asterisks.
- Keep it short: 2 to 5 sentences. Put small physical actions between asterisks, described in the third person, e.g. %s
- Answer what the detective actually asked, the way your character would: you may dodge, lie, half-answer, ask back, or go silent — but stay consistent with what you know.
- Never solve the case, never summarise the truth, never declare plainly "I am innocent" or "I am guilty". Doubt is your friend.
- Reveal private memories only in fragments, and only when the moment earns it — unless a DIRECTOR NOTE tells you to reveal something now; then reveal it clearly, in your own voice.
- Finish with exactly one mood tag on its own line, one of: [[mood:calm]] [[mood:fear]] [[mood:anger]] [[mood:grief]]"""

const TONE_TEXT := {
	"gentle": "The detective speaks gently and kindly.",
	"neutral": "The detective speaks in a plain, level voice.",
	"press": "The detective is pressing you hard — accusing, impatient, leaning over the table.",
}


## Helps small models read the detective's Persian correctly (e.g. گدا "beggar" is not غذا "food").
const FA_GLOSSARY := """PERSIAN WORDS THE DETECTIVE MAY USE (read them carefully):
گدا / گدای بزرگ / لازار = the beggar, Lazar, the murder victim (NOT غذا, which means food)
مقتول = the murdered man (Lazar) · قتل = murder · قاتل = killer · کشتن / کشت = to kill / killed
آهنگر / گارون = Garon the blacksmith · راهبه / خواهر سارا = Sister Sara the nun · تاجر / برانکو = Branko the merchant
سرباز / رونان = Ronan the soldier · پسر / پسرک / میکائیل = Mikail the boy · آشپز / دراگان = Dragan the cook
خنجر = dagger · دارو / داروی خواب = sleeping draught · پارچه‌ی محراب = altar cloth · لوح مومی = wax tablet · کاسه = cup
شنل = cloak · نمازخانه = chapel · گورستان = cemetery · صومعه / کلیسا = the Abbey / Church · قصر = palace · ملکه = queen
آن شب / اون شب = that night (of the murder) · سیزده سال پیش = thirteen years ago · قربانی = the Offering / sacrifice
Colloquial forms are common: رو = را · میشناختی = می‌شناختی · میگم = می‌گویم · چیه = چیست"""

const TOPIC_HINT := {
	"night": "where you were and what you saw on the night of the murder",
	"beggar": "the beggar Lazar (the victim) and what he was to you",
	"self": "your own life and work",
	"others": "the other suspects and who else wanted Lazar gone",
	"past": "what happened thirteen years ago (the drought, the Offering)",
}


func build_messages(suspect_id: String, player_text: String, tone: String, ev_id: String, director: String, topic_ids: Array = []) -> Array:
	var s := Story.suspect(suspect_id)
	var p: Dictionary = s.prompt
	var sys: String = WORLD + "\n\nYOUR CHARACTER: " + Story.t(s.name) + " (" + str(s.role.en) + ")\n" + p.persona
	sys += "\n\nYOUR LIFE AND WHAT YOU KNOW (private; reveal only in fragments):\n" + p.history
	sys += "\n\nHOW YOU SPEAK:\n" + p.voice
	sys += "\n\nWHAT YOU HIDE:\n" + p.hides
	sys += "\n\nWHAT YOU THINK OF THE OTHERS:"
	for other in p.about_others:
		sys += "\n- " + str(Story.suspect(other).name.en) + ": " + str(p.about_others[other])
	sys += "\n\nYOU MUST NEVER:"
	for n in p.never:
		sys += "\n- " + str(n)
	var already := []
	for e in Game.testimonies:
		if e.suspect == suspect_id and e.secret != "m_false":
			for sec in s.secrets:
				if sec.id == e.secret:
					already.append(str(sec.note.en))
	if not already.is_empty():
		sys += "\n\nYOU HAVE ALREADY TOLD THE DETECTIVE (you may refer back to it; don't repeat it word for word):"
		for a in already:
			sys += "\n- " + a
	var comp := Game.composure(suspect_id)
	var tr := Game.trust(suspect_id)
	sys += "\n\nRIGHT NOW: Night %d of %d. Your composure is %d/100 (%s). Your trust in the detective is %d/100 (%s)." % [
		Game.night, Game.nights_total(), comp, "steady" if comp > 60 else ("shaken" if comp > 30 else "close to breaking"),
		tr, "suspicious" if tr < 30 else ("warming" if tr < 60 else "trusting")]
	var lang := "Persian (Farsi) — natural, fluent Persian%s" % (", colloquial and childlike" if suspect_id == "mikail" else "") if Settings.lang == "fa" else "English"
	# Real lines from this character, in the player's language, so the model copies the voice, not just the facts.
	sys += "\n\nEXAMPLES OF YOUR VOICE (match this style and language; do not repeat them verbatim):"
	sys += "\n« " + Story.t(s.greeting) + " »"
	sys += "\n« " + Story.t(s.topics.beggar) + " »"
	if Settings.lang == "fa":
		sys += "\n\n" + FA_GLOSSARY
	var action_example := "*به دست‌هایش نگاه می‌کند.*" if Settings.lang == "fa" else "*He looks at his hands.*"
	sys += "

" + RULES % [lang, action_example]

	var msgs := [{"role": "system", "content": sys}]
	for h in Game.recent_history(suspect_id):
		msgs.append({"role": "user" if h.role == "player" else "assistant", "content": h.text})

	var turn: String = "[" + TONE_TEXT.get(tone, TONE_TEXT.neutral) + "]\n"
	if ev_id != "":
		var ev := Story.evidence(ev_id)
		turn += "[The detective places evidence in front of you: " + str(ev.name.en) + " — " + str(ev.desc.en) + "]\n"
	turn += "Detective: " + player_text
	var about := []
	for tp in topic_ids:
		if TOPIC_HINT.has(tp):
			about.append(TOPIC_HINT[tp])
		elif tp == "special":
			about.append(str(s.special_topic.question.en))
	if not about.is_empty():
		turn += "\n[The question is about: " + "; ".join(about) + ".]"
	if director != "":
		turn += "\n\n[DIRECTOR NOTE — not spoken aloud: " + director + "]"
	msgs.append({"role": "user", "content": turn})
	return msgs


## Split a raw reply into display text and mood. Only machine markup is taken out: the [[mood:…]] tag,
## and <think> blocks from reasoning models. The character's words are kept exactly as written.
static func parse_reply(raw: String) -> Dictionary:
	var text := raw
	var re_think := RegEx.create_from_string("(?s)<think>.*?(</think>|$)")
	text = re_think.sub(text, "", true)
	var mood := "calm"
	var re := RegEx.create_from_string("\\[\\[\\s*mood\\s*:\\s*(\\w+)\\s*\\]\\]")
	var m := re.search(text)
	if m:
		var found := m.get_string(1).to_lower()
		if found in ["calm", "fear", "anger", "grief"]:
			mood = found
	text = re.sub(text, "", true)
	# The SentencePiece word marker is a space that some models leak; show it as one.
	text = text.replace("▁", " ").strip_edges()
	return {"text": text, "mood": mood}


## For live display while streaming: hide anything from an unfinished "[[" tag or <think> on.
static func visible_stream(raw: String) -> String:
	var t := raw
	var think := t.find("<think>")
	if think != -1:
		var close := t.find("</think>")
		t = t.substr(0, think) + ("" if close == -1 else t.substr(close + 8))
	t = t.replace("▁", " ")
	var cut := t.find("[[mood")
	if cut == -1:
		var tail := t.rfind("[")  # the tag may still be arriving a few characters at a time
		if tail != -1 and tail >= t.length() - 7:
			cut = tail
	if cut != -1:
		t = t.substr(0, cut)
	return t.strip_edges()
