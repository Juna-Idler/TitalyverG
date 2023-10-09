@tool

# warning-ignore-all:return_value_discarded

extends Control

func _get_property_list():
	var properties = [
		{
			name = "RubyLabel",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "Font",
			type = TYPE_NIL,
			hint_string = "font_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "font_font",
			type = TYPE_OBJECT,hint = PROPERTY_HINT_RESOURCE_TYPE,hint_string = "Font"
		},
		{
			name = "font_size",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "1,256,or_greater"
		},
		{
			name = "font_ruby_size",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "1,128,or_greater"
		},
		{
			name = "font_outline_width",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "0,32,or_greater"
		},
		{
			name = "font_ruby_outline_width",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "0,16,or_greater"
		},
		{
			name = "font_color",
			type = TYPE_COLOR,
		},
		{
			name = "font_outline_color",
			type = TYPE_COLOR,
		},
		{
			name = "RubyAlignment",
			type = TYPE_NIL,
			hint_string = "ruby_alignment_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "ruby_alignment_ruby",
			type = TYPE_INT,hint = PROPERTY_HINT_ENUM ,hint_string = ",".join(RubyAlignment.keys())
		},
		{
			name = "ruby_alignment_parent",
			type = TYPE_INT,hint = PROPERTY_HINT_ENUM ,hint_string = ",".join(ParentAlignment.keys())
		},
		{
			name = "Buffer",
			type = TYPE_NIL,
			hint_string = "buffer_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "buffer_left_margin",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "0,1024,or_greater"
		},
		{
			name = "buffer_right_margin",
			type = TYPE_INT ,hint = PROPERTY_HINT_RANGE ,hint_string = "0,1024,or_greater"
		},
		{
			name = "buffer_left_padding",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "0,1024,or_greater"
		},
		{
			name = "buffer_right_padding",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "0,1024,or_greater"
		},
		{
			name = "buffer_visible_border",
			type = TYPE_BOOL,
		},
		{
			name = "Adjust",
			type = TYPE_NIL,
			hint_string = "adjust_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "adjust_line_height",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "-256,256,or_less,or_greater"
		},
		{
			name = "adjust_ruby_distance",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "-256,256,or_less,or_greater"
		},
		{
			name = "adjust_no_ruby_space",
			type = TYPE_INT,hint = PROPERTY_HINT_RANGE ,hint_string = "-256,256,or_less,or_greater"
		},
		{
			name = "Text",
			type = TYPE_NIL,
			hint_string = "text_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "text_input",
			type = TYPE_STRING,hint = PROPERTY_HINT_MULTILINE_TEXT,
		},
		{
			name = "text_ruby_parent",
			type = TYPE_STRING,
		},
		{
			name = "text_ruby_begin",
			type = TYPE_STRING,
		},
		{
			name = "text_ruby_end",
			type = TYPE_STRING,
		},
		{
			name = "Display",
			type = TYPE_NIL,
			hint_string = "display_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "display_horizontal_alignment",
			type = TYPE_INT,hint = PROPERTY_HINT_ENUM,hint_string = ",".join(HorizontalAlignment.keys())
		},
		{
			name = "display_vertical_alignment",
			type = TYPE_INT,hint = PROPERTY_HINT_ENUM,hint_string = ",".join(VerticalAlignment.keys())
		},
		{
			name = "display_rate",
			type = TYPE_FLOAT,hint = PROPERTY_HINT_RANGE ,hint_string = "0,100"
		},
		{
			name = "display_rate_phonetic",
			type = TYPE_BOOL,
		},
		{
			name = "Output",
			type = TYPE_NIL,
			hint_string = "output_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "output_base_text",
			type = TYPE_STRING,hint = PROPERTY_HINT_MULTILINE_TEXT,
		},
		{
			name = "output_phonetic_text",
			type = TYPE_STRING,hint = PROPERTY_HINT_MULTILINE_TEXT,
		},
		{
			name = "Other",
			type = TYPE_NIL,
			hint_string = "",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "clip_rect",
			type = TYPE_BOOL,
		},
		{
			name = "auto_fit_height",
			type = TYPE_BOOL,
		},		
	]
	return properties


var font_font : Font:
	set(v):
		font_font = v
		build_words()

var font_size : int :
	set(v):
		font_size = v
		build_words()
var font_ruby_size : int :
	set(v):
		font_ruby_size = v
		build_words()
		
var font_outline_width : int :
	set(v):
		font_outline_width = v
		queue_redraw()
var font_ruby_outline_width : int :
	set(v):
		font_ruby_outline_width = v
		queue_redraw()

var font_color : Color = Color.WHITE :
	set(v):
		font_color = v
		queue_redraw()
var font_outline_color : Color = Color.BLACK :
	set(v):
		font_outline_color = v
		queue_redraw()


enum RubyAlignment {CENTER,SPACE121,SPACE010}
var ruby_alignment_ruby  : RubyAlignment :
	set(v):
		ruby_alignment_ruby = v
		build_words()

enum ParentAlignment {NOTHING,CENTER,SPACE121,SPACE010}
var ruby_alignment_parent  : ParentAlignment :
	set(v):
		ruby_alignment_parent = v
		build_words()

var buffer_left_margin : int :
	set(v):
		buffer_left_margin = v
		layout()
var buffer_right_margin : int :
	set(v):
		buffer_right_margin = v
		layout()
var buffer_left_padding : int :
	set(v):
		buffer_left_padding = v
		layout()
var buffer_right_padding : int :
	set(v):
		buffer_right_padding = v
		layout()
var buffer_visible_border : bool :
	set(v):
		buffer_visible_border = v
		queue_redraw()

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
		build_words()
var text_ruby_parent : String = "｜" :
	set(v):
		text_ruby_parent = v
		if set_regex():
			build_words()
var text_ruby_begin : String = "《" :
	set(v):
		text_ruby_begin = v
		if set_regex():
			build_words()
var text_ruby_end : String = "》" :
	set(v):
		text_ruby_end = v
		if set_regex():
			build_words()
	
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
	
var display_rate : float = 100 :
	set(v):
		display_rate = v
		if not _output_base_text.is_empty():
			queue_redraw()
var display_rate_phonetic : bool :
	set(v):
		display_rate_phonetic = v
		layout()

var _output_base_text : String
var output_base_text : String :
	set(_v):
		pass
	get:
		return _output_base_text
var _output_phonetic_text : String
var output_phonetic_text : String :
	set(_v):
		pass
	get:
		return _output_phonetic_text

var clip_rect : bool :
	set(v):
		clip_rect = v
		queue_redraw()
var auto_fit_height : bool :
	set(v):
		auto_fit_height = v
		layout()


func set_regex() -> bool:
	if not text_ruby_parent.is_empty() and not text_ruby_begin.is_empty() and not text_ruby_end.is_empty():
		return ruby_regex.compile(Ruby.RubyString.regex_escape(text_ruby_parent) +
				"(?<p>.+?)" + Ruby.RubyString.regex_escape(text_ruby_begin) +
				"(?<r>.+?)" + Ruby.RubyString.regex_escape(text_ruby_end)) == OK
	return false

var ruby_regex : RegEx = RegEx.new()
var line_break_word : Ruby.LineBreakWord = Ruby.LineBreakWord.new()
var unbreakable_words : Array[UnbreakableWordData] # of UnbreakableWordData
var lines : Array[RubyLabelLine] # of RubyLabelLine
var layout_height : float


func _ready():
	layout()
	tree_entered.connect(layout)
	resized.connect(layout)


class RubyLabelChar:
	var x : float
	var y : float
	var width : float
	var character : int
	var start : float
	var end : float
	
	func _init(x_,y_,w,c,s,e):
		x = x_
		y = y_
		width = w
		character = c
		start = s
		end = e

class RubyLabelLine:
	var base : Array[RubyLabelChar] # of RubyLabelChar
	var ruby : Array[RubyLabelChar] # of RubyLabelChar
	
	func _init(b,r):
		base = b
		ruby = r
	
	static func create(line_words : Array[UnbreakableWordData],line_words_x : PackedFloat32Array,
			font : Font,font_size : int,ruby_size : int,
			text_pos : int,y:float,has_ruby:bool,ruby_distance : float,no_ruby_space : float) -> RubyLabelLine:
		var line_chars = []
		var line_ruby_chars = []
		var ruby_height : float = font.get_height(ruby_size) + ruby_distance
		
		var by = y + (ruby_height if has_ruby else float(no_ruby_space)) + font.get_ascent(font_size)
		for i in line_words.size():
			var word := line_words[i]
			var start_pos : PackedFloat32Array = []
			for j in word.base_text_data.size():
				start_pos.append(text_pos)
				var unit = word.base_text_data[j]
				var bx = line_words_x[i] + word.base_text_x[j]
				for k in unit.char_width.size():
					var c = RubyLabelChar.new(bx,by,unit.char_width[k],
							unit.code[k],text_pos,text_pos + 1)
					bx += unit.char_width[k]
					text_pos += 1
					line_chars.append(c)
			start_pos.append(text_pos)
			for j in word.ruby_text_data.size():
				var unit = word.ruby_text_data[j] as RubyUnitWordData
				var bx = line_words_x[i] + word.ruby_text_x[j]
				var target = word.ruby_target[j]
				var d = start_pos[target+1] - start_pos[target]
				for k in unit.char_width.size():
					var s = start_pos[target] + d * k / unit.char_width.size()
					var e = start_pos[target] + d * (k+1) / unit.char_width.size()
					var c = RubyLabelChar.new(bx,y + font.get_ascent(ruby_size),unit.char_width[k],
							unit.code[k],s,e)
					bx += unit.char_width[k]
					line_ruby_chars.append(c)
		return RubyLabelLine.new(line_chars,line_ruby_chars)

	static func create_by_phonetic(line_words : Array[UnbreakableWordData],line_words_x : PackedFloat32Array,
			font : Font,font_size : int,ruby_size : int,
			text_pos : int,y:float,has_ruby:bool,ruby_distance : float,no_ruby_space : float) -> RubyLabelLine:
		var line_chars = []
		var line_ruby_chars = []
		var ruby_height : float = font.get_height(ruby_size) + ruby_distance
		
		var by = y + (ruby_height if has_ruby else float(no_ruby_space)) + font.get_ascent(font_size)
		for i in line_words.size():
			var word := line_words[i]
			if not word.has_ruby():
				for j in word.base_text_data.size():
					var unit = word.base_text_data[j] as RubyUnitWordData
					var bx = line_words_x[i] + word.base_text_x[j]
					for k in unit.char_width.size():
						var c = RubyLabelChar.new(bx,by,unit.char_width[k],
								unit.code[k],text_pos,text_pos + 1)
						bx += unit.char_width[k]
						text_pos += 1
						line_chars.append(c)
				continue
			var start_pos : PackedFloat32Array = []
			for j in word.ruby_text_data.size():
				start_pos.append(text_pos)
				var unit = word.ruby_text_data[j] as RubyUnitWordData
				var bx = line_words_x[i] + word.ruby_text_x[j]
				for k in unit.char_width.size():
					var c = RubyLabelChar.new(bx,y + font.get_ascent(ruby_size),unit.char_width[k],
							unit.code[k],text_pos,text_pos + 1)
					bx += unit.char_width[k]
					text_pos += 1
					line_ruby_chars.append(c)
			start_pos.append(text_pos)
			for j in word.base_text_data.size():
				var unit := word.base_text_data[j] as RubyUnitWordData
				var bx = line_words_x[i] + word.base_text_x[j]
				var target : int
				for k in word.ruby_target.size():
					if word.ruby_target[k] == j:
						target = k
						break
				var d = start_pos[target+1] - start_pos[target]
				for k in unit.char_width.size():
					var s = start_pos[word.ruby_target[target]] + d * k / unit.char_width.size()
					var e = start_pos[word.ruby_target[target]] + d * (k+1) / unit.char_width.size()
					var c = RubyLabelChar.new(bx,by,unit.char_width[k],
							unit.code[k],s,e)
					bx += unit.char_width[k]
					line_chars.append(c)
		return RubyLabelLine.new(line_chars,line_ruby_chars)

class RubyUnitWordData:
	var code : PackedInt32Array = []
	var width : float = 0
	var char_width : PackedFloat32Array = []

	func _init(word : String,font : Font,font_size : int):
		code.resize(word.length())
		for i in word.length():
			code[i] = word.unicode_at(i)
		char_width.resize(word.length())
		for i in word.length():
			char_width[i] = font.get_string_size(word[i],0,-1,font_size).x
			width += char_width[i]

class UnbreakableWordData:
	var base_text_data : Array[RubyUnitWordData] = [] # of RubyUnitWordData
	var base_text_x : PackedFloat32Array = []
	var ruby_text_data : Array[RubyUnitWordData] = [] # of RubyUnitWordData
	var ruby_text_x : PackedFloat32Array = []
	var ruby_target : PackedInt32Array = [] # of target base_text index
	var width : float
	
	func get_width() -> float:
		return width
	func get_ruby_width() -> float:
		return 0.0 if ruby_text_x.is_empty() else (ruby_text_x[ruby_text_x.size()-1] - ruby_text_x[0] + ruby_text_data.back().width)
	func get_left_ruby_buffer() -> float:
		return get_width() if ruby_text_x.is_empty() else ruby_text_x[0]
	func get_right_ruby_buffer() -> float:
		return get_width() - (0 if ruby_text_x.is_empty() else ruby_text_x[ruby_text_x.size()-1] + ruby_text_data.back().width)
	func has_ruby() -> bool:
		return not ruby_text_data.is_empty()

	func _init(word : Ruby.UnbreakableWord,font : Font,font_size : int,ruby_size : int,
			ruby_alignment_ruby : int,ruby_alignment_parent : int):
		if not word.has_ruby():
			var b_data := RubyUnitWordData.new(word.word,font,font_size)
			base_text_data = [b_data]
			base_text_x = [0]
			width = b_data.width
			return
		
		var x : float = 0
		var next : int = 0
		var ruby_buffer : float = +INF
		var index = 0
		for u_ in word.ruby_units:
			var u = u_ as Ruby.RubyUnit
			next += u.base_text.length()
			if u.has_ruby():
				var b_data := RubyUnitWordData.new(u.base_text,font,font_size)
				var r_data := RubyUnitWordData.new(u.ruby_text,font,ruby_size)

				if ruby_alignment_ruby != RubyAlignment.CENTER and\
						b_data.width > r_data.width and r_data.char_width.size() > 1:
					var ruby_offset : float
					var space : float
					match ruby_alignment_ruby:
						RubyAlignment.SPACE121:
							ruby_offset = (b_data.width - r_data.width) / (r_data.char_width.size() * 2)
							space = ruby_offset * 2
						RubyAlignment.SPACE010:
							ruby_offset = 0
							space = (b_data.width - r_data.width) / (r_data.char_width.size() -1)
						
					r_data.width = b_data.width - ruby_offset * 2
					var new_width : PackedFloat32Array = []
					for w in r_data.char_width:
						new_width.append(w + space)
					r_data.char_width = new_width
					if ruby_buffer + ruby_offset < 0:
						x += -(ruby_buffer + ruby_offset)
					base_text_data.append(b_data)
					base_text_x.append(x)
					ruby_text_data.append(r_data)
					ruby_text_x.append(x + ruby_offset)
					x += b_data.width
					ruby_buffer = ruby_offset
					ruby_target.append(index)
				elif ruby_alignment_parent != ParentAlignment.NOTHING and b_data.width < r_data.width:
					var base_offset : float
					var space : float
					var sub : float = r_data.width - b_data.width
					var count = b_data.char_width.size()
					if ruby_alignment_parent != ParentAlignment.CENTER and count > 1:
						match ruby_alignment_parent:
							ParentAlignment.SPACE121:
								base_offset = sub / (count * 2)
								space = base_offset * 2
							ParentAlignment.SPACE010:
								base_offset = 0
								space = sub / (count - 1)
					else:
						base_offset = sub/2
						space = 0
				
					var new_width : PackedFloat32Array = []
					for w in b_data.char_width:
						new_width.append(w + space)
					b_data.char_width = new_width
					base_text_data.append(b_data)
					base_text_x.append(x + base_offset)
					ruby_text_data.append(r_data)
					ruby_text_x.append(x)
					x += r_data.width
					ruby_buffer = 0
					ruby_target.append(index)
				else:
					var sub := (b_data.width - r_data.width)/2
					if ruby_buffer + sub < 0:
						x += -(ruby_buffer + sub)
					base_text_data.append(b_data)
					base_text_x.append(x)
					ruby_text_data.append(r_data)
					ruby_text_x.append(x + sub)
					x += b_data.width
					ruby_buffer = sub
					ruby_target.append(index)
			else:
				var b_data := RubyUnitWordData.new(u.base_text,font,font_size)
				base_text_data.append(b_data)
				base_text_x.append(x)
				x += b_data.width
				ruby_buffer += b_data.width
			index += 1
		width = x

func build_words():
	if text_input.is_empty() or not ruby_regex.is_valid():
		return
	var font := font_font if font_font else get_theme_default_font()
	if not font:
		return

	var ruby_text = Ruby.RubyString.create_by_regex(text_input,line_break_word,ruby_regex)
	unbreakable_words.clear()
	_output_base_text = ruby_text.get_base_text()
	_output_phonetic_text = ruby_text.get_phonetic_text()
	var text_pos : int = 0
	for w_ in ruby_text.words:
		var w  = w_ as Ruby.UnbreakableWord
		text_pos += w.word.length()
		var next_code = _output_base_text.unicode_at(text_pos) if text_pos < _output_base_text.length() else 0
		unbreakable_words.append(UnbreakableWordData.new(w,font,font_size,font_ruby_size,
				ruby_alignment_ruby,ruby_alignment_parent))
	layout()


func layout():
	if not get_parent():
		return
	lines = []
	if unbreakable_words.is_empty():
		return
	var font := font_font if font_font else get_theme_default_font()
	if not font:
		return

	var x : float = buffer_left_padding
	var y : float = 0
	var ruby_height : float = font.get_height(font_ruby_size) + adjust_ruby_distance
	var line_height : float = font.get_height(font_size) + adjust_line_height
	var ruby_buffer : float = buffer_left_margin + buffer_left_padding
	var text_pos = 0
	var line_words = [] # of UnbreakableWordData
	var line_words_x : PackedFloat32Array = []
	var line_has_ruby : bool = false
	for w_ in unbreakable_words:
		var w = w_ as UnbreakableWordData
		if line_words.is_empty():
			if w.base_text_data[0].code[0] == "\n".unicode_at(0):
				y += line_height + adjust_no_ruby_space
				text_pos += 1
				continue
			
			line_words.append(w)
			x = max(-w.get_left_ruby_buffer() - buffer_left_margin - buffer_left_padding,0) + buffer_left_padding
			line_words_x.append(x)
			x += w.get_width()
			if w.has_ruby():
				ruby_buffer = w.get_right_ruby_buffer()
				line_has_ruby = true
			else:
				ruby_buffer += w.get_width()
			continue

		var base_x = x + w.get_width() - min(ruby_buffer + w.get_left_ruby_buffer(),0)
		var ruby_x = x - min(ruby_buffer + w.get_left_ruby_buffer(),0) + w.get_width() - min(w.get_right_ruby_buffer(),0)
		if w.base_text_data[0].code[0] == "\n".unicode_at(0) or\
				base_x > size.x - buffer_right_padding or\
				(w.has_ruby() and ruby_x > size.x + buffer_right_margin):
			if display_rate_phonetic:
				lines.append(RubyLabelLine.create_by_phonetic(line_words,line_words_x,
						font,font_size,font_ruby_size,text_pos,y,line_has_ruby,adjust_ruby_distance,adjust_no_ruby_space))
				for lw_ in line_words:
					var lw = lw_ as UnbreakableWordData
					lw.ruby_target.size()
					for btd in lw.base_text_data:
						text_pos += btd.char_width.size()
					for i in lw.ruby_text_data.size():
						text_pos += lw.ruby_text_data[i].char_width.size() - lw.base_text_data[lw.ruby_target[i]].char_width.size()
			else:
				lines.append(RubyLabelLine.create(line_words,line_words_x,
						font,font_size,font_ruby_size,text_pos,y,line_has_ruby,adjust_ruby_distance,adjust_no_ruby_space))
				for lw in line_words:
					for btd in lw.base_text_data:
						text_pos += btd.char_width.size()
			x = buffer_left_padding
			y += line_height + (ruby_height if line_has_ruby else float(adjust_no_ruby_space))
			ruby_buffer = buffer_left_margin + buffer_left_padding
			line_words.clear()
			line_words_x.resize(0)
			line_has_ruby = false

		if w.base_text_data[0].code[0] == "\n".unicode_at(0):
			text_pos += 1
			continue

		line_words.append(w)
		if w.has_ruby():
			x -= min(ruby_buffer + w.get_left_ruby_buffer(),0)
			line_has_ruby = true
			ruby_buffer = w.get_right_ruby_buffer()
		else:
			ruby_buffer += w.get_width()
		line_words_x.append(x)
		x += w.get_width()
	
	if not line_words.is_empty():
		var line
		if display_rate_phonetic:
			line = RubyLabelLine.create_by_phonetic(line_words,line_words_x,font,font_size,font_ruby_size,text_pos,y,
					line_has_ruby,adjust_ruby_distance,adjust_no_ruby_space)
		else:
			line = RubyLabelLine.create(line_words,line_words_x,font,font_size,font_ruby_size,text_pos,y,
					line_has_ruby,adjust_ruby_distance,adjust_no_ruby_space)
		lines.append(line)
		y += line_height + (float(adjust_no_ruby_space) if line.ruby.is_empty() else ruby_height)

	layout_height = (y - adjust_line_height) if adjust_line_height < 0 else y

	if auto_fit_height:
		custom_minimum_size.y = layout_height
		size.y = layout_height
	queue_redraw()

func _draw():
	var font := font_font if font_font else get_theme_default_font()
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
	
	if clip_rect:
		RenderingServer.canvas_item_set_custom_rect(get_canvas_item(),true,
				Rect2(-buffer_left_margin-1,0,buffer_left_margin+1 + size.x + buffer_right_margin+1,size.y))
		RenderingServer.canvas_item_set_clip(get_canvas_item(), true)
	else:
		RenderingServer.canvas_item_set_clip(get_canvas_item(), false)
	if buffer_visible_border:
		draw_line(Vector2(-buffer_left_margin,0),Vector2(-buffer_left_margin,size.y),Color.WHITE)
		draw_line(Vector2(buffer_left_padding,0),Vector2(buffer_left_padding,size.y),Color.WHITE)
		draw_line(Vector2(size.x - buffer_right_padding,0),Vector2(size.x - buffer_right_padding,size.y),Color.WHITE)
		draw_line(Vector2(size.x + buffer_right_margin,0),Vector2(size.x + buffer_right_margin,size.y),Color.WHITE)

	var count = (_output_phonetic_text.length() if display_rate_phonetic else _output_base_text.length()) * display_rate/100
	if display_horizontal_alignment == HorizontalAlignment.LEFT:
		for l in lines:
			for c_ in l.base:
				var c := c_ as RubyLabelChar
				if count >= c.end:
					font.draw_char_outline(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_size,font_outline_width,font_outline_color)
				elif count > c.start:
					var fadecolor := font_outline_color
					fadecolor.a = (count - c.start) / (c.end - c.start)
					font.draw_char_outline(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_size,font_outline_width,fadecolor)
		for l in lines:
			for c_ in l.ruby:
				var c := c_ as RubyLabelChar
				if count >= c.end:
					font.draw_char_outline(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_ruby_size,font_ruby_outline_width,font_outline_color)
				elif count > c.start:
					var fadecolor := font_outline_color
					fadecolor.a = (count - c.start) / (c.end - c.start)
					font.draw_char_outline(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_ruby_size,font_ruby_outline_width,fadecolor)
		for l in lines:
			for c_ in l.base:
				var c := c_ as RubyLabelChar
				if count >= c.end:
					font.draw_char(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_size,font_color)
				elif count > c.start:
					var fadecolor := font_color
					fadecolor.a = (count - c.start) / (c.end - c.start)
					font.draw_char(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_size,fadecolor)
		for l in lines:
			for c_ in l.ruby:
				var c := c_ as RubyLabelChar
				if count >= c.end:
					font.draw_char(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_ruby_size,font_color)
				elif count > c.start:
					var fadecolor := font_color
					fadecolor.a = (count - c.start) / (c.end - c.start)
					font.draw_char(get_canvas_item(),Vector2(c.x,c.y + y_offset),c.character,font_ruby_size,fadecolor)
		return

	var slides := PackedFloat32Array()
	slides.resize(lines.size())
	if display_horizontal_alignment == HorizontalAlignment.RIGHT:
		for i in lines.size():
			var l := lines[i] as RubyLabelLine
			if not l.base.is_empty():
				var left = l.base.front().x
				var right = l.base.back().x + l.base.back().width
				if not l.ruby.is_empty():
					left = min(left,l.ruby.front().x + buffer_left_padding + buffer_left_margin)
					right = max(right,l.ruby.back().x + l.ruby.back().width - buffer_right_padding - buffer_right_margin)
				var width = right - left
				slides[i]  = (size.x - buffer_right_padding) - (buffer_left_padding + width)
	elif display_horizontal_alignment == HorizontalAlignment.CENTER:
		for i in lines.size():
			var l := lines[i] as RubyLabelLine
			if not l.base.is_empty():
				var left = l.base.front().x
				var right = l.base.back().x + l.base.back().width
				if not l.ruby.is_empty():
					left = min(left,l.ruby.front().x)
					right = max(right,l.ruby.back().x + l.ruby.back().width)
				var width = right - left
				var slide = (size.x + buffer_left_padding - buffer_right_padding - width) / 2 - buffer_left_padding
				slides[i] = slide
	else:
		return

	for i in lines.size():
		var l := lines[i] as RubyLabelLine
		for c_ in l.base:
			var c := c_ as RubyLabelChar
			var pos = Vector2(c.x + slides[i],c.y + y_offset)
			if count >= c.end:
				font.draw_char_outline(get_canvas_item(),pos,c.character,font_size,font_outline_width,font_outline_color)
			elif count > c.start:
				var fadecolor := font_outline_color
				fadecolor.a = (count - c.start) / (c.end - c.start)
				font.draw_char_outline(get_canvas_item(),pos,c.character,font_size,font_outline_width,fadecolor)
	for i in lines.size():
		var l := lines[i] as RubyLabelLine
		for c_ in l.ruby:
			var c := c_ as RubyLabelChar
			var pos = Vector2(c.x + slides[i],c.y + y_offset)
			if count >= c.end:
				font.draw_char_outline(get_canvas_item(),pos,c.character,font_ruby_size,font_ruby_outline_width,font_outline_color)
			elif count > c.start:
				var fadecolor := font_outline_color
				fadecolor.a = (count - c.start) / (c.end - c.start)
				font.draw_char_outline(get_canvas_item(),pos,c.character,font_ruby_size,font_ruby_outline_width,fadecolor)
	for i in lines.size():
		var l := lines[i] as RubyLabelLine
		for c_ in l.base:
			var c := c_ as RubyLabelChar
			var pos = Vector2(c.x + slides[i],c.y + y_offset)
			if count >= c.end:
				font.draw_char(get_canvas_item(),pos,c.character,font_size,font_color)
			elif count > c.start:
				var fadecolor := font_color
				fadecolor.a = (count - c.start) / (c.end - c.start)
				font.draw_char(get_canvas_item(),pos,c.character,font_size,fadecolor)
	for i in lines.size():
		var l := lines[i] as RubyLabelLine
		for c_ in l.ruby:
			var c := c_ as RubyLabelChar
			var pos = Vector2(c.x + slides[i],c.y + y_offset)
			if count >= c.end:
				font.draw_char(get_canvas_item(),pos,c.character,font_ruby_size,font_color)
			elif count > c.start:
				var fadecolor := font_color
				fadecolor.a = (count - c.start) / (c.end - c.start)
				font.draw_char(get_canvas_item(),pos,c.character,font_ruby_size,fadecolor)
			

