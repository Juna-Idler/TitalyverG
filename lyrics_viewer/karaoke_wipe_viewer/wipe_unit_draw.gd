@tool
extends Control

var font : Font
var font_size : int

var outline_size : int


var data : Array[WipeViewerLine.MeasuredUnit]
var strings : PackedStringArray
var x_pos : PackedFloat32Array

func initialize(strings_ :PackedStringArray,x_pos_ : PackedFloat32Array,font_,font_size_,outline_size_):
	strings = strings_
	x_pos = x_pos_
	font = font_
	font_size = font_size_
	outline_size = outline_size_


func _draw():
	if outline_size > 0:
		for i in strings.size():
			draw_string_outline(font,Vector2(x_pos[i] + outline_size,font.get_ascent(font_size) + outline_size),strings[i],
					HORIZONTAL_ALIGNMENT_CENTER,-1,font_size,outline_size,Color(0.0,1.0,0.0))

	for i in strings.size():
		draw_string(font,Vector2(x_pos[i] + outline_size,font.get_ascent(font_size) + outline_size),strings[i],
				HORIZONTAL_ALIGNMENT_CENTER,-1,font_size,Color(1.0,0.0,0.0))


