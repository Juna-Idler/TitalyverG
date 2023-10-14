extends Control

class_name KaraokeWipeView


var parameter := WipeViewerLine.Parameter.new()

var fade_in_time : float = 0.5
var fade_out_time : float = 0.5

var scroll_center : bool = true
var scrolling : bool = false

var user_offset : float = 0.0

const WipeLine := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/wipe_line.tscn")
var lyrics : LyricsContainer


@onready var control = $Control

var lines : Array[WipeViewerLine]

var layout_height : float


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_font(font_ : Font):
	parameter.font = font_
	for l in lines:
		l.measure_lyrics()

func set_lyrics(lyrics_ : LyricsContainer) -> bool:
	for c in control.get_children():
		control.remove_child(c)
		c.queue_free()
	lines.clear()
	lyrics = lyrics_
	var y := 0.0
	for i in range(lyrics.lines.size() - 1):
		var wl : WipeViewerLine = WipeLine.instantiate()
		wl.size = Vector2(size.x,0)
		wl.position = Vector2(0,y)
		control.add_child(wl)
		lines.append(wl)
		wl.parameter = parameter
		wl.set_lyrics(lyrics.lines[i],lyrics.lines[i+1].get_start_time())
		y += wl.size.y
	var wl : WipeViewerLine = WipeLine.instantiate()
	wl.size = Vector2(size.x,0)
	wl.position = Vector2(0,y)
	control.add_child(wl)
	lines.append(wl)
	wl.parameter = parameter
	wl.set_lyrics(lyrics.lines[-1],(99*60+59) + 0.99)
	layout_height = y + wl.size.y
	control.size.y = layout_height
	control.custom_minimum_size.y = control.size.y
	return true


func set_time(time : float):
	var y := _calculate_time_y_offset(time) + user_offset
	var top_y := y - size.y / 2
	var bottom_y := y + size.y / 2
	for l in lines:
		l.set_time(time)


func _calculate_time_y_offset(c_time : float) -> float:
	var active_top : float = 0
	var active_bottom : float = 0
	var y := 0.0
	if scrolling:
		for i in lines.size():
			var line := lines[i]
			if c_time <= line.end_time:
				if c_time < line.start_time:
					active_top = y
				else:
					var duration : float = line.end_time - line.start_time
					var rate := (c_time - line.start_time) / duration if duration > 0.0 else 0.0
					active_top = y + line.size.y * rate
				break
			y += line.size.y
		y = layout_height
		for i in range(lines.size() - 1,0,-1):
			var line := lines[i]
			y -= line.size.y
			if c_time >= line.start_time:
				var duration : float = line.end_time - line.start_time
				var rate := (c_time - line.start_time) / duration if duration > 0.0 else 1.0
				active_bottom = y + line.size.y * rate
				break
	else:
		for i in lines.size():
			var line := lines[i]
			if c_time <= line.end_time:
				var duration : float = min(line.end_time - line.start_time,fade_in_time)
				if c_time > line.end_time - duration:
					var rate := (c_time - (line.end_time - duration)) / duration if duration > 0.0 else 0.0
					active_top = y + line.size.y * rate
				else:
					active_top = y
				break
			y += line.size.y
		y = layout_height
		for i in range(lines.size() - 1,0,-1):
			var line := lines[i]
			y -= line.size.y
			var prev := lines[i-1]
			var duration : float = min(prev.end_time - prev.start_time,fade_in_time)
			if c_time >= line.start_time - duration:
				if c_time < line.start_time:
					var rate := (c_time - (line.start_time - duration)) / duration  if duration > 0.0 else 1.0
					active_bottom = y + line.size.y * rate
				else:
					active_bottom = y + line.size.y
				break
	return -(active_top + active_bottom) / 2



func _on_resized():
	if control:
		var y := 0.0
		for c in control.get_children():
			c.custom_minimum_size = Vector2()
			c.size.x = size.x
			c.layout_lyrics()
			c.position.y = y
			y += c.size.y
		layout_height = y
		control.size.y = layout_height
		control.custom_minimum_size.y = control.size.y

