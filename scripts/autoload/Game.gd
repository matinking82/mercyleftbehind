extends Node
## Case state and rules: nights, the candle, composure/trust, the clue engine, judgements, endings.

signal state_changed
signal testimony_added(entry: Dictionary)
signal evidence_added(ev_id: String)

const SAVE_PATH := "user://case.json"
const HISTORY_LIMIT := 14

var night := 1
var candles := 12
var evidence_owned: Array = []          # evidence ids, in the order found
var revealed: Array = []                # secret ids
var testimonies: Array = []             # {secret, suspect, night, unreliable?}
var meters := {}                        # suspect -> {composure, trust}
var history := {}                       # suspect -> [{role: "player"/"suspect", text}]
var asked := {}                         # suspect -> [topic ids]
var judgements: Array = []              # one per night: suspect id or ""
var notes := {}                         # "1".."5" -> player text
var false_confession := false
var ended := false
var ending_id := ""
var active := false                     # a case exists (for Continue)


func _ready() -> void:
	load_game()


# ---------------------------------------------------------------- lifecycle

func new_game() -> void:
	night = 1
	candles = int(Story.data.get("candles_per_night", 14))
	evidence_owned = []
	for ev in Story.all_evidence():
		if ev.get("initial", false):
			evidence_owned.append(ev.id)
	revealed = []
	testimonies = []
	meters = {}
	history = {}
	asked = {}
	for s in Story.suspects:
		meters[s.id] = {"composure": float(s.start.composure), "trust": float(s.start.trust)}
		history[s.id] = []
		asked[s.id] = []
	judgements = []
	notes = {}
	false_confession = false
	ended = false
	ending_id = ""
	active = true
	save_game()
	state_changed.emit()


func nights_total() -> int:
	return int(Story.data.get("nights_total", 5))


func can_accuse() -> bool:
	return night >= int(Story.data.get("accuse_from_night", 3))


func is_last_night() -> bool:
	return night >= nights_total()


## Close the current night with a provisional verdict; returns false when the case must now be decided.
func end_night(suspect_id: String) -> bool:
	judgements.append(suspect_id)
	if is_last_night():
		save_game()
		return false
	night += 1
	candles = int(Story.data.get("candles_per_night", 14))
	for id in meters:
		var start := float(Story.suspect(id).start.composure)
		meters[id].composure = minf(100.0, maxf(meters[id].composure + 20.0, minf(start, meters[id].composure + 35.0)))
	if suspect_id != "" and meters.has(suspect_id):
		meters[suspect_id].composure = maxf(5.0, meters[suspect_id].composure - 15.0)
	save_game()
	state_changed.emit()
	return true


func spend_candle() -> void:
	candles = maxi(0, candles - 1)
	state_changed.emit()


# ---------------------------------------------------------------- meters

func composure(id: String) -> float:
	return meters.get(id, {}).get("composure", 50.0)


func trust(id: String) -> float:
	return meters.get(id, {}).get("trust", 50.0)


func _shift(id: String, d_comp: float, d_trust: float) -> void:
	if not meters.has(id):
		return
	meters[id].composure = clampf(meters[id].composure + d_comp, 0.0, 100.0)
	meters[id].trust = clampf(meters[id].trust + d_trust, 0.0, 100.0)


func apply_tone(id: String, tone: String) -> void:
	match tone:
		"gentle": _shift(id, 3, 7)
		"press": _shift(id, -11, -5)
		_: _shift(id, -2, 1)


func apply_mood(id: String, mood: String) -> void:
	match mood:
		"fear": _shift(id, -4, 0)
		"anger": _shift(id, -3, -2)
		"grief": _shift(id, -1, 3)
		"calm": _shift(id, 2, 0)
	state_changed.emit()


# ---------------------------------------------------------------- clue engine

## Decide what an interaction unlocks. `topic_ids` and `ev_id` describe what the player did.
## Returns {secret: Dictionary or {}, locked: Dictionary or {}} — at most one secret per turn.
func evaluate(suspect_id: String, topic_ids: Array, ev_id: String) -> Dictionary:
	var sus := Story.suspect(suspect_id)
	var locked := {}
	for sec in sus.get("secrets", []):
		if sec.id in revealed:
			continue
		var when: Dictionary = sec.get("when", {})
		var hit: bool = ev_id != "" and ev_id in when.get("evidence", [])
		if not hit:
			for tp in topic_ids:
				if tp in when.get("topic", []):
					hit = true
		if not hit:
			continue
		if _needs_met(suspect_id, sec.get("need", {})):
			return {"secret": sec, "locked": {}}
		if locked.is_empty() and sec.has("locked"):
			locked = sec
	return {"secret": {}, "locked": locked}


func _needs_met(suspect_id: String, need: Dictionary) -> bool:
	if need.has("trust_min") and trust(suspect_id) < float(need.trust_min):
		return false
	if need.has("composure_max") and composure(suspect_id) > float(need.composure_max):
		return false
	for req in need.get("secrets", []):
		if not req in revealed:
			return false
	return true


func reveal(suspect_id: String, sec: Dictionary) -> void:
	if sec.id in revealed:
		return
	revealed.append(sec.id)
	var entry := {"secret": sec.id, "suspect": suspect_id, "night": night}
	testimonies.append(entry)
	_shift(suspect_id, -8, 0)
	testimony_added.emit(entry)
	var unlock: String = sec.get("unlocks", "")
	if unlock != "" and not unlock in evidence_owned:
		evidence_owned.append(unlock)
		evidence_added.emit(unlock)
	save_game()
	state_changed.emit()


## Mikail breaks under heavy pressure and "confesses" — a trap, recorded as unreliable.
func check_false_confession(suspect_id: String, tone: String) -> bool:
	if suspect_id != "mikail" or false_confession or tone != "press":
		return false
	if composure(suspect_id) > 12.0:
		return false
	false_confession = true
	testimonies.append({"secret": "m_false", "suspect": "mikail", "night": night, "unreliable": true})
	meters.mikail.composure = 30.0
	meters.mikail.trust = 0.0
	save_game()
	return true


const FALSE_CONFESSION := {
	"line": {"en": "*He screams, hands over his ears.* I DID IT! I did it, I killed him, I KILLED HIM, are you happy? *He curls into a ball on the chair, shaking.* ...Now leave me alone. Please. Leave me alone.", "fa": "*دست‌هایش را روی گوش‌هایش می‌گذارد و جیغ می‌کشد.* من کردم! من کردم، من کشتمش، من کشتمش، راضی شدی؟ *روی صندلی مچاله می‌شود و می‌لرزد.* ...حالا ولم کن. خواهش می‌کنم. ولم کن."},
	"note": {"en": "Mikail, broken under pressure, screamed: «I did it! I killed him!» — then curled up and would not speak.", "fa": "میکائیل زیر فشار شکست و فریاد زد: «من کردم! من کشتمش!» — و بعد مچاله شد و دیگر حرف نزد."},
	"reveal": "You are completely broken by the pressure. Scream a terrified FALSE confession: 'I did it! I killed him!' — then curl up and beg to be left alone. (It is not true; you are just terrified and guilty for once wishing him dead.)"
}


func testimony_text(entry: Dictionary) -> String:
	if entry.secret == "m_false":
		return Story.t(FALSE_CONFESSION.note)
	for sec in Story.suspect(entry.suspect).get("secrets", []):
		if sec.id == entry.secret:
			return Story.t(sec.note)
	return ""


## Match free text to topics by keyword, so typed questions can unlock topic-gated secrets.
func detect_topics(suspect_id: String, text: String) -> Array:
	var low := text.to_lower()
	var out := []
	for tp in Story.topics_for(suspect_id):
		for kw in tp.get("keywords", []):
			if low.find(str(kw).to_lower()) != -1:
				out.append(tp.id)
				break
	return out


func mark_asked(suspect_id: String, topic_id: String) -> void:
	if not topic_id in asked[suspect_id]:
		asked[suspect_id].append(topic_id)


func add_history(suspect_id: String, role: String, text: String) -> void:
	history[suspect_id].append({"role": role, "text": text})
	while history[suspect_id].size() > 60:
		history[suspect_id].pop_front()


func recent_history(suspect_id: String) -> Array:
	var h: Array = history.get(suspect_id, [])
	return h.slice(maxi(0, h.size() - HISTORY_LIMIT))


# ---------------------------------------------------------------- hints

func hint() -> String:
	for h in Story.data.get("hints", []):
		if h.has("unless") and h.unless in revealed:
			continue
		if h.has("requires") and not h.requires in revealed:
			continue
		return Story.t(h)
	return ""


# ---------------------------------------------------------------- ending

func accuse(killer: String, means: String, motive: String) -> String:
	var sol: Dictionary = Story.data.solution
	if killer != sol.killer:
		ending_id = "wrong_" + killer
	elif means == sol.means and motive == sol.motive:
		ending_id = "true"
	else:
		ending_id = "half"
	ended = true
	save_game()
	return ending_id


# ---------------------------------------------------------------- persistence

func save_game() -> void:
	var d := {
		"night": night, "candles": candles, "evidence_owned": evidence_owned, "revealed": revealed,
		"testimonies": testimonies, "meters": meters, "history": history, "asked": asked,
		"judgements": judgements, "notes": notes, "false_confession": false_confession,
		"ended": ended, "ending_id": ending_id, "active": active,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func load_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	night = int(d.get("night", 1))
	candles = int(d.get("candles", 12))
	evidence_owned = d.get("evidence_owned", [])
	revealed = d.get("revealed", [])
	testimonies = d.get("testimonies", [])
	meters = d.get("meters", {})
	history = d.get("history", {})
	asked = d.get("asked", {})
	judgements = d.get("judgements", [])
	notes = d.get("notes", {})
	false_confession = d.get("false_confession", false)
	ended = d.get("ended", false)
	ending_id = d.get("ending_id", "")
	active = d.get("active", false) and not ended
	for s in Story.suspects:
		if not meters.has(s.id):
			meters[s.id] = {"composure": float(s.start.composure), "trust": float(s.start.trust)}
		if not history.has(s.id):
			history[s.id] = []
		if not asked.has(s.id):
			asked[s.id] = []
