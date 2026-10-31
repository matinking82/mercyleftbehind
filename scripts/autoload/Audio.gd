extends Node
## Music with crossfades between the main theme and each suspect's theme.

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _current := ""
var _tween: Tween


func _ready() -> void:
	_a = AudioStreamPlayer.new()
	_b = AudioStreamPlayer.new()
	for p in [_a, _b]:
		p.bus = "Master"
		p.volume_db = -80.0
		add_child(p)
	Settings.changed.connect(_apply_volume)


func _target_db() -> float:
	return linear_to_db(maxf(Settings.music_volume, 0.0001))


func _apply_volume() -> void:
	if _a.playing:
		_a.volume_db = _target_db()


func play(track: String, fade := 1.6) -> void:
	if track == _current:
		return
	_current = track
	var path := "res://assets/music/%s.mp3" % track
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStreamMP3 = load(path)
	stream.loop = true
	# Swap players: _b fades out what was playing, _a fades in the new track.
	var old := _a
	_a = _b
	_b = old
	_a.stream = stream
	_a.volume_db = -40.0
	_a.play()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_a, "volume_db", _target_db(), fade)
	_tween.tween_property(_b, "volume_db", -60.0, fade)
	_tween.chain().tween_callback(_b.stop)
