class_name Vignette
extends Control
## Dark edges and faint film grain over the art, drawn with a tiny shader.

const SHADER := """
shader_type canvas_item;
uniform float strength = 0.85;
uniform float grain = 0.045;
float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.25, 0.85, length(uv * vec2(1.15, 1.0)));
	float n = rand(UV * 900.0 + vec2(TIME * 13.0, TIME * 7.0)) - 0.5;
	COLOR = vec4(vec3(n * 0.5 + 0.5) * 0.0, v * strength + n * grain);
}
"""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	material = mat


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
