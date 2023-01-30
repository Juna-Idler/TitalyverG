
class_name LyricsTimeTag

const TIME_TAG_PATTERN := "\\[(\\d+):(\\d+)[:.](\\d+)\\]"
const LINE_HEAD_PATTERN := "^" + TIME_TAG_PATTERN
const ELEMENT_PATTERN := LINE_HEAD_PATTERN + "(.*)$"
const KARAOKE_BLOCK_PATTERN := TIME_TAG_PATTERN + ".*?((?=" + TIME_TAG_PATTERN + ")|$)"


class Element:
	var text : String
	var start_time : float
	
	func _init(start_time_ : float,text_ : String):
		start_time = start_time_
		text = text_

	static func create(text_ : String):
		var regex = RegEx.create_from_string(ELEMENT_PATTERN)
		var m := regex.search(text_)
		if m:
			var sec := float(m.get_string(1)) * 60 + float(m.get_string(2)) + float("0." + m.get_string(3))
			return Element.new(sec,m.get_string(4))
		return Element.new(-1,text_);


class Unit:
	var characters : PackedStringArray
	var start_times : PackedFloat32Array
	var end_times : PackedFloat32Array

	func _init(c,s,e):
		characters = c
		start_times = s
		end_times = e
	
	func get_text() -> String:
		return "".join(characters)

	static func create(text : String,splitter : Callable):
		var elements = LyricsTimeTag.parse(text)
		var text_length := 0
		for e in elements:
			text_length += e.text.length()
		if text_length == 0:
			return Unit.new([""],[elements.front().start_time],[elements.back().start_time])

		var characters_ = PackedStringArray()
		var elements_count := PackedInt32Array()
		elements_count.resize(elements.size())
		for i in elements.size():
			var splited : PackedStringArray = splitter.call(elements[i].text)
			characters_.append_array(splited)
			elements_count[i] = splited.size()
		
		var start_times_ := PackedFloat32Array()
		var end_times_ := PackedFloat32Array()
		start_times_.resize(characters_.size() + 2)
		start_times_.fill(-1)
		end_times_.resize(characters_.size() + 2)
		end_times_.fill(-1)

		var text_pos = 1
		for i in elements.size():
			var e := elements[i] as Element
			if not e.text.is_empty():
				start_times_[text_pos] = e.start_time
			if end_times_[text_pos - 1] < 0:
				end_times_[text_pos - 1] = e.start_time
			text_pos += elements_count[i]
		return Unit.new(characters_,start_times_.slice(1,-1),end_times_.slice(1,-1))

static func parse(text : String) -> Array:
	var head_regex := RegEx.create_from_string(LINE_HEAD_PATTERN)
	var karaoke_regex := RegEx.create_from_string(KARAOKE_BLOCK_PATTERN)
	var head := head_regex.search(text)
	if  head:
		var k = karaoke_regex.search_all(text)
		return k.map(func(v) : return Element.create(v.get_string()))
	
	var k = karaoke_regex.search_all("[00:00.00]" + text)
	var elements := k.map(func(v) : return Element.create(v.get_string()))
	elements[0].start_time = -1
	return elements
	
