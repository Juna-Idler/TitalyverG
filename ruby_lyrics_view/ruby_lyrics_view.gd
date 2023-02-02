@tool
extends Control

class_name RubyLyricsView


@export var font_font : Font:
	set(v):
		font_font = v
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


enum RubyAlignment {CENTER,SPACE121,SPACE010}
@export var ruby_alignment_ruby  : RubyAlignment :
	set(v):
		ruby_alignment_ruby = v
		build()

enum ParentAlignment {NOTHING,CENTER,SPACE121,SPACE010}
@export var ruby_alignment_parent  : ParentAlignment :
	set(v):
		ruby_alignment_parent = v
		build()

@export var buffer_left_padding : int :
	set(v):
		buffer_left_padding = v
		layout()
@export var buffer_right_padding : int :
	set(v):
		buffer_right_padding = v
		layout()

@export var adjust_line_height : int :
	set(v):
		adjust_line_height = v
		layout()
@export var adjust_ruby_distance : int :
	set(v):
		adjust_ruby_distance = v
		layout()
@export var adjust_no_ruby_space : int :
	set(v):
		adjust_no_ruby_space = v
		layout()
	
	
enum HorizontalAlignment {LEFT,CENTER,RIGHT}
@export var display_horizontal_alignment : HorizontalAlignment :
	set(v):
		display_horizontal_alignment = v
		queue_redraw()

@export var display_top_margin : int :
	set(v):
		display_top_margin = v
		queue_redraw()
@export var display_bottom_margin : int :
	set(v):
		display_bottom_margin = v
		queue_redraw()


@export var display_time : float = 0 :
	set(v):
		display_time = v
		queue_redraw()

@export var display_fade_in_time : float = 0.5
@export var display_fade_out_time : float = 1.0

func set_display_range(min_,max_):
	display_range_min = min_
	display_range_max = max_

var display_range_min : float = 0
var display_range_max : float = 1.79769e308


var splitter : Callable = func(text : String) :
	return text.split("") \
			if not text.is_empty() else PackedStringArray([""]) #split bug patch

var line_break : LineBreak.ILineBreak = LineBreak.JapaneaseLineBreak.new()
var lyrics : LyricsContainer
var built_lines : Array # of BuiltLine
var linebreak_lines : Array # of LinebreakLine
var displayed_lines : Array # of DisplayedLine

var layout_height : float



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
	var font := font_font
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
					var clusters := splitter.call(t.text)
					for c in clusters:
						var w := font.get_string_size(c,0,-1,font_size).x
						bases.append(Unit.new(w,c))
				var rubys : Array = []
				for t in unit.ruby:
					var clusters := splitter.call(t.text)
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
		for i in range(1,lines.size()-1):
			var parts : Array = [] # of BuiltLine.Part
			for u in lines[i].units:
				var unit := u as LyricsContainer.LyricsLine.Unit
				var bases : Array = [] # of Unit
				for t in unit.base:
					var tt := t as LyricsContainer.TimeTag
					var clusters := splitter.call(tt.text)
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
					var clusters := splitter.call(tt.text)
					var index = rubys.size()
					for c in clusters:
						var w := font.get_string_size(c,0,-1,font_ruby_size).x
						rubys.append(Unit.new(w,c))
					rubys[index].start = tt.start_time
					if index - 1 >= 0 and rubys[index - 1].end < 0:
						rubys[index - 1].end = tt.start_time
				var part_base := bases.filter(func(u:Unit):return not u.cluster.is_empty())
				var part_ruby := rubys.filter(func(u:Unit):return not u.cluster.is_empty())
				if not part_base.is_empty():
					parts.append(BuiltLine.Part.new(part_base,part_ruby,unit.get_start_time(),unit.get_end_time()))
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
						var time = (prev_pos[0] * next_pos[1] + next_pos[0] * prev_pos[1]) / (prev_pos[1] + next_pos[1])
						line.parts[i].start = time
						line.parts[i-1].end = time
				for p in line.parts:
					var part := p as BuiltLine.Part
					Unit.interpolate(part.base,part.start,part.end)
					if not part.ruby.is_empty():
						Unit.interpolate(part.ruby,part.start,part.end)
	layout()


func layout():
	var font := font_font
	if not font:
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
		
		var ruby_height : float = font.get_height(font_ruby_size) + adjust_ruby_distance
		var base_height : float = font.get_height(font_size) + adjust_line_height
		
		if line.unbreakables.is_empty():
			y += base_height + adjust_no_ruby_space
			continue
		
#		var ruby_buffer : float = buffer_left_padding

		var displayed_base : Array = []
		var displayed_ruby : Array = []

		var x : float = buffer_left_padding
		for u in line.unbreakables[0].base:
			u.x += x
			displayed_base.append(u)
		for u in line.unbreakables[0].ruby:
			u.x += x
			displayed_ruby.append(u)
		x += line.unbreakables[0].width

		for i in range(1,line.unbreakables.size()):
			var unbreakable := line.unbreakables[i] as LinebreakLine.Unbreakable
			if x + unbreakable.width > size.x - buffer_right_padding:
				var base_y_distance = float(adjust_no_ruby_space) if displayed_ruby.is_empty() else ruby_height
				var by = y + base_y_distance + font.get_ascent(font_size)
				var ry = y + font.get_ascent(font_ruby_size)
				for u in displayed_base:
					u.y = by
				for u in displayed_ruby:
					u.y = ry
				var height = base_height + base_y_distance
				displayed_lines.append(DisplayedLine.new(displayed_base,displayed_ruby,line.start,line.end,y,height))
				x = buffer_left_padding
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
			var base_y_distance = float(adjust_no_ruby_space) if displayed_ruby.is_empty() else ruby_height
			var by = y + base_y_distance + font.get_ascent(font_size)
			var ry = y + font.get_ascent(font_ruby_size)
			for u in displayed_base:
				u.y = by
			for u in displayed_ruby:
				u.y = ry
			var height = base_height + base_y_distance
			displayed_lines.append(DisplayedLine.new(displayed_base,displayed_ruby,line.start,line.end,y,height))
			y += height

	layout_height = (y - adjust_line_height) if adjust_line_height < 0 else y
	custom_minimum_size.y = layout_height + display_top_margin + display_bottom_margin
#	size.y = layout_height
	set_deferred("size:y",layout_height + display_top_margin + display_bottom_margin)

func _draw():
	var font := font_font
	if not font:
		return

	var y_offset : float = display_top_margin

	var slides := PackedFloat32Array()
	slides.resize(displayed_lines.size())
	match display_horizontal_alignment:
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
						left = min(left,l.ruby.front().x + buffer_left_padding)
						right = max(right,l.ruby.back().x + l.ruby.back().width - buffer_right_padding)
					var width = right - left
					slides[i]  = (size.x - buffer_right_padding) - (buffer_left_padding + width)
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
					var slide = (size.x + buffer_left_padding - buffer_right_padding - width) / 2 - buffer_left_padding
					slides[i] = slide

	if font_outline_width > 0:
		for i in displayed_lines.size():
			var l := displayed_lines[i] as DisplayedLine
			var y = l.y + y_offset
			if y + l.height < display_range_min or display_range_max < y:
				continue
				
			if display_time < l.start - display_fade_in_time or l.end + display_fade_out_time < display_time:
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_sleep_outline_color)
			elif display_time < l.start:
				var rate := (display_time - (l.start - display_fade_in_time)) / display_fade_in_time
				var fade_color := font_standby_outline_color * rate + font_sleep_outline_color * (1 - rate)
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fade_color)
			elif display_time > l.end:
				var rate := (display_time - l.end) / display_fade_out_time
				var fade_color := font_sleep_outline_color * rate + font_active_outline_color * (1 - rate)
				for c in l.base:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fade_color)
			else:
				for c_ in l.base:
					var c := c_ as Unit
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					if display_time < c.start:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_standby_outline_color)
					elif display_time > c.end:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_active_outline_color)
					else:
						var rate := (display_time - c.start) / (c.end - c.start)
						var fadecolor := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fadecolor)

	if font_ruby_outline_width > 0:
		for i in displayed_lines.size():
			var l := displayed_lines[i] as DisplayedLine
			var y = l.y + y_offset
			if y + l.height < display_range_min or display_range_max < y:
				continue
				
			if display_time < l.start - display_fade_in_time or l.end + display_fade_out_time < display_time:
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_sleep_outline_color)
			elif display_time < l.start:
				var rate := (display_time - (l.start - display_fade_in_time)) / display_fade_in_time
				var fade_color := font_standby_outline_color * rate + font_sleep_outline_color * (1 - rate)
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fade_color)
			elif display_time > l.end:
				var rate := (display_time - l.end) / display_fade_out_time
				var fade_color := font_sleep_outline_color * rate + font_active_outline_color * (1 - rate)
				for c in l.ruby:
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fade_color)
			else:
				for c_ in l.ruby:
					var c := c_ as Unit
					var pos = Vector2(c.x + slides[i],c.y + y_offset)
					if display_time < c.start:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_standby_outline_color)
					elif display_time > c.end:
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_active_outline_color)
					else:
						var rate := (display_time - c.start) / (c.end - c.start)
						var fadecolor := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
						font.draw_string_outline(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fadecolor)

	for i in displayed_lines.size():
		var l := displayed_lines[i] as DisplayedLine
		var y = l.y + y_offset
		if y + l.height < display_range_min or display_range_max < y:
			continue

			
		if display_time < l.start - display_fade_in_time or l.end + display_fade_out_time < display_time:
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_sleep_color)
		elif display_time < l.start:
			var rate := (display_time - (l.start - display_fade_in_time)) / display_fade_in_time
			var fade_color := font_standby_color * rate + font_sleep_color * (1 - rate)
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fade_color)
		elif display_time > l.end:
			var rate := display_time - l.end / display_fade_out_time
			var fade_color := font_sleep_color * rate + font_active_color * (1 - rate)
			for c in l.base:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fade_color)
		else:
			for c_ in l.base:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if display_time < c.start:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_standby_color)
				elif display_time > c.end:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_active_color)
				else:
					var rate := (display_time - c.start) / (c.end - c.start)
					var fadecolor := font_active_color * rate + font_standby_color * (1 - rate)
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fadecolor)

	for i in displayed_lines.size():
		var l := displayed_lines[i] as DisplayedLine
		var y = l.y + y_offset
		if y + l.height < display_range_min or display_range_max < y:
			continue
			
		if display_time < l.start - display_fade_in_time or l.end + display_fade_out_time < display_time:
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_sleep_color)
		elif display_time < l.start:
			var rate := (display_time - (l.start - display_fade_in_time)) / display_fade_in_time
			var fade_color := font_standby_color * rate + font_sleep_color * (1 - rate)
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fade_color)
		elif display_time > l.end:
			var rate := (display_time - l.end) / display_fade_out_time
			var fade_color := font_sleep_color * rate + font_active_color * (1 - rate)
			for c in l.ruby:
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fade_color)
		else:
			for c_ in l.ruby:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if display_time < c.start:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_standby_color)
				elif display_time > c.end:
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_active_color)
				else:
					var rate := (display_time - c.start) / (c.end - c.start)
					var fadecolor := font_active_color * rate + font_standby_color * (1 - rate)
					font.draw_string(get_canvas_item(),pos,c.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fadecolor)

			
