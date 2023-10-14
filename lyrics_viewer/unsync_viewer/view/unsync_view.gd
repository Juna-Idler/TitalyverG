extends Control

class_name UnsyncView


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

@export var font_color : Color = Color.WHITE :
	set(v):
		font_color = v
		if lyrics and lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
			queue_redraw()
@export var font_outline_color : Color = Color.BLACK :
	set(v):
		font_outline_color = v
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
@export var horizontal_alignment : UnsyncView.HorizontalAlignment :
	set(v):
		horizontal_alignment = v
		queue_redraw()


@export var active_back_color : Color :
	set(v):
		active_back_color = v
		queue_redraw()
@export var active_back_texture : Texture

@export_group("Scroll")


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
	var last_time := time
	time = time_
	if not lyrics:
		return

	var target_time_y_offset = get_target_y_offset()
	if target_time_y_offset == time_y_offset and time == last_time:
		return
		
	var distance = abs(target_time_y_offset - time_y_offset)
	if distance > scroll_limit:
		var move : float = 0.0
		for i in limits.size() / 2.0:
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
var built_lines : Array[BuiltLine]
var linebreak_lines : Array[LinebreakLine]
var displayed_lines : Array[DisplayedLine]

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

	func _init(w,c):
		width = w
		cluster = c
	func set_xy(x_ : float,y_ : float):
		x = x_
		y = y_
		
class BuiltLine:
	class Part:
		var base : Array[Unit] # of Unit
		var ruby : Array[Unit] # of Unit
		var base_width : float = 0
		var ruby_width : float = 0
		func _init(b,r):
			base = b
			ruby = r
			for u in base:
				base_width += u.width
			for u in ruby:
				ruby_width += u.width
		
		func get_width() -> float:
			return max(base_width,ruby_width)
		
	var parts : Array[Part] # of Part
	func _init(p):
		parts = p
	func get_width() -> float:
		var width := 0.0
		for p in parts:
			width += max(p.get_base_wdith(),p.get_ruby_wdith())
		return width

class LinebreakLine:
	class Unbreakable:
		var base : Array[Unit] # of Unit
		var ruby : Array[Unit] # of Unit
		var width : float = 0
		func _init(b,r,w):
			base = b
			ruby = r
			width = w
		func get_left_ruby_buffer() -> float:
			return width if ruby.is_empty() else ruby[0].x - base[0].x
		func get_right_ruby_buffer() -> float:
			return width - (0.0 if ruby.is_empty() else ruby.back().x - base[0].x + ruby.back().width)
	
	var unbreakables : Array[Unbreakable]
	func _init(ub):
		unbreakables = ub


class DisplayedLine:
	var base : Array[Unit] # of Unit
	var ruby : Array[Unit] # of Unit
	
	var y : float
	var height : float
	
	func _init(b,r,y_,h):
		base = b
		ruby = r
		y = y_
		height = h

func build():
	if not font or not lyrics:
		return
	
	built_lines.clear()
	if lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
		for l in lyrics.lines:
			var parts : Array[BuiltLine.Part] = []
			for u in l.units:
				var unit := u as LyricsContainer.LyricsLine.Unit
				var bases : Array[Unit] = []
				for t in unit.base:
					var clusters : PackedStringArray = splitter.call(t.text)
					for c in clusters:
						var w := font.get_string_size(c,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
						bases.append(Unit.new(w,c))
				var rubys : Array[Unit] = []
				for t in unit.ruby:
					var clusters : PackedStringArray = splitter.call(t.text)
					for c in clusters:
						var w := font.get_string_size(c,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size).x
						rubys.append(Unit.new(w,c))
				parts.append(BuiltLine.Part.new(bases,rubys))
			built_lines.append(BuiltLine.new(parts))
	else:
		var lines : Array[LyricsContainer.LyricsLine] = [] # of LyricsContainer.LyricsLine
		lines.append(LyricsContainer.LyricsLine.create_from_time_tag(LyricsContainer.TimeTag.new(0,"")))
		for l in lyrics.lines:
			if l.sync_mode == LyricsContainer.SyncMode.UNSYNC:
				continue
			lines.append(l)
		lines.append(LyricsContainer.LyricsLine.create_from_time_tag(LyricsContainer.TimeTag.new(24*60*60,"")))
		for i in range(lines.size()-1):
			var parts : Array[BuiltLine.Part] = [] # of BuiltLine.Part
			for u in lines[i].units:
				var unit := u as LyricsContainer.LyricsLine.Unit
				var bases : Array[Unit] = [] # of Unit
				for t in unit.base:
					var clusters : PackedStringArray = splitter.call(t.text)
					var index = bases.size()
					for c in clusters:
						var w := font.get_string_size(c,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
						bases.append(Unit.new(w,c))
					bases[index].start = t.start_time
					if index - 1 >= 0 and bases[index - 1].end < 0:
						bases[index - 1].end = t.start_time
				var rubys : Array[Unit] = [] # of Unit
				for t in unit.ruby:
					var clusters : PackedStringArray = splitter.call(t.text)
					var index = rubys.size()
					for c in clusters:
						var w := font.get_string_size(c,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size).x
						rubys.append(Unit.new(w,c))
					rubys[index].start = t.start_time
					if index - 1 >= 0 and rubys[index - 1].end < 0:
						rubys[index - 1].end = t.start_time
				parts.append(BuiltLine.Part.new(bases,rubys))
			built_lines.append(BuiltLine.new(parts))
		
	layout()


func layout():
	if not font or not lyrics:
		return

	linebreak_lines.clear()
	for l in built_lines:
		var line := l as BuiltLine
		var linebreak_line : Array[LinebreakLine.Unbreakable] = []
		var unbreak_base : Array[Unit] = []
		var unbreak_ruby : Array[Unit] = []

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
		linebreak_lines.append(LinebreakLine.new(linebreak_line))


	displayed_lines.clear()
	var y : float = 0
	for l in linebreak_lines:
		var line := l as LinebreakLine
		
		var ruby_height : float = font.get_height(font_ruby_size) + ruby_distance
		var base_height : float = font.get_height(font_size) + line_height
		
		if line.unbreakables.is_empty():
			displayed_lines.append(DisplayedLine.new([],[],y,base_height + no_ruby_space))
			y += base_height + no_ruby_space
			continue
		
#		var ruby_buffer : float = buffer_left_padding

		var displayed_base : Array[Unit] = []
		var displayed_ruby : Array[Unit] = []

		var ruby_padding : float = line.unbreakables[0].get_right_ruby_buffer()
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
			if unbreakable.ruby.is_empty():
				ruby_padding += unbreakable.get_left_ruby_buffer()
			else:
				var padding = ruby_padding + unbreakable.get_left_ruby_buffer()
				if padding < 0:
					x -= padding
				ruby_padding = unbreakable.get_right_ruby_buffer()
			var right := x + unbreakable.width
			if right > size.x - right_padding or (not unbreakable.ruby.is_empty()
					and right - unbreakable.get_right_ruby_buffer() > size.x):
				var base_y_distance = float(no_ruby_space) if displayed_ruby.is_empty() else ruby_height
				var by = y + base_y_distance + font.get_ascent(font_size)
				var ry = y + font.get_ascent(font_ruby_size)
				for u in displayed_base:
					u.y = by
				for u in displayed_ruby:
					u.y = ry
				var height = base_height + base_y_distance
				displayed_lines.append(DisplayedLine.new(displayed_base,displayed_ruby,y,height))
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
			displayed_lines.append(DisplayedLine.new(displayed_base,displayed_ruby,y,height))
			y += height

	layout_height = (y - line_height) if line_height < 0 else y

	queue_redraw()


func get_target_y_offset() -> float:
	var target_time_y_offset : float
	if lyrics.sync_mode == LyricsContainer.SyncMode.UNSYNC:
		if unsync_auto_scroll and song_duration > 0 and layout_height > size.y:
			target_time_y_offset = -(layout_height) * (time) / song_duration 
			target_time_y_offset = min(target_time_y_offset + size.y / 2,0)
			target_time_y_offset = max(target_time_y_offset,-(layout_height - size.y))
			target_time_y_offset = (layout_height - size.y) * target_time_y_offset / (layout_height - size.y)
			if target_time_y_offset == time_y_offset:
				return time_y_offset
		else:
			if time_y_offset == 0:
				return time_y_offset
			target_time_y_offset = 0
	return target_time_y_offset


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
		if font_outline_width > 0:
			for i in range(display_start_line,display_end_line):
				var l := displayed_lines[i] as DisplayedLine
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_outline_color)
		if font_outline_width > 0:
			for i in range(display_start_line,display_end_line):
				var l := displayed_lines[i] as DisplayedLine
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_outline_color)
		for i in range(display_start_line,display_end_line):
			var l := displayed_lines[i] as DisplayedLine
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_color)
		for i in range(display_start_line,display_end_line):
			var l := displayed_lines[i] as DisplayedLine
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_color)
		return


func _on_resized():
	if font and lyrics:
		time_y_offset = get_target_y_offset()
