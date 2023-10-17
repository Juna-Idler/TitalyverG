extends TextureRect


const shader_material := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/wipe_shader_material.tres")

@onready var sub_viewport = $SubViewport
@onready var control = $SubViewport/Control


var timetable : PackedFloat64Array
var x_table : PackedFloat64Array

var invalid := true


func initialize(block : Array[WipeViewerLine.MeasuredUnit],
		font : Font,font_size : int,outline_size : int):
	var x_start := block[0].x
	var strings : PackedStringArray = []
	var x_pos : PackedFloat32Array = []
	for b in block:
		strings.append(b.cluster)
		x_pos.append(b.x - x_start)
	control.initialize(strings,x_pos,font,font_size,outline_size)
	for b in block:
		timetable.append(b.start)
		timetable.append(b.end)
		x_table.append(b.x - x_start + control.outline_offset)
		x_table.append(b.x + b.width - x_start + control.outline_offset)
	x_table[0] = 0
	x_table[-1] += control.outline_offset
	size = Vector2(block[-1].x - x_start + block[-1].width + control.outline_offset * 2,
			font.get_height(font_size) + control.outline_offset * 2)
	sub_viewport.size = size
#	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	invalid = true

func get_outline_offset() -> int:
	return control.outline_offset

func activate():
	if invalid:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		invalid = false
	


func set_time(time : float):
	activate()
	if time < timetable[0]:
		(material as ShaderMaterial).set_shader_parameter("junction",0.0)
	elif time > timetable[-1]:
		(material as ShaderMaterial).set_shader_parameter("junction",1.0)
	else:
		for i in range(1,timetable.size()):
			if time <= timetable[i]:
				var rate := (time - timetable[i-1]) / (timetable[i] - timetable[i-1])
				var junction = ((x_table[i] - x_table[i-1]) * rate + x_table[i-1]) / x_table[-1]
				(material as ShaderMaterial).set_shader_parameter("junction",junction)
				break

func set_fade_in(rate : float):
	activate()
	rate = clamp(rate,0.0,1.0)
	(material as ShaderMaterial).set_shader_parameter("junction",-1.0 + rate)

func set_fade_out(rate : float):
	activate()
	rate = clamp(rate,0.0,1.0)
	(material as ShaderMaterial).set_shader_parameter("junction",1.0 + rate)

func set_sleep():
	activate()
	(material as ShaderMaterial).set_shader_parameter("junction",-1.0)
	

func _ready():
	texture = sub_viewport.get_texture()
	material = shader_material.duplicate()


