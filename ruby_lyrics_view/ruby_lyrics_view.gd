@tool
extends Control

class_name RubyLyricsView


@export_group("Font")

@export var font : Font:
	set(v):
		font = v
		build()

@export var font_size : int :
	set(v):
		font_size = v
		build()
@export var font_ruby_size : int :
	set(v):
		font_ruby_size = v
		build()
		
@export var font_outline_width : int :
	set(v):
		font_outline_width = v
		queue_redraw()
@export var font_ruby_outline_width : int :
	set(v):
		font_ruby_outline_width = v
		queue_redraw()

@export var font_sleep_color : Color = Color.WHITE :
	set(v):
		font_sleep_color = v
		queue_redraw()
@export var font_sleep_outline_color : Color = Color.BLACK :
	set(v):
		font_sleep_outline_color = v
		queue_redraw()
@export var font_active_color : Color = Color.WHITE :
	set(v):
		font_active_color = v
		queue_redraw()
@export var font_active_outline_color : Color = Color.RED :
	set(v):
		font_active_outline_color = v
		queue_redraw()
@export var font_standby_color : Color = Color.WHITE :
	set(v):
		font_standby_color = v
		queue_redraw()
@export var font_standby_outline_color : Color = Color.BLUE :
	set(v):
		font_standby_outline_color = v
		queue_redraw()

@export var font_unsync_color : Color = Color.WHITE :
	set(v):
		font_unsync_color = v
		if lyrics and lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
			queue_redraw()
@export var font_unsync_outline_color : Color = Color.BLACK :
	set(v):
		font_unsync_outline_color = v
		if lyrics and lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
			queue_redraw()

@export var font_unsync_outline_enable : bool = false:
	set(v):
		font_unsync_outline_enable = v
		if lyrics and lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
			queue_redraw()


@export_group("Adjust")

enum RubyAlignment {CENTER,SPACE121,SPACE010}
@export var alignment_ruby  : RubyAlignment :
	set(v):
		alignment_ruby = v
		build()

enum ParentAlignment {NOTHING,CENTER,SPACE121,SPACE010}
@export var alignment_parent  : ParentAlignment :
	set(v):
		alignment_parent = v
		build()

@export var left_padding : int :
	set(v):
		left_padding = v
		layout()
@export var right_padding : int :
	set(v):
		right_padding = v
		layout()

@export var line_height : int :
	set(v):
		line_height = v
		layout()
@export var ruby_distance : int :
	set(v):
		ruby_distance = v
		layout()
@export var no_ruby_space : int :
	set(v):
		no_ruby_space = v
		layout()


@export_group("Display")

enum HorizontalAlignment {LEFT,CENTER,RIGHT}
@export var horizontal_alignment : HorizontalAlignment :
	set(v):
		horizontal_alignment = v
		queue_redraw()


@export var active_back_color : Color :
	set(v):
		active_back_color = v
		queue_redraw()
@export var active_back_texture : Texture

@export_group("Scroll")


@export var fade_in_time : float = 0.5
@export var fade_out_time : float = 0.5

@export var scroll_center : bool = true
@export var scrolling : bool = false

@export var unsync_auto_scroll : bool = true
@export var song_duration : float = 0

var scroll_limit : float = 2
var limits : PackedFloat32Array = [32,2,64,4,128,8,256,16,512,32,1024,64,2048,128,4096,256]

@export var user_y_offset : int :
	set(v):
		user_y_offset = v
		queue_redraw()
		
var time : float = 0

func set_time_and_target_y(time_ : float):
	if time == time_:
		return
	time = time_
	if not lyrics:
		return

	var target_time_y_offset : float
	if lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
		if unsync_auto_scroll and song_duration > 0 and layout_height > size.y:
			target_time_y_offset = -(layout_height) * (time) / song_duration 
			target_time_y_offset = min(target_time_y_offset + size.y / 2,0)
			target_time_y_offset = max(target_time_y_offset,-(layout_height - size.y))
			target_time_y_offset = (layout_height - size.y) * target_time_y_offset / (layout_height - size.y)
			if target_time_y_offset == time_y_offset:
				return
		else:
			if time_y_offset == 0:
				return
			target_time_y_offset = 0
	else:
		target_time_y_offset = calculate_time_y_offset(time)
		if scroll_center:
			target_time_y_offset +=  size.y/2
		else:
			if layout_height > size.y:
				target_time_y_offset = min(target_time_y_offset + size.y / 2,0)
				target_time_y_offset = max(target_time_y_offset,-(layout_height - size.y))
				
				target_time_y_offset = (layout_height - size.y) * target_time_y_offset / (layout_height - size.y)
			else:
				target_time_y_offset = 0

	var distance = abs(target_time_y_offset - time_y_offset)
	if distance > scroll_limit:
		var move : float = 0.0
		for i in limits.size() / 2:
			if distance <= limits[i*2]:
				move = limits[i*2+1]
				break
		if move == 0:
			move = distance
		time_y_offset += sign(target_time_y_offset - time_y_offset) * move
	else:
		time_y_offset = target_time_y_offset
	queue_redraw()


var splitter : Callable = func(text : String) :
	return text.split("") \
			if not text.is_empty() else PackedStringArray([""]) #split bug patch

var line_break : LineBreak.ILineBreak = LineBreak.JapaneaseLineBreak.new()
var lyrics : LyricsContainer
var built_lines : Array # of BuiltLine
var linebreak_lines : Array # of LinebreakLine
var displayed_lines : Array # of DisplayedLine

var layout_height : float
var time_y_offset : float

func _ready():
	layout()
	tree_entered.connect(layout)
	resized.connect(layout)


class Unit:
	var x : float = 0
	var y : float = 0
	var width : float
	var cluster : String
	var start : float = -1
	var end : float = -1

	func _init(w,c):
		width = w
		cluster = c
	func set_xy(x_ : float,y_ : float):
		x = x_
		y = y_
		
	static func interpolate(units : Array,start_ : float,end_ : float):
		units[0].start = start_
		units[units.size()-1].end = end_
		for i in range(1, units.size()):
			if units[i].start < 0 and units[i-1].end < 0:
				var prev_width = units[i-1].width
				var prev_time = units[i-1].start
				var next_width = units[i].width
				var next_time = end_
				for j in range(i+1, units.size()):
					if units[j].start >= 0:
						next_time = units[j].start
						break
					next_width += units[j].width
				
				var time = (prev_time * next_width + next_time * prev_width) / (prev_width + next_width)
				units[i].start = time
				units[i-1].end = time
			else:
				if units[i].start < 0:
					units[i].start = units[i-1].end
				elif units[i-1].end < 0:
					units[i-1].end = units[i].start
		
class BuiltLine:
	class Part:
		var base : Array # of Unit
		var ruby : Array # of Unit
		var start : float
		var end : float
		var base_width : float = 0
		var ruby_width : float = 0
		func _init(b,r,s,e):
			base = b
			ruby = r
			start = s
			end = e
			for u in base:
				base_width += u.width
			for u in ruby:
				ruby_width += u.width
		
		func get_width() -> float:
			return max(base_width,ruby_width)
		
		func get_first_time() -> Array:
			if start >= 0:
				return [start,0.0]
			var b_width := 0.0
			var b_time := -1.0
			for u in base:
				if u.start >= 0:
					b_time = u.start
					break
				b_width += u.width
			b_time = end if b_time < 0 else b_time
			var r_width := 0.0
			var r_time := -1.0
			if not ruby.is_empty():
				for u in ruby:
					if u.start >= 0:
						r_time = u.start
						break
					r_width += u.width
				r_time = end if r_time < 0 else r_time
			if b_time >= 0:
				if r_time >= 0:
					if b_time < r_time:
						return [b_time, get_width() * b_width / base_width]
					else:
						return [r_time, get_width() * r_width / ruby_width]
				else:
					return [b_time, get_width() * b_width / base_width]
			else:
				if r_time >= 0:
					return [r_time, get_width() * r_width / ruby_width]
			return []
		func get_last_time() -> Array:
			if end >= 0:
				return [end,0.0]
			var b_width := 0.0
			var b_time := -1.0
			for i in range(base.size()-1,-1,-1):
				if base[i].end >= 0:
					b_time = base[i].end
					break
				b_width += base[i].width
			b_time = start if b_time < 0 else b_time
			var r_width := 0.0
			var r_time := -1.0
			for i in range(ruby.size()-1,-1,-1):
				if ruby[i].end >= 0:
					r_time = ruby[i].end
					break
				r_width += ruby[i].width
			r_time = start if r_time < 0 else r_time
			if b_time >= 0:
				if r_time >= 0:
					if b_time > r_time:
						return [b_time,get_width() * b_width / base_width]
					else:
						return [r_time,get_width() * r_width / ruby_width]
				else:
					return [b_time,get_width() * b_width / base_width]
			else:
				if r_time >= 0:
					return [r_time,get_width() * r_width / ruby_width]
			return []
		
	var parts : Array # of Part
	var start : float
	var end : float
	func _init(p,s,e):
		parts = p
		start = s
		end = e
	func get_width() -> float:
		var width := 0.0
		for p in parts:
			width += max(p.get_base_wdith(),p.get_ruby_wdith())
		return width

class LinebreakLine:
	class Unbreakable:
		var base : Array # of Unit
		var ruby : Array # of Unit
		var width : float = 0
		func _init(b,r,w):
			base = b
			ruby = r
			width = w
		func get_left_ruby_buffer() -> float:
			return width if ruby.is_empty() else ruby[0].x
		func get_right_ruby_buffer() -> float:
			return width - (0.0 if ruby.is_empty() else ruby.back().x + ruby.back().width)
	
	var unbreakables : Array
	var start : float
	var end : float
	func _init(ub,s,e):
		unbreakables = ub
		start = s
		end = e

class DisplayedLine:
	var base : Array # of Unit
	var ruby : Array # of Unit
	
	var start : float
	var end : float
	
	var y : float
	var height : float
	
	func _init(b,r,s,e,y_,h):
		base = b
		ruby = r
		start = s
		end = e
		y = y_
		height = h

func build():
	if not font or not lyrics:
		return
	
	built_lines.clear()
	if lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
		for l in lyrics.lines:
			var parts : Array = []
			for u in l.units:
				var unit := u as LyricsContainer.LyricsLine.Unit
				var bases : Array = []
				for t in unit.base:
					var clusters : PackedStringArray = splitter.call(t.text)
					for c in clusters:
						var w := font.get_string_size(c,0,-1,font_size).x
						bases.append(Unit.new(w,c))
				var rubys : Array = []
				for t in unit.ruby:
					var clusters : PackedStringArray = splitter.call(t.text)
					for c in clusters:
						var w := font.get_string_size(c,0,-1,font_ruby_size).x
						rubys.append(Unit.new(w,c))
				parts.append(BuiltLine.Part.new(bases,rubys,-1,-1))
			built_lines.append(BuiltLine.new(parts,-1,-1))
	else:
		var lines : Array = [] # of LyricsContainer.LyricsLine
		lines.append(LyricsContainer.LyricsLine.create_from_time_tag(LyricsContainer.TimeTag.new(0,"")))
		for l in lyrics.lines:
			if l.sync_mode == LyricsContainer.SyncMode.UNSYNC:
				continue
			lines.append(l)
		lines.append(LyricsContainer.LyricsLine.create_from_time_tag(LyricsContainer.TimeTag.new(24*60*60,"")))
		for i in range(lines.size()-1):
			var parts : Array = [] # of BuiltLine.Part
			for u in lines[i].units:
				var unit := u as LyricsContainer.LyricsLine.Unit
				var bases : Array = [] # of Unit
				for t in unit.base:
					var tt := t as LyricsContainer.TimeTag
					var clusters : PackedStringArray = splitter.call(tt.text)
					var index = bases.size()
					for c in clusters:
						var w := font.get_string_size(c,0,-1,font_size).x
						bases.append(Unit.new(w,c))
					bases[index].start = tt.start_time
					if index - 1 >= 0 and bases[index - 1].end < 0:
						bases[index - 1].end = tt.start_time
				var rubys : Array = [] # of Unit
				for t in unit.ruby:
					var tt := t as LyricsContainer.TimeTag
					var clusters : PackedStringArray = splitter.call(tt.text)
					var index = rubys.size()
					for c in clusters:
						var w := font.get_string_size(c,0,-1,font_ruby_size).x
						rubys.append(Unit.new(w,c))
					rubys[index].start = tt.start_time
					if index - 1 >= 0 and rubys[index - 1].end < 0:
						rubys[index - 1].end = tt.start_time
				parts.append(BuiltLine.Part.new(bases,rubys,unit.get_start_time(),unit.get_end_time()))
			var line_end : float = lines[i].get_end_time()
			var next = lines[i+1].get_start_time()
			if line_end < 0 or next > line_end:
				line_end = lines[i+1].get_start_time()
			built_lines.append(BuiltLine.new(parts,lines[i].get_start_time(),line_end))
		
		if lyrics.sync_mode == LyricsContainer.SyncMode.KARAOKE:
			for l in built_lines:
				var line = l as BuiltLine
				for i in line.parts.size() - 1:
					var part := line.parts[i] as BuiltLine.Part
					var next : float = line.parts[i+1].start
					if part.end < 0:
						if next >= 0:
							part.end = next
					elif next < 0:
						line.parts[i+1].start = part.end
				if not line.parts.is_empty() and line.parts.back().end < 0:
					line.parts.back().end = line.end
				
				for i in range(1,line.parts.size()):
					if line.parts[i].start < 0:
						var prev_pos : Array = line.parts[i-1].get_last_time()
						var j : int = i
						var width : float = 0.0
						var next_pos : Array = line.parts[j].get_first_time()
						while next_pos.is_empty():
							width += line.parts[j].get_width()
							j += 1
							next_pos = line.parts[j].get_first_time()
						next_pos[1] += width
						var i_time : float = (prev_pos[0] * next_pos[1] + next_pos[0] * prev_pos[1]) / (prev_pos[1] + next_pos[1])
						line.parts[i].start = i_time
						line.parts[i-1].end = i_time
				for p in line.parts:
					var part := p as BuiltLine.Part
					Unit.interpolate(part.base,part.start,part.end)
					if not part.ruby.is_empty():
						Unit.interpolate(part.ruby,part.start,part.end)
	layout()


func layout():
	if not font or not lyrics:
		return

	linebreak_lines.clear()
	for l in built_lines:
		var line := l as BuiltLine
		var linebreak_line : Array = []
		var unbreak_base : Array = []
		var unbreak_ruby : Array = []

		var ubx : float = 0
		for p in line.parts:
			var part := p as BuiltLine.Part
			if not unbreak_base.is_empty() and not line_break._is_link(unbreak_base.back().cluster,part.base[0].cluster):
				var width : float = 0
				for u in unbreak_base:
					width += u.width
				linebreak_line.append(LinebreakLine.Unbreakable.new(unbreak_base,unbreak_ruby,width))
				unbreak_base = []
				unbreak_ruby = []
				ubx = 0
			
			if part.ruby.is_empty():
				part.base[0].x = ubx
				unbreak_base.append(part.base[0])
				ubx += part.base[0].width
				for i in range(1,part.base.size()):
					if line_break._is_link(part.base[i-1].cluster,part.base[i].cluster):
						part.base[i].x = ubx
						unbreak_base.append(part.base[i])
						ubx += part.base[i].width
					else:
						var width : float = 0
						for u in unbreak_base:
							width += u.width
						linebreak_line.append(LinebreakLine.Unbreakable.new(unbreak_base,unbreak_ruby,width))
						unbreak_base = []
						unbreak_ruby = []
						part.base[i].x = 0
						unbreak_base.append(part.base[i])
						ubx = part.base[i].width
			else:
				var rx : float = ubx + (part.base_width - part.ruby_width) / 2
				for u in part.base:
					u.x = ubx
					unbreak_base.append(u)
					ubx += u.width
				for u in part.ruby:
					u.x = rx
					unbreak_ruby.append(u)
					rx += u.width

		if not unbreak_base.is_empty():
			var width : float = 0
			for u in unbreak_base:
				width += u.width
			linebreak_line.append(LinebreakLine.Unbreakable.new(unbreak_base,unbreak_ruby,width))
		linebreak_lines.append(LinebreakLine.new(linebreak_line,line.start,line.end))


	displayed_lines.clear()
	var y : float = 0
	for l in linebreak_lines:
		var line := l as LinebreakLine
		
		var ruby_height : float = font.get_height(font_ruby_size) + ruby_distance
		var base_height : float = font.get_height(font_size) + line_height
		
		if line.unbreakables.is_empty():
			displayed_lines.append(DisplayedLine.new([],[],line.start,line.end,y,base_height + no_ruby_space))
			y += base_height + no_ruby_space
			continue
		
#		var ruby_buffer : float = buffer_left_padding

		var displayed_base : Array = []
		var displayed_ruby : Array = []

		var x : float = left_padding
		for u in line.unbreakables[0].base:
			u.x += x
			displayed_base.append(u)
		for u in line.unbreakables[0].ruby:
			u.x += x
			displayed_ruby.append(u)
		x += line.unbreakables[0].width

		for i in range(1,line.unbreakables.size()):
			var unbreakable := line.unbreakables[i] as LinebreakLine.Unbreakable
			if x + unbreakable.width > size.x - right_padding:
				var base_y_distance = float(no_ruby_space) if displayed_ruby.is_empty() else ruby_height
				var by = y + base_y_distance + font.get_ascent(font_size)
				var ry = y + font.get_ascent(font_ruby_size)
				for u in displayed_base:
					u.y = by
				for u in displayed_ruby:
					u.y = ry
				var height = base_height + base_y_distance
				displayed_lines.append(DisplayedLine.new(displayed_base,displayed_ruby,line.start,line.end,y,height))
				x = left_padding
				y += height
				displayed_base = []
				displayed_ruby = []

			for u in unbreakable.base:
				u.x += x
				displayed_base.append(u)
			for u in unbreakable.ruby:
				u.x += x
				displayed_ruby.append(u)
			x += unbreakable.width
		
		if not displayed_base.is_empty():
			var base_y_distance = float(no_ruby_space) if displayed_ruby.is_empty() else ruby_height
			var by = y + base_y_distance + font.get_ascent(font_size)
			var ry = y + font.get_ascent(font_ruby_size)
			for u in displayed_base:
				u.y = by
			for u in displayed_ruby:
				u.y = ry
			var height = base_height + base_y_distance
			displayed_lines.append(DisplayedLine.new(displayed_base,displayed_ruby,line.start,line.end,y,height))
			y += height

	layout_height = (y - line_height) if line_height < 0 else y

#	time_y_offset = calculate_time_y_offset(time)
#	if scroll_center:
#		time_y_offset +=  size.y/2
#	else:
#		time_y_offset = max(time_y_offset,-(layout_height - size.y))
#		time_y_offset = min(time_y_offset + size.y / 2,0)
#		time_y_offset = (layout_height - size.y) * time_y_offset / (layout_height - size.y)
	queue_redraw()


func calculate_time_y_offset(c_time : float) -> float:
	if lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
		return 0
	var active_top : float = 0
	var active_bottom : float = 0
	if scrolling:
		for i in displayed_lines.size():
			var line := displayed_lines[i] as DisplayedLine
			if c_time <= line.end:
				if c_time < line.start:
					active_top = line.y
				else:
					var duration : float = line.end - line.start
					var rate := (c_time - line.start) / duration if duration > 0 else 0.0
					active_top = line.y + line.height * rate
				break
		for i in range(displayed_lines.size()-1,0,-1):
			var line := displayed_lines[i] as DisplayedLine
			if c_time >= line.start:
				var duration : float = line.end - line.start
				var rate := (c_time - line.start) / duration if duration > 0 else 1.0
				active_bottom = line.y + line.height * rate
				break
	else:
		for i in displayed_lines.size():
			var line := displayed_lines[i] as DisplayedLine
			if c_time <= line.end:
				var duration : float = min(line.end - line.start,fade_in_time)
				if c_time > line.end - duration:
					var rate := (c_time - (line.end - duration)) / duration if duration > 0 else 0.0
					active_top = line.y + line.height * rate
				else:
					active_top = line.y
				break
		for i in range(displayed_lines.size()-1,0,-1):
			var line := displayed_lines[i] as DisplayedLine
			var prev := displayed_lines[i-1] as DisplayedLine
			var duration : float = min(prev.end - prev.start,fade_in_time)
			if c_time >= line.start - duration:
				if c_time < line.start:
					var rate := (c_time - (line.start - duration)) / duration  if duration > 0 else 1.0
					active_bottom = line.y + line.height * rate
				else:
					active_bottom = line.y + line.height
				break
	return -(active_top + active_bottom) / 2


func _draw():
	if not font or not lyrics:
		return
	
	var y_offset : float = user_y_offset + time_y_offset
	
	var display_start_line : int = 0
	var display_end_line : int = displayed_lines.size()
	
	for i in displayed_lines.size():
		var l := displayed_lines[i] as DisplayedLine
		if l.y + l.height + y_offset > 0:
			display_start_line = i
			break
	for i in range(displayed_lines.size()-1,-1,-1):
		var l := displayed_lines[i] as DisplayedLine
		if l.y + y_offset < size.y:
			display_end_line = i + 1
			break

	var slides := PackedFloat32Array()
	slides.resize(displayed_lines.size())
	match horizontal_alignment:
		HorizontalAlignment.LEFT:
#			slides.fill(0)
			pass
		HorizontalAlignment.RIGHT:
			for i in displayed_lines.size():
				var l := displayed_lines[i] as DisplayedLine
				if not l.base.is_empty():
					var left = l.base.front().x
					var right = l.base.back().x + l.base.back().width
					if not l.ruby.is_empty():
						left = min(left,l.ruby.front().x + left_padding)
						right = max(right,l.ruby.back().x + l.ruby.back().width - right_padding)
					var width = right - left
					slides[i]  = (size.x - right_padding) - (left_padding + width)
		HorizontalAlignment.CENTER:
			for i in displayed_lines.size():
				var l := displayed_lines[i] as DisplayedLine
				if not l.base.is_empty():
					var left = l.base.front().x
					var right = l.base.back().x + l.base.back().width
					if not l.ruby.is_empty():
						left = min(left,l.ruby.front().x)
						right = max(right,l.ruby.back().x + l.ruby.back().width)
					var width = right - left
					var slide = (size.x + left_padding - right_padding - width) / 2 - left_padding
					slides[i] = slide

	if lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
		if font_outline_width > 0 and font_unsync_outline_enable:
			for i in range(display_start_line,display_end_line):
				var l := displayed_lines[i] as DisplayedLine
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_unsync_outline_color)
		if font_outline_width > 0 and font_unsync_outline_enable:
			for i in range(display_start_line,display_end_line):
				var l := displayed_lines[i] as DisplayedLine
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_unsync_outline_color)
		for i in range(display_start_line,display_end_line):
			var l := displayed_lines[i] as DisplayedLine
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_unsync_color)
		for i in range(display_start_line,display_end_line):
			var l := displayed_lines[i] as DisplayedLine
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_unsync_color)
		return

	for i in range(display_start_line,display_end_line):
		var l := displayed_lines[i] as DisplayedLine
		if time < l.start:
			var rate := (time - (l.start - fade_in_time)) / fade_in_time
			var rect := Rect2(0,l.y + y_offset,size.x,l.height)
			draw_texture_rect(active_back_texture,rect,false,active_back_color * rate)
		elif time > l.end:
			var rate := (time - l.end) / fade_out_time
			var rect := Rect2(0,l.y + y_offset,size.x,l.height)
			draw_texture_rect(active_back_texture,rect,false,active_back_color * (1 - rate))
		else:
			var rect := Rect2(0,l.y + y_offset,size.x,l.height)
			draw_texture_rect(active_back_texture,rect,false,active_back_color)

	if font_outline_width > 0:
		for i in range(display_start_line,display_end_line):
			var l := displayed_lines[i] as DisplayedLine

			if time < l.start - fade_in_time or l.end + fade_out_time < time:
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_sleep_outline_color)
			elif time < l.start:
				var rate := (time - (l.start - fade_in_time)) / fade_in_time
				var target_color := font_standby_outline_color if lyrics.sync_mode == LyricsContainer.SyncMode.KARAOKE else font_active_outline_color
				var fade_color := target_color * rate + font_sleep_outline_color * (1 - rate)
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fade_color)
			elif time > l.end:
				var rate := (time - l.end) / fade_out_time
				var fade_color := font_sleep_outline_color * rate + font_active_outline_color * (1 - rate)
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fade_color)
			else:
				for c_ in l.base:
					var c := c_ as Unit
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					if time < c.start:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_standby_outline_color)
					elif time > c.end:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_active_outline_color)
					else:
						var rate := (time - c.start) / (c.end - c.start)
						var fadecolor := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fadecolor)

	if font_ruby_outline_width > 0:
		for i in range(display_start_line,display_end_line):
			var l := displayed_lines[i] as DisplayedLine

			if time < l.start - fade_in_time or l.end + fade_out_time < time:
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_sleep_outline_color)
			elif time < l.start:
				var rate := (time - (l.start - fade_in_time)) / fade_in_time
				var target_color := font_standby_outline_color if lyrics.sync_mode == LyricsContainer.SyncMode.KARAOKE else font_active_outline_color
				var fade_color := target_color * rate + font_sleep_outline_color * (1 - rate)
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fade_color)
			elif time > l.end:
				var rate := (time - l.end) / fade_out_time
				var fade_color := font_sleep_outline_color * rate + font_active_outline_color * (1 - rate)
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fade_color)
			else:
				for c_ in l.ruby:
					var c := c_ as Unit
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					if time < c.start:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_standby_outline_color)
					elif time > c.end:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_active_outline_color)
					else:
						var rate := (time - c.start) / (c.end - c.start)
						var fadecolor := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fadecolor)

	for i in range(display_start_line,display_end_line):
		var l := displayed_lines[i] as DisplayedLine

		if time < l.start - fade_in_time or l.end + fade_out_time < time:
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_sleep_color)
		elif time < l.start:
			var rate := (time - (l.start - fade_in_time)) / fade_in_time
			var target_color := font_standby_color if lyrics.sync_mode == LyricsContainer.SyncMode.KARAOKE else font_active_color
			var fade_color := target_color * rate + font_sleep_color * (1 - rate)
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fade_color)
		elif time > l.end:
			var rate := (time - l.end) / fade_out_time
			var fade_color := font_sleep_color * rate + font_active_color * (1 - rate)
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fade_color)
		else:
			for c_ in l.base:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if time < c.start:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_standby_color)
				elif time > c.end:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_active_color)
				else:
					var rate := (time - c.start) / (c.end - c.start)
					var fadecolor := font_active_color * rate + font_standby_color * (1 - rate)
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fadecolor)

	for i in range(display_start_line,display_end_line):
		var l := displayed_lines[i] as DisplayedLine

		if time < l.start - fade_in_time or l.end + fade_out_time < time:
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_sleep_color)
		elif time < l.start:
			var rate := (time - (l.start - fade_in_time)) / fade_in_time
			var target_color := font_standby_color if lyrics.sync_mode == LyricsContainer.SyncMode.KARAOKE else font_active_color
			var fade_color := target_color * rate + font_sleep_color * (1 - rate)
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fade_color)
		elif time > l.end:
			var rate := (time - l.end) / fade_out_time
			var fade_color := font_sleep_color * rate + font_active_color * (1 - rate)
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fade_color)
		else:
			for c_ in l.ruby:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if time < c.start:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_standby_color)
				elif time > c.end:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_active_color)
				else:
					var rate := (time - c.start) / (c.end - c.start)
					var fadecolor := font_active_color * rate + font_standby_color * (1 - rate)
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fadecolor)

#
#	for i in range(display_start_line,display_end_line):
#		var l := displayed_lines[i] as DisplayedLine
#
#		if time < l.start - fade_in_time or l.end + fade_out_time < time:
#			for c in l.base:
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if font_outline_width > 0:
#					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_sleep_outline_color)
#				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_sleep_color)
#			for c in l.ruby:
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if font_ruby_outline_width > 0:
#					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_sleep_outline_color)
#				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_sleep_color)
#		elif time < l.start:
#			var rate := (time - (l.start - fade_in_time)) / fade_in_time
#			var fade_color := font_standby_color * rate + font_sleep_color * (1 - rate)
#			var fade_outline_color := font_standby_outline_color * rate + font_sleep_outline_color * (1 - rate)
#			var rect := Rect2(0,l.y + y_offset,size.x,l.height)
##			draw_rect(rect,active_back_color * rate)
#			draw_texture_rect(active_back_texture,rect,false,active_back_color * rate)
#			for c in l.base:
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if font_outline_width > 0:
#					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fade_outline_color)
#				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fade_color)
#			for c in l.ruby:
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if font_ruby_outline_width > 0:
#					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fade_outline_color)
#				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fade_color)
#		elif time > l.end:
#			var rate := (time - l.end) / fade_out_time
#			var fade_color := font_sleep_color * rate + font_active_color * (1 - rate)
#			var fade_outline_color := font_sleep_outline_color * rate + font_active_outline_color * (1 - rate)
#			var rect := Rect2(0,l.y + y_offset,size.x,l.height)
##			draw_rect(rect,active_back_color * (1 - rate))
#			draw_texture_rect(active_back_texture,rect,false,active_back_color * (1 - rate))
#			for c in l.base:
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if font_outline_width > 0:
#					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fade_outline_color)
#				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fade_color)
#			for c in l.ruby:
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if font_ruby_outline_width > 0:
#					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fade_outline_color)
#				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fade_color)
#		else:
#			var rect := Rect2(0,l.y + y_offset,size.x,l.height)
##			draw_rect(rect,active_back_color)
#			draw_texture_rect(active_back_texture,rect,false,active_back_color)
#
#			for c_ in l.base:
#				var c := c_ as Unit
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if time < c.start:
#					if font_outline_width > 0:
#						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_standby_outline_color)
#					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_standby_color)
#				elif time > c.end:
#					if font_outline_width > 0:
#						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_active_outline_color)
#					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_active_color)
#				else:
#					var rate := (time - c.start) / (c.end - c.start)
#					var fade_color := font_active_color * rate + font_standby_color * (1 - rate)
#					var fade_outline_color := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
#					if font_outline_width > 0:
#						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fade_outline_color)
#					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fade_color)
#
#			for c_ in l.ruby:
#				var c := c_ as Unit
#				var pos = Vector2(c.x + slides[i],c.y + y_offset)
#				if time < c.start:
#					if font_ruby_outline_width > 0:
#						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_standby_outline_color)
#					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_standby_color)
#				elif time > c.end:
#					if font_ruby_outline_width > 0:
#						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_active_outline_color)
#					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_active_color)
#				else:
#					var rate := (time - c.start) / (c.end - c.start)
#					var fade_color := font_active_color * rate + font_standby_color * (1 - rate)
#					var fade_outline_color := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
#					if font_ruby_outline_width > 0:
#						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fade_outline_color)
#					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fade_color)

