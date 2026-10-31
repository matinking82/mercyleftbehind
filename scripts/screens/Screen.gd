class_name Screen
extends Control
## Base for full-screen views: access to Main, background art with vignette.

func m() -> Node:
	return get_meta("main")


func add_background(key: String, dim := 0.35, vignette := true) -> Control:
	var bg := UI.full_rect(UI.cover(UI.scene_tex(key), dim))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	if vignette:
		add_child(UI.full_rect(Vignette.new()))
	return bg


func add_slow_zoom(node: Control, amount := 0.06, seconds := 30.0) -> void:
	node.pivot_offset = Vector2(800, 450)
	var tw := create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2.ONE * (1.0 + amount), seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_SINE)
