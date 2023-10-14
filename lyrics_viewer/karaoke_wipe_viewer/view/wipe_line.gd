extends Control

class_name WipeViewerLine

const WipeUnit := preload("res://lyrics_viewer/karaoke_wipe_viewer/view/wipe_unit.tscn")


class Parameter:
	var font : Font

	var font_size : int
	var font_ruby_size : int

	var font_outline_size : int
	var font_ruby_outline_size : int

	enum HorizontalAlignment {LEFT = 0,CENTER = 1,RIGHT = 2}
	var horizontal_alignment : Parameter.HorizontalAlignment
	
	var left_padding : float
	var right_padding : float

	var line_height : float
	var ruby_distance : float
	var no_ruby_space : float

	enum RubyAlignment {CENTER,SPACE121,SPACE010}
	var alignment_ruby  : RubyAlignment

	enum ParentAlignment {NOTHING,CENTER,SPACE121,SPACE010}
	var alignment_parent  : ParentAlignment



var parameter : Parameter = null


var splitter : Callable = func(text : String) :
	return text.split("") \
			if not text.is_empty() else PackedStringArray([""]) #split bug patch

var line_break : LineBreak.ILineBreak = LineBreak.JapaneaseLineBreak.new()


class MeasuredUnit:
	var x : float = 0
	var rx : float = 0
	var width : float = -1
	var cluster : String
	var start : float = -1
	var end : float = -1

	func _init(c):
		cluster = c
		
	static func interpolate(units : Array[MeasuredUnit],start_ : float,end_ : float):
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

class MeasuredRubyBlock:
	var base : Array[MeasuredUnit]
	var ruby : Array[MeasuredUnit]
	var start : float
	var end : float
	var base_width : float = 0
	var ruby_width : float = 0
	func _init(b : Array[MeasuredUnit],r : Array[MeasuredUnit],s : float,e : float):
		base = b
		ruby = r
		start = s
		end = e
	
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
		var r_width := 0.0
		var r_time := -1.0
		for i in range(ruby.size()-1,-1,-1):
			if ruby[i].end >= 0:
				r_time = ruby[i].end
				break
			r_width += ruby[i].width
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
		return [start,get_width()]

class Unbreakable:
	var base : Array[MeasuredUnit]
	var ruby : Array[MeasuredUnit]
	var width : float = 0
	func _init(b : Array[MeasuredUnit],r : Array[MeasuredUnit],w : float):
		base = b
		ruby = r
		width = w
	func get_left_ruby_buffer() -> float:
		return width if ruby.is_empty() else ruby[0].rx - base[0].rx
	func get_right_ruby_buffer() -> float:
		return width - (0.0 if ruby.is_empty() else (ruby[-1].rx - base[-1].rx + ruby[-1].width))

class DisplayedRuby:
	var ruby : Array[MeasuredUnit]
	var x : float
	func _init(r : Array[MeasuredUnit],x_ : float):
		ruby = r
		x = x_


var ruby_blocks : Array[MeasuredRubyBlock] = []
var unbreakables : Array[Unbreakable] = []

var sync_mode : LyricsContainer.SyncMode

var start_time : float
var end_time : float


func set_lyrics(line : LyricsContainer.LyricsLine,next_line_start_time : float):
	sync_mode = line.sync_mode
	end_time = next_line_start_time
	ruby_blocks = []
	for u in line.units:
		var bases : Array[MeasuredUnit] = []
		for t in u.base:
			var clusters : PackedStringArray = splitter.call(t.text)
			var index = bases.size()
			for c in clusters:
				bases.append(MeasuredUnit.new(c))
			bases[index].start = t.start_time
			if index - 1 >= 0 and bases[index - 1].end < 0:
				bases[index - 1].end = t.start_time
		var rubys : Array[MeasuredUnit] = []
		for t in u.ruby:
			var clusters : PackedStringArray = splitter.call(t.text)
			var index = rubys.size()
			for c in clusters:
				rubys.append(MeasuredUnit.new(c))
			rubys[index].start = t.start_time
			if index - 1 >= 0 and rubys[index - 1].end < 0:
				rubys[index - 1].end = t.start_time
		ruby_blocks.append(MeasuredRubyBlock.new(bases,rubys,u.get_start_time(),u.get_end_time()))
	if ruby_blocks[-1].end >= 0:
		end_time = ruby_blocks[-1].end

	measure_lyrics()


func measure_lyrics():
	if not parameter or ruby_blocks.is_empty():
		return
	var font := parameter.font
	var font_size := parameter.font_size
	var font_ruby_size := parameter.font_ruby_size
	
	for rb in ruby_blocks:
		rb.base_width = 0
		for b in rb.base:
			b.width = font.get_string_size(b.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
			rb.base_width += b.width
		rb.ruby_width = 0
		for r in rb.ruby:
			r.width = font.get_string_size(r.cluster,HORIZONTAL_ALIGNMENT_LEFT,-1,font_ruby_size).x
			rb.ruby_width += r.width

	if sync_mode == LyricsContainer.SyncMode.KARAOKE:
		for i in ruby_blocks.size() - 1:
			var rb := ruby_blocks[i]
			var next : float = ruby_blocks[i+1].start
			if rb.end < 0:
				if next >= 0:
					rb.end = next
			elif next < 0:
				ruby_blocks[i+1].start = rb.end
		if not ruby_blocks.is_empty() and ruby_blocks[-1].end < 0:
			ruby_blocks[-1].end = end_time
		
		for i in range(1,ruby_blocks.size()):
			if ruby_blocks[i].start < 0:
				var prev_pos : Array = ruby_blocks[i-1].get_last_time()
				var j : int = i
				var width : float = 0.0
				var next_pos : Array = ruby_blocks[j].get_first_time()
				while next_pos.is_empty():
					width += ruby_blocks[j].get_width()
					j += 1
					next_pos = ruby_blocks[j].get_first_time()
				next_pos[1] += width
				var i_time : float = (prev_pos[0] * next_pos[1] + next_pos[0] * prev_pos[1]) / (prev_pos[1] + next_pos[1])
				ruby_blocks[i].start = i_time
				ruby_blocks[i-1].end = i_time
		for rb in ruby_blocks:
			MeasuredUnit.interpolate(rb.base,rb.start,rb.end)
			if not rb.ruby.is_empty():
				MeasuredUnit.interpolate(rb.ruby,rb.start,rb.end)

	unbreakables = []
	var ub_base : Array[MeasuredUnit] = []
	var ub_ruby : Array[MeasuredUnit] = []
	var ubx : float = 0
	for rb in ruby_blocks:
		if not ub_base.is_empty() and not line_break._is_link(ub_base.back().cluster,rb.base[0].cluster):
			var width : float = 0
			for b in ub_base:
				width += b.width
			unbreakables.append(Unbreakable.new(ub_base,ub_ruby,width))
			ub_base = []
			ub_ruby = []
			ubx = 0
		
		if rb.ruby.is_empty():
			rb.base[0].rx = ubx
			ub_base.append(rb.base[0])
			ubx += rb.base[0].width
			for i in range(1,rb.base.size()):
				if line_break._is_link(rb.base[i-1].cluster,rb.base[i].cluster):
					rb.base[i].rx = ubx
					ub_base.append(rb.base[i])
					ubx += rb.base[i].width
				else:
					var width : float = 0
					for b in ub_base:
						width += b.width
					unbreakables.append(Unbreakable.new(ub_base,ub_ruby,width))
					ub_base = []
					ub_ruby = []
					rb.base[i].rx = 0
					ub_base.append(rb.base[i])
					ubx = rb.base[i].width
		else:
			var rx : float = ubx + (rb.base_width - rb.ruby_width) / 2
			for b in rb.base:
				b.rx = ubx
				ub_base.append(b)
				ubx += b.width
			for r in rb.ruby:
				r.rx = rx
				ub_ruby.append(r)
				rx += r.width

	if not ub_base.is_empty():
		var width : float = 0
		for b in ub_base:
			width += b.width
		unbreakables.append(Unbreakable.new(ub_base,ub_ruby,width))

	layout_lyrics()


func ruby_align():
	pass



func layout_lyrics():
	if not parameter or unbreakables.is_empty():
		return
	var font := parameter.font
	var font_size := parameter.font_size
	var font_ruby_size := parameter.font_ruby_size
	var ruby_distance := parameter.ruby_distance
	var line_height := parameter.line_height
	var no_ruby_space := parameter.no_ruby_space
	var left_padding := parameter.left_padding
	var right_padding := parameter.right_padding
	var font_outline_size := parameter.font_outline_size
	var font_ruby_outline_size := parameter.font_ruby_outline_size
	
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var y : float = 0
	var width : float = 0 
	
	var ruby_height : float = font.get_height(font_ruby_size) + ruby_distance
	var base_height : float = font.get_height(font_size) + line_height
	
	if unbreakables.is_empty():
		custom_minimum_size = Vector2(0,base_height + no_ruby_space)
		return

	var displayed_base : Array[MeasuredUnit] = []
	var displayed_rubys : Array[DisplayedRuby] = []

	var ruby_padding : float = unbreakables[0].get_right_ruby_buffer()
	
	for b in unbreakables[0].base:
		b.x = b.rx
		displayed_base.append(b)
	if not unbreakables[0].ruby.is_empty():
		var ruby : Array[MeasuredUnit] = []
		for r in unbreakables[0].ruby:
			r.x = r.rx
			ruby.append(r)
		displayed_rubys.append(DisplayedRuby.new(ruby,0 + unbreakables[0].ruby[0].x))
	var x := unbreakables[0].width

	for i in range(1,unbreakables.size()):
		var unbreakable := unbreakables[i]
		if unbreakable.ruby.is_empty():
			ruby_padding += unbreakable.get_left_ruby_buffer()
		else:
			var padding = ruby_padding + unbreakable.get_left_ruby_buffer()
			if padding < 0:
				x -= padding
			ruby_padding = unbreakable.get_right_ruby_buffer()
		var right := left_padding + x + unbreakable.width
		if right > size.x - right_padding or (not unbreakable.ruby.is_empty()
				and right - unbreakable.get_right_ruby_buffer() > size.x):
			var base_y_distance := no_ruby_space if displayed_rubys.is_empty() else ruby_height
			var base := WipeUnit.instantiate()
			add_child(base)
			base.initialize(displayed_base,font,font_size,font_outline_size)
			var align_x := calculate_aligned_x(base)
			base.position = Vector2(align_x - font_outline_size,y + base_y_distance - font_outline_size)
			for r in displayed_rubys:
				var ruby := WipeUnit.instantiate()
				add_child(ruby)
				ruby.initialize(r.ruby,font,font_ruby_size,font_ruby_outline_size)
				ruby.position = Vector2(align_x + r.x - font_ruby_outline_size,y - font_ruby_outline_size)
			
			width = max(width,x)
			x = 0
			y += base_height + base_y_distance
			displayed_base = []
			displayed_rubys = []

		for b in unbreakable.base:
			b.x = x + b.rx
			displayed_base.append(b)

		if not unbreakable.ruby.is_empty():
			var ruby : Array[MeasuredUnit] = []
			for r in unbreakable.ruby:
				r.x = r.rx
				ruby.append(r)
			displayed_rubys.append(DisplayedRuby.new(ruby,x + unbreakable.ruby[0].x))
		
		x += unbreakable.width
	width = max(width,x)
	
	if not displayed_base.is_empty():
		var base_y_distance := no_ruby_space if displayed_rubys.is_empty() else ruby_height
		var height = base_height + base_y_distance
		var base := WipeUnit.instantiate()
		add_child(base)
		base.initialize(displayed_base,font,font_size,font_outline_size)
		var align_x := calculate_aligned_x(base)
		base.position = Vector2(align_x - font_outline_size,y + base_y_distance - font_outline_size)
		for r in displayed_rubys:
			var ruby := WipeUnit.instantiate()
			add_child(ruby)
			ruby.initialize(r.ruby,font,font_ruby_size,font_ruby_outline_size)
			ruby.position = Vector2(align_x + r.x - font_ruby_outline_size,y - font_ruby_outline_size)
		y += height

	size.y = y
	custom_minimum_size.y = y


func calculate_aligned_x(base : Control) -> float:
	match parameter.horizontal_alignment:
		Parameter.HorizontalAlignment.LEFT:
			return parameter.left_padding - parameter.font_outline_size * 2
		Parameter.HorizontalAlignment.CENTER:
			return (size.x - base.size.x) / 2
		Parameter.HorizontalAlignment.RIGHT:
			return size.x - base.size.x - parameter.font_outline_size * 2 - parameter.right_padding
	assert(false)
	return 0


func set_time(_time : float):
	for c in get_children():
		c.set_time(_time)
		

#	var last_time := time
#	time = time_
#
#
#	var target_time_y_offset = get_target_y_offset()
#	if target_time_y_offset == time_y_offset and time == last_time:
#		return
#
#	var distance = abs(target_time_y_offset - time_y_offset)
#	if distance > scroll_limit:
#		var move : float = 0.0
#		for i in limits.size() / 2.0:
#			if distance <= limits[i*2]:
#				move = limits[i*2+1]
#				break
#		if move == 0:
#			move = distance
#		time_y_offset += sign(target_time_y_offset - time_y_offset) * move
#	else:
#		time_y_offset = target_time_y_offset
#	queue_redraw()

	pass





# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
