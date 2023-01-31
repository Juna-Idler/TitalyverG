extends Control


var font_font : Font:
	set(v):
		font_font = v
		build()

var font_size : int :
	set(v):
		font_size = v
		build()
var font_ruby_size : int :
	set(v):
		font_ruby_size = v
		build()
		
var font_outline_width : int :
	set(v):
		font_outline_width = v
		queue_redraw()
var font_ruby_outline_width : int :
	set(v):
		font_ruby_outline_width = v
		queue_redraw()

var font_sleep_color : Color = Color.WHITE :
	set(v):
		font_sleep_color = v
		queue_redraw()
var font_sleep_outline_color : Color = Color.BLACK :
	set(v):
		font_sleep_outline_color = v
		queue_redraw()
var font_active_color : Color = Color.WHITE :
	set(v):
		font_active_color = v
		queue_redraw()
var font_active_outline_color : Color = Color.RED :
	set(v):
		font_active_outline_color = v
		queue_redraw()
var font_standby_color : Color = Color.WHITE :
	set(v):
		font_standby_color = v
		queue_redraw()
var font_standby_outline_color : Color = Color.BLUE :
	set(v):
		font_standby_outline_color = v
		queue_redraw()


enum RubyAlignment {CENTER,SPACE121,SPACE010}
var ruby_alignment_ruby  : RubyAlignment :
	set(v):
		ruby_alignment_ruby = v
		build()

enum ParentAlignment {NOTHING,CENTER,SPACE121,SPACE010}
var ruby_alignment_parent  : ParentAlignment :
	set(v):
		ruby_alignment_parent = v
		build()

var buffer_left_padding : int :
	set(v):
		buffer_left_padding = v
		layout()
var buffer_right_padding : int :
	set(v):
		buffer_right_padding = v
		layout()

var adjust_line_height : int :
	set(v):
		adjust_line_height = v
		layout()
var adjust_ruby_distance : int :
	set(v):
		adjust_ruby_distance = v
		layout()
var adjust_no_ruby_space : int :
	set(v):
		adjust_no_ruby_space = v
		layout()
	
var text_input : String :
	set(value):
		text_input = value
		build()
	
enum HorizontalAlignment {LEFT,CENTER,RIGHT}
var display_horizontal_alignment : HorizontalAlignment :
	set(v):
		display_horizontal_alignment = v
		queue_redraw()
enum VerticalAlignment {TOP,CENTER,BOTTOM}
var display_vertical_alignment : VerticalAlignment :
	set(v):
		display_vertical_alignment = v
		queue_redraw()
	
var display_time : float = 0 :
	set(v):
		display_time = v
		queue_redraw()


var splitter : Callable = func(text : String) :
	return text.split("") \
			if not text.is_empty() else PackedStringArray([""]) #split bug patch

var lyrics : LyricsContainer
var built_lines : Array # of BuiltLine
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
		
	static func interpolate(units : Array,start : float,end : float):
		units[0].start = start
		units[units.size()-1].end = end
		for i in range(1, units.size()):
			if units[i].start < 0 and units[i-1].end < 0:
				var prev_width = units[i-1].width
				var prev_time = units[i-1].start
				var next_width = units[i].width
				var next_time = end
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

class DisplayedLine:
	var base : Array # of Unit
	var ruby : Array # of Unit
	
	var start : float
	var end : float
	
	func _init(b,r,s,e):
		base = b
		ruby = r
		start = s
		end = e

func build():
	var font := font_font
	if not font:
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
				parts.append(BuiltLine.Part.new(
						bases.filter(func(u:Unit):return not u.cluster.is_empty()),
						rubys.filter(func(u:Unit):return not u.cluster.is_empty()),
						unit.get_start_time(),unit.get_end_time())
				)
			var line_end : float = lines[i].get_end_time()
			if line_end < 0:
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
				if line.parts.back().end < 0:
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
	pass

func _draw():
	var font := font_font
	if not font:
		return

	var y_offset : float = 0
	match display_vertical_alignment:
		VerticalAlignment.TOP:
			pass
		VerticalAlignment.CENTER:
			y_offset = (size.y - layout_height) / 2
		VerticalAlignment.BOTTOM:
			y_offset = (size.y - layout_height)

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

	for i in displayed_lines.size():
		var l := displayed_lines[i] as DisplayedLine
		if l.start < display_time and display_time < l.end:
			for c_ in l.base:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if display_time < c.start:
					font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_standby_outline_color)
				elif display_time > c.end:
					font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_active_outline_color)
				else:
					var rate := (display_time - c.start) / (c.end - c.start)
					var fadecolor := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
					font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,fadecolor)
		else:
			for c_ in l.base:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_outline_width,font_sleep_outline_color)

	for i in displayed_lines.size():
		var l := displayed_lines[i] as DisplayedLine
		if l.start < display_time and display_time < l.end:
			for c_ in l.ruby:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if display_time < c.start:
					font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_standby_outline_color)
				elif display_time > c.end:
					font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_active_outline_color)
				else:
					var rate := (display_time - c.start) / (c.end - c.start)
					var fadecolor := font_active_outline_color * rate + font_standby_outline_color * (1 - rate)
					font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,fadecolor)
		else:
			for c_ in l.ruby:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string_outline(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_ruby_outline_width,font_sleep_outline_color)

	for i in displayed_lines.size():
		var l := displayed_lines[i] as DisplayedLine
		if l.start < display_time and display_time < l.end:
			for c_ in l.base:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if display_time < c.start:
					font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_standby_color)
				elif display_time > c.end:
					font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_active_color)
				else:
					var rate := (display_time - c.start) / (c.end - c.start)
					var fadecolor := font_active_color * rate + font_standby_color * (1 - rate)
					font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fadecolor)
		else:
			for c_ in l.base:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,font_sleep_color)

	for i in displayed_lines.size():
		var l := displayed_lines[i] as DisplayedLine
		if l.start < display_time and display_time < l.end:
			for c_ in l.ruby:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				if display_time < c.start:
					font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_standby_color)
				elif display_time > c.end:
					font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_active_color)
				else:
					var rate := (display_time - c.start) / (c.end - c.start)
					var fadecolor := font_active_color * rate + font_standby_color * (1 - rate)
					font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,fadecolor)
		else:
			for c_ in l.ruby:
				var c := c_ as Unit
				var pos = Vector2(c.x + slides[i],c.y + y_offset)
				font.draw_string(get_canvas_item(),pos,c.grapheme,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size,font_sleep_color)
			
