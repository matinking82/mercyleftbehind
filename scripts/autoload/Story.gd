extends Node
## Read-only access to the case bible (data/story.json, data/suspects.json) and UI strings.

var data: Dictionary
var topics: Array
var suspects: Array
var _suspect_by_id := {}
var _evidence_by_id := {}

const UI := {
	"new_case": {"en": "New Case", "fa": "پرونده‌ی تازه"},
	"continue": {"en": "Continue", "fa": "ادامه"},
	"settings": {"en": "Settings", "fa": "تنظیمات"},
	"how_to": {"en": "How to Play", "fa": "راهنمای بازی"},
	"quit": {"en": "Quit", "fa": "خروج"},
	"back": {"en": "Back", "fa": "بازگشت"},
	"next": {"en": "Next", "fa": "بعدی"},
	"skip": {"en": "Skip", "fa": "رد کردن"},
	"begin": {"en": "Enter Room B", "fa": "ورود به اتاق B"},
	"night": {"en": "Night", "fa": "شب"},
	"of": {"en": "of", "fa": "از"},
	"candles": {"en": "Candle", "fa": "شمع"},
	"questions_left": {"en": "questions left tonight", "fa": "سؤال تا پایان امشب"},
	"case_file": {"en": "Case File", "fa": "پرونده"},
	"instinct": {"en": "Instinct", "fa": "غریزه"},
	"end_night": {"en": "End the Night", "fa": "پایان شب"},
	"accuse": {"en": "Accuse", "fa": "اتهام"},
	"accuse_locked": {"en": "You may accuse from Night 3", "fa": "از شب سوم می‌توانی اتهام بزنی"},
	"menu": {"en": "Menu", "fa": "منو"},
	"interrogate": {"en": "Interrogate", "fa": "بازجویی"},
	"composure": {"en": "Composure", "fa": "خونسردی"},
	"trust": {"en": "Trust", "fa": "اعتماد"},
	"leave_room": {"en": "Leave the room", "fa": "ترک اتاق"},
	"present": {"en": "Show Evidence", "fa": "نشان دادن مدرک"},
	"ask": {"en": "Ask", "fa": "بپرس"},
	"type_question": {"en": "Type your question… (Enter to ask)", "fa": "سؤالت را بنویس… (Enter برای پرسیدن)"},
	"tone": {"en": "Tone", "fa": "لحن"},
	"tone_gentle": {"en": "Gentle", "fa": "ملایم"},
	"tone_neutral": {"en": "Neutral", "fa": "خنثی"},
	"tone_press": {"en": "Press", "fa": "فشار"},
	"tone_gentle_tip": {"en": "Builds trust. Some suspects only open up to kindness.", "fa": "اعتماد می‌سازد. بعضی‌ها فقط با مهربانی حرف می‌زنند."},
	"tone_neutral_tip": {"en": "Plain questioning.", "fa": "بازجویی معمولی."},
	"tone_press_tip": {"en": "Breaks composure — but costs trust. Some secrets only slip out under pressure.", "fa": "خونسردی را می‌شکند — اما اعتماد را از بین می‌برد. بعضی رازها فقط زیر فشار بیرون می‌ریزند."},
	"you": {"en": "You", "fa": "تو"},
	"new_testimony": {"en": "Testimony recorded", "fa": "شهادت ثبت شد"},
	"new_evidence": {"en": "New evidence", "fa": "مدرک تازه"},
	"choose_evidence": {"en": "Choose evidence to show", "fa": "مدرکی برای نشان دادن انتخاب کن"},
	"cancel": {"en": "Cancel", "fa": "انصراف"},
	"thinking": {"en": "is thinking…", "fa": "در فکر است…"},
	"ai_failed": {"en": "The language model did not answer — using the scripted reply. (Check Settings → AI.)", "fa": "مدل زبانی پاسخ نداد — از پاسخ نوشته‌شده استفاده شد. (تنظیمات ← هوش مصنوعی را بررسی کن.)"},
	"no_candles": {"en": "The candle has burned down. End the night.", "fa": "شمع تمام شد. شب را به پایان برسان."},
	"victim": {"en": "The Victim", "fa": "مقتول"},
	"evidence": {"en": "Evidence", "fa": "مدارک"},
	"testimony": {"en": "Testimony", "fa": "شهادت‌ها"},
	"suspects": {"en": "Suspects", "fa": "مظنونان"},
	"notebook": {"en": "Notebook", "fa": "دفترچه"},
	"no_testimony": {"en": "No testimony yet. Question the suspects; show them evidence.", "fa": "هنوز شهادتی نیست. از مظنونان سؤال کن و مدارک را نشانشان بده."},
	"notes_hint": {"en": "Your own notes for this night…", "fa": "یادداشت‌های خودت برای امشب…"},
	"close": {"en": "Close", "fa": "بستن"},
	"judgement_title": {"en": "Judgement of the Night", "fa": "داوری شب"},
	"judgement_text": {"en": "Before the candle dies, write in your notebook whom you suspect most tonight. It is not final — but they will feel your eyes on them tomorrow.", "fa": "پیش از خاموشی شمع، در دفترچه‌ات بنویس امشب به چه کسی بیشتر از همه شک داری. قطعی نیست — اما فردا سنگینی نگاهت را حس خواهد کرد."},
	"no_one": {"en": "No one yet", "fa": "هنوز هیچ‌کس"},
	"seal_night": {"en": "Close the notebook", "fa": "بستن دفترچه"},
	"accusation": {"en": "The Accusation", "fa": "اتهام"},
	"acc_who": {"en": "Who opened the door?", "fa": "چه کسی در را گشود؟"},
	"acc_how": {"en": "How was it done?", "fa": "چگونه انجام شد؟"},
	"acc_why": {"en": "Why?", "fa": "چرا؟"},
	"acc_confirm": {"en": "Name them", "fa": "اعلام کن"},
	"acc_sure": {"en": "This cannot be undone. Are you certain?", "fa": "این کار برگشت‌پذیر نیست. مطمئنی؟"},
	"not_yet": {"en": "Not yet", "fa": "هنوز نه"},
	"the_end": {"en": "The End", "fa": "پایان"},
	"stats": {"en": "Evidence found: %s / %s   ·   Testimony: %s / %s   ·   Nights: %s", "fa": "مدارک یافته‌شده: %s از %s   ·   شهادت‌ها: %s از %s   ·   شب‌ها: %s"},
	"to_menu": {"en": "Return to the menu", "fa": "بازگشت به منو"},
	"language": {"en": "Language", "fa": "زبان"},
	"game_mode": {"en": "Interrogation mode", "fa": "حالت بازجویی"},
	"mode_ai": {"en": "AI — ask anything (needs a language model)", "fa": "هوش مصنوعی — هر سؤالی بپرس (نیازمند مدل زبانی)"},
	"mode_classic": {"en": "Classic — choose questions (works offline)", "fa": "کلاسیک — انتخاب سؤال (بدون اینترنت)"},
	"ai_server": {"en": "AI server (OpenAI-compatible URL)", "fa": "سرور هوش مصنوعی (آدرس سازگار با OpenAI)"},
	"ai_key": {"en": "API key (empty for local Ollama)", "fa": "کلید API (برای Ollama محلی خالی بگذار)"},
	"ai_model": {"en": "Model", "fa": "مدل"},
	"ai_test": {"en": "Test connection", "fa": "آزمایش اتصال"},
	"ai_testing": {"en": "Testing…", "fa": "در حال آزمایش…"},
	"ai_ok": {"en": "Connected. The suspects can hear you.", "fa": "متصل شد. مظنونان صدایت را می‌شنوند."},
	"ai_bad": {"en": "No answer: %s", "fa": "پاسخی نیامد: %s"},
	"find_models": {"en": "Find installed models", "fa": "یافتن مدل‌های نصب‌شده"},
	"no_models": {"en": "No local Ollama models found at that address.", "fa": "هیچ مدل Ollama محلی در این آدرس پیدا نشد."},
	"preset_ollama": {"en": "Local Ollama", "fa": "Ollama محلی"},
	"music": {"en": "Music volume", "fa": "صدای موسیقی"},
	"text_speed": {"en": "Text speed", "fa": "سرعت متن"},
	"fullscreen": {"en": "Fullscreen", "fa": "تمام‌صفحه"},
	"save": {"en": "Save", "fa": "ذخیره"},
	"unreliable": {"en": "UNRELIABLE — extracted under heavy pressure", "fa": "غیرقابل‌اعتماد — زیر فشار شدید گرفته شد"},
	"overwrite": {"en": "Start a new case? Your current progress will be lost.", "fa": "پرونده‌ی تازه شروع شود؟ پیشرفت فعلی از دست می‌رود."},
	"yes": {"en": "Yes", "fa": "بله"},
	"no": {"en": "No", "fa": "خیر"},
	"asked": {"en": "asked", "fa": "پرسیده‌شده"},
	"judged": {"en": "Suspected", "fa": "مظنون شب"},
	"credits": {"en": "Story & design: reimagined from «The Murder of the Great Beggar» 0.5.1 · Engine: Godot · Music: original game score", "fa": "داستان و طراحی: بازآفرینی «قتل گدای بزرگ» ۰.۵.۱ · موتور: گودو · موسیقی: موسیقی اصلی بازی"},
	"first_tip_ai": {"en": "Tip — type any question, or click a topic below. Choose a tone first: Gentle builds trust, Press breaks composure. Show evidence with 🗝. Every question burns the candle.", "fa": "نکته — هر سؤالی می‌خواهی بنویس یا روی یکی از موضوع‌های پایین بزن. اول لحن را انتخاب کن: «ملایم» اعتماد می‌سازد و «فشار» خونسردی را می‌شکند. با 🗝 مدرک نشان بده. هر سؤال بخشی از شمع را می‌سوزاند."},
	"first_tip_classic": {"en": "Tip — click a topic below to ask about it. Choose a tone first: Gentle builds trust, Press breaks composure. Show evidence with 🗝. Every question burns the candle.", "fa": "نکته — روی یکی از موضوع‌های پایین بزن تا درباره‌اش بپرسی. اول لحن را انتخاب کن: «ملایم» اعتماد می‌سازد و «فشار» خونسردی را می‌شکند. با 🗝 مدرک نشان بده. هر سؤال بخشی از شمع را می‌سوزاند."},
	"mode_badge_ai": {"en": "AI interrogation · %s", "fa": "بازجویی هوش مصنوعی · %s"},
	"mode_badge_classic": {"en": "Classic interrogation", "fa": "بازجویی کلاسیک"},
	"how_to_text": {
		"en": "[b]Your goal[/b]\nFind who killed Lazar, the Great Beggar — and prove how and why. You have [b]five nights[/b].\n\n[b]Each night[/b]\nYou have a candle of [b]14 questions[/b]. Pick a suspect in the corridor and enter the room. Every question or piece of evidence you show burns one.\n\n[b]Asking[/b]\nIn [i]AI mode[/i] type anything you like — the suspects answer in character. In [i]Classic mode[/i] choose from topics. The topic buttons work in both.\n\n[b]Tone[/b]\n[color=#9fc4a0]Gentle[/color] builds trust. [color=#d08a6a]Press[/color] breaks composure. Some secrets need trust, others need pressure. Watch the two bars under each portrait.\n\n[b]Evidence[/b]\nShowing the right evidence to the right person is how the case opens. New testimony and new evidence are written in your Case File automatically.\n\n[b]Instinct[/b]\nStuck? Ask your instinct in the corridor for a nudge.\n\n[b]Judgement[/b]\nAt the end of each night, write down whom you suspect. From Night 3 you may make the final accusation: [b]who[/b], [b]how[/b], and [b]why[/b]. Only the full truth closes the door.",
		"fa": "[b]هدف تو[/b]\nبفهم چه کسی لازار، گدای بزرگ، را کشت — و ثابت کن چگونه و چرا. [b]پنج شب[/b] فرصت داری.\n\n[b]هر شب[/b]\nشمعی به اندازه‌ی [b]۱۴ سؤال[/b] داری. در راهرو مظنونی را انتخاب کن و وارد اتاق شو. هر سؤال یا مدرکی که نشان می‌دهی، بخشی از شمع را می‌سوزاند.\n\n[b]پرسیدن[/b]\nدر [i]حالت هوش مصنوعی[/i] هرچه می‌خواهی بنویس — مظنونان در نقش خود پاسخ می‌دهند. در [i]حالت کلاسیک[/i] از میان موضوع‌ها انتخاب کن. دکمه‌های موضوع در هر دو حالت کار می‌کنند.\n\n[b]لحن[/b]\nلحن [color=#9fc4a0]ملایم[/color] اعتماد می‌سازد. [color=#d08a6a]فشار[/color] خونسردی را می‌شکند. بعضی رازها اعتماد می‌خواهند و بعضی فشار. به دو نوار زیر هر چهره دقت کن.\n\n[b]مدارک[/b]\nنشان دادن مدرک درست به آدم درست، قفل پرونده را باز می‌کند. شهادت‌ها و مدارک تازه خودکار در پرونده ثبت می‌شوند.\n\n[b]غریزه[/b]\nگیر کرده‌ای؟ در راهرو از غریزه‌ات کمک بگیر.\n\n[b]داوری[/b]\nپایان هر شب بنویس به چه کسی شک داری. از شب سوم می‌توانی اتهام نهایی را بزنی: [b]چه کسی[/b]، [b]چگونه[/b] و [b]چرا[/b]. فقط تمام حقیقت در را می‌بندد."
	}
}


func _ready() -> void:
	data = _load_json("res://data/story.json")
	var s := _load_json("res://data/suspects.json")
	topics = s.get("topics", [])
	suspects = s.get("suspects", [])
	for sus in suspects:
		_suspect_by_id[sus.id] = sus
	for ev in data.get("evidence", []):
		_evidence_by_id[ev.id] = ev


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing data file " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## Localise a {"en": ..., "fa": ...} dictionary (or pass through a plain string).
func t(v) -> String:
	if v is Dictionary:
		return str(v.get(Settings.lang, v.get("en", "")))
	return str(v)


func ui(key: String) -> String:
	return t(UI.get(key, key))


func suspect(id: String) -> Dictionary:
	return _suspect_by_id.get(id, {})


func evidence(id: String) -> Dictionary:
	return _evidence_by_id.get(id, {})


func all_evidence() -> Array:
	return data.get("evidence", [])


## Topic definitions for a suspect: the five shared topics plus their special one.
func topics_for(suspect_id: String) -> Array:
	var out := []
	for tp in topics:
		out.append(tp)
	var sp: Dictionary = suspect(suspect_id).get("special_topic", {})
	if not sp.is_empty():
		out.append({"id": "special", "label": sp.label, "question": sp.question, "keywords": sp.get("keywords", [])})
	return out


func total_secrets() -> int:
	var n := 0
	for s in suspects:
		n += s.secrets.size()
	return n


## Persian digits when the UI is Persian.
func num(n) -> String:
	var s := str(n)
	if Settings.lang != "fa":
		return s
	var out := ""
	for ch in s:
		var c := ch.unicode_at(0)
		out += char(0x06F0 + c - 48) if c >= 48 and c <= 57 else ch
	return out
