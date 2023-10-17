extends Control

class_name KaraokeWipeView


var parameter := WipeViewerLine.Parameter.new()

var fade_in_time : float = 0.5
var fade_out_time : float = 0.5

var scroll_center : bool = true
var scrolling : bool = false

var user_offset : float = 0.0


var font_sleep_color : Color = Color.WHITE
var font_sleep_outline_color : Color = Color.BLACK
var font_active_color : Color = Color.WHITE
var font_active_outline_color : Color = Color.RED
var font_standby_color : Color = Color.WHITE
var font_standby_outline_color : Color = Color.BLUE


const WipeLine := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/wipe_line.tscn")


@onready var control = $Control

var lines : Array[WipeViewerLine]

var layout_height : float

var active_top_index : int = 0
var active_bottom_index : int = 0

var active_top_rate : float
var active_bottom_rate : float


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

func set_lyrics(lyrics : LyricsContainer) -> bool:
	for c in control.get_children():
		control.remove_child(c)
		c.queue_free()
	lines.clear()
	active_top_index = 0
	active_bottom_index = 0
	active_top_rate = 0
	active_bottom_rate = 1
	
	var lyrics_lines : Array[LyricsContainer.LyricsLine] = []
#	lyrics_lines.append(LyricsContainer.LyricsLine.create_from_time_tag(LyricsContainer.TimeTag.new(0,"")))
	for l in lyrics.lines:
		if l.sync_mode == LyricsContainer.SyncMode.UNSYNC:
			continue
		lyrics_lines.append(l)
	lyrics_lines.append(LyricsContainer.LyricsLine.create_from_time_tag(LyricsContainer.TimeTag.new((99*60+59) + 0.99,"")))
	
	var y := 0.0
	for i in range(lyrics_lines.size() - 1):
		var wl : WipeViewerLine = WipeLine.instantiate()
		wl.size = Vector2(size.x,0)
		wl.position = Vector2(0,y)
		control.add_child(wl)
		lines.append(wl)
		wl.parameter = parameter
		wl.set_lyrics(lyrics_lines[i],lyrics_lines[i+1].get_start_time())
		y += wl.size.y
	layout_height = y
	control.size.y = layout_height
	control.custom_minimum_size.y = control.size.y
	return true


func set_time(time : float):
	_calculate_active_line(time)
	
	var top := lines[active_top_index].position.y + lines[active_top_index].size.y * active_top_rate
	if scroll_center:
		var bottom := lines[active_bottom_index].position.y + lines[active_bottom_index].size.y * active_bottom_rate
		control.position.y = (size.y - (top + bottom)) / 2 + user_offset
	else:
		control.position.y = -top + user_offset
	
	var view_rect := Rect2(Vector2(0,-control.position.y),size)
	for l in lines:
		var rect := l.get_rect()
		if view_rect.intersects(rect):
			l.show()
			if time < l.start_time - fade_in_time:
				l.set_sleep()
			elif time < l.start_time:
				l.set_fade_in((time - (l.start_time - fade_in_time)) / fade_in_time)
			elif time < l.end_time:
				l.set_time(time)
			elif time < l.end_time + fade_out_time:
				l.set_fade_out((time - l.end_time) / fade_out_time)
			else:
				l.set_sleep()
		else:
			l.hide()
	


func _calculate_active_line(c_time : float):
	active_top_index = 0
	active_bottom_index = 0
	active_top_rate = 0
	active_bottom_rate = 1
	if scrolling:
		for i in lines.size():
			var line := lines[i]
			if c_time <= line.end_time:
				active_top_index = i
				if c_time >= line.start_time:
					var duration : float = line.end_time - line.start_time
					var rate := (c_time - line.start_time) / duration if duration > 0.0 else 0.0
					active_top_rate = rate
				break
		for i in range(lines.size() - 1,0,-1):
			var line := lines[i]
			if c_time >= line.start_time:
				var duration : float = line.end_time - line.start_time
				var rate := (c_time - line.start_time) / duration if duration > 0.0 else 1.0
				active_bottom_index = i
				active_bottom_rate = rate
				break
	else:
		for i in lines.size():
			var line := lines[i]
			if c_time <= line.end_time:
				var duration : float = min(line.end_time - line.start_time,fade_in_time)
				active_top_index = i
				if c_time > line.end_time - duration:
					var rate := (c_time - (line.end_time - duration)) / duration if duration > 0.0 else 0.0
					active_top_rate = rate
				break
		for i in range(lines.size() - 1,0,-1):
			var line := lines[i]
			var prev := lines[i-1]
			var duration : float = min(prev.end_time - prev.start_time,fade_in_time)
			if c_time >= line.start_time - duration:
				active_bottom_index = i
				if c_time < line.start_time:
					var rate := (c_time - (line.start_time - duration)) / duration  if duration > 0.0 else 1.0
					active_bottom_rate = rate
				break
	pass


func set_user_offset(offset : float):
	user_offset = offset
	if not lines.is_empty():
		var top := lines[active_top_index].position.y + lines[active_top_index].size.y * active_top_rate
		if scroll_center:
			var bottom := lines[active_bottom_index].position.y + lines[active_bottom_index].size.y * active_bottom_rate
			control.position.y = (size.y - (top + bottom)) / 2 + user_offset
		else:
			control.position.y = -top + user_offset

func measure_lyrics():
	if control:
		var y := 0.0
		for l in lines:
			l.measure_lyrics()
			l.position.y = y
			y += l.size.y
		layout_height = y
		control.custom_minimum_size.y = layout_height
		control.size.y = layout_height

		if not lines.is_empty():
			var top := lines[active_top_index].position.y + lines[active_top_index].size.y * active_top_rate
			if scroll_center:
				var bottom := lines[active_bottom_index].position.y + lines[active_bottom_index].size.y * active_bottom_rate
				control.position.y = (size.y - (top + bottom)) / 2 + user_offset
			else:
				control.position.y = -top + user_offset

func layout_lyrics():
	if control:
		var y := 0.0
		for l in lines:
			l.layout_lyrics()
			l.position.y = y
			y += l.size.y
		layout_height = y
		control.custom_minimum_size.y = layout_height
		control.size.y = layout_height

		if not lines.is_empty():
			var top := lines[active_top_index].position.y + lines[active_top_index].size.y * active_top_rate
			if scroll_center:
				var bottom := lines[active_bottom_index].position.y + lines[active_bottom_index].size.y * active_bottom_rate
				control.position.y = (size.y - (top + bottom)) / 2 + user_offset
			else:
				control.position.y = -top + user_offset

func _on_resized():
	if control:
		var y := 0.0
		for l in lines:
			l.custom_minimum_size = Vector2()
			l.size.x = size.x
			l.layout_lyrics()
			l.position.y = y
			y += l.size.y
		layout_height = y
		control.custom_minimum_size.y = control.size.y
		control.size.y = layout_height

		if not lines.is_empty():
			var top := lines[active_top_index].position.y + lines[active_top_index].size.y * active_top_rate
			if scroll_center:
				var bottom := lines[active_bottom_index].position.y + lines[active_bottom_index].size.y * active_bottom_rate
				control.position.y = (size.y - (top + bottom)) / 2 + user_offset
			else:
				control.position.y = -top + user_offset

