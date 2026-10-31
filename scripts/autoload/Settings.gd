extends Node
## Player preferences, persisted to user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

var lang := "fa"                 # "fa" or "en"
var mode := "ai"                 # "ai" = free questions to a language model, "classic" = scripted topics
var ai_base_url := "http://127.0.0.1:11434/v1"
var ai_key := ""
var ai_model := "gemma3n:latest"
var music_volume := 0.7
var text_speed := 1.0            # multiplier for typewriter effects; 0 = instant
var fullscreen := false
var first_run := true


func _ready() -> void:
	load_settings()
	apply_window()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	lang = cfg.get_value("general", "lang", lang)
	mode = cfg.get_value("general", "mode", mode)
	ai_base_url = cfg.get_value("ai", "base_url", ai_base_url)
	ai_key = cfg.get_value("ai", "key", ai_key)
	ai_model = cfg.get_value("ai", "model", ai_model)
	music_volume = cfg.get_value("audio", "music", music_volume)
	text_speed = cfg.get_value("general", "text_speed", text_speed)
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	first_run = cfg.get_value("general", "first_run", first_run)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "lang", lang)
	cfg.set_value("general", "mode", mode)
	cfg.set_value("general", "text_speed", text_speed)
	cfg.set_value("general", "first_run", first_run)
	cfg.set_value("ai", "base_url", ai_base_url)
	cfg.set_value("ai", "key", ai_key)
	cfg.set_value("ai", "model", ai_model)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(PATH)
	apply_window()
	changed.emit()


func apply_window() -> void:
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)


func is_rtl() -> bool:
	return lang == "fa"
