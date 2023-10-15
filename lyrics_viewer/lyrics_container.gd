
class_name LyricsContainer


enum SyncMode { UNSYNC = 0, LINE = 1, KARAOKE = 3 }


var lines : Array[LyricsLine]
var at_tag_container : AtTagContainer
var sync_mode : SyncMode

#static func default_splitter(text : String) -> PackedStringArray:
#	if text.is_empty():
#		return PackedStringArray([""])
#	return text.split()
	
func _init(lyrics_text : String):
	at_tag_container = AtTagContainer.new(lyrics_text)
	for l in at_tag_container.other_lines:
		var line := LyricsLine.create(l,at_tag_container)
		lines.append(line)

#		@warning_ignore("int_as_enum_without_cast")
		sync_mode = (sync_mode | line.sync_mode) as SyncMode
		

func get_end_time() -> float:
	for i in range(lines.size()-1,-1,-1):
		var end : float = lines[i].force_get_end_time()
		if end >= 0:
			return end
	return -1.0


class LyricsLine:
	var units : Array[Unit] # of LyricsLine.Unit
	var sync_mode : SyncMode
	
	func _init(u : Array[Unit],sm : SyncMode):
		units = u
		sync_mode = sm
	
	static func create(lyrics_line : String,at_tag : AtTagContainer) -> LyricsLine:
		var units_ : Array[Unit] = []
		var sync_mode_ : SyncMode
		var ruby_units := at_tag.translate(lyrics_line)
		var tt_count := 0
		for u in ruby_units:
			var unit := u as RubyUnit
			var base := TimeTag.parse(unit.base_text)
			var ruby := TimeTag.parse(unit.ruby_text) if unit.has_ruby() else ([] as Array[TimeTag])
			units_.append(Unit.new(base,ruby))
			
			if base[0].start_time >= 0 or base.size() > 1:
				tt_count += base.size()
			if not ruby.is_empty() and (ruby[0].start_time >= 0 or ruby.size() > 1):
				tt_count += ruby.size()
		if units_[0].get_start_time() < 0:
			sync_mode_ = SyncMode.UNSYNC
		elif tt_count > 1:
			sync_mode_ = SyncMode.KARAOKE
		elif tt_count == 1:
			sync_mode_ = SyncMode.LINE
		else:
			sync_mode_ = SyncMode.UNSYNC
		return LyricsLine.new(units_,sync_mode_)
		
	static func create_from_time_tag(time_tag : TimeTag) -> LyricsLine:
		return LyricsLine.new([Unit.new([time_tag],[])],SyncMode.LINE)


	func get_base_text() -> String:
		var r : String = ""
		for u in units:
			var unit := u as Unit
			r += unit.get_base_text()
		return r
	
	func get_phonetic_text() -> String:
		var r : String = ""
		for u in units:
			var unit := u as Unit
			r += unit.get_ruby_text() if unit.has_ruby() else unit.get_base_text()
		return r
	
	func get_rubyed_text(parent:String,begin:String,end:String) -> String:
		var r : String = ""
		for u in units:
			var unit := u as Unit
			if unit.has_ruby():
				r += parent + unit.get_base_text() + begin + unit.get_ruby_text() + end
			else:
				r += unit.get_base_text()
		return r
		
	func get_start_time() -> float:
		return units[0].force_get_start_time()

	func get_end_time() -> float:
		return units[-1].get_end_time()
		
	func force_get_end_time() -> float:
		for i in range(units.size()-1,-1,-1):
			var end : float = units[i].force_get_end_time()
			if end >= 0:
				return end
		return -1.0

	class Unit:
		var base : Array[TimeTag] # of TimeTag
		var ruby : Array[TimeTag] # of TimeTag
		
		func _init(b : Array[TimeTag],r : Array[TimeTag]):
			base = b
			ruby = r
		
		func has_ruby() -> bool:
			return not ruby.is_empty()
		
		func get_base_text() -> String:
			var r : String = ""
			for tt in base:
				r += tt.text
			return r
		func get_ruby_text() -> String:
			var r : String = ""
			for tt in ruby:
				r += tt.text
			return r
		
		func get_start_time() -> float:
			var start : float = base[0].start_time
			var rstart : float = ruby[0].start_time if not ruby.is_empty() else -1.0
			if start >= 0:
				if rstart >= 0:
					start = min(start,rstart)
			else:
				if rstart >= 0:
					start = rstart
			return start
		func force_get_start_time() -> float:
			var start = get_start_time()
			if start >= 0:
				return start
			for b in base:
				if b.start_time >= 0:
					start = b.start_time
					break
			for r in ruby:
				if r.start_time >= 0:
					start = min(start,r.start_time)
					break
			return start

		func get_end_time() -> float:
			var end = base[-1].start_time if base[-1].text.is_empty() else -1.0
			var rend = ruby[-1].start_time if not ruby.is_empty() and ruby[-1].text.is_empty() else -1.0
			if end >= 0:
				if rend >= 0:
					end = max(end,rend)
			else:
				if rend >= 0:
					end = rend
			return end
		func force_get_end_time() -> float:
			var end = get_end_time()
			if end >= 0:
				return end
			for i in range(base.size()-1,-1,-1):
				if base[i].start_time >= 0:
					end = base[i].start_time
					break
			for i in range(ruby.size()-1,-1,-1):
				if ruby[i].start_time >= 0:
					end = max(end,ruby[i].start_time)
					break
			return end

class TimeTag:
	const TIME_TAG_PATTERN := "\\[(\\d+):(\\d+)[:.](\\d+)\\]"
	const LINE_PATTERN := "^" + TIME_TAG_PATTERN + "(.*)$"
	const KARAOKE_PATTERN := TIME_TAG_PATTERN + ".*?((?=" + TIME_TAG_PATTERN + ")|$)"
	
	var text : String
	var start_time : float
	
	func _init(start_time_ : float,text_ : String):
		start_time = start_time_
		text = text_

	static func create(text_ : String):
		var regex = RegEx.create_from_string(LINE_PATTERN)
		var m := regex.search(text_)
		if m:
			var sec := float(m.get_string(1)) * 60 + float(m.get_string(2)) + float("0." + m.get_string(3))
			return TimeTag.new(sec,m.get_string(4))
		return TimeTag.new(-1,text_);

	static func parse(text_ : String) -> Array[TimeTag]:
		var karaoke_regex := RegEx.create_from_string(KARAOKE_PATTERN)
		var k = karaoke_regex.search_all(text_)
		if k.is_empty():
			return [TimeTag.create(text_)]
		if k[0].get_start() > 0:
			var elements : Array[TimeTag] = [TimeTag.create(text_.substr(0,k[0].get_start()))]
			elements.append_array(k.map(func(v) : return TimeTag.create(v.get_string())))
			return elements
		var result : Array[TimeTag] = []
		result.assign(k.map(func(v) : return TimeTag.create(v.get_string())))
		return result



class RubyUnit:
	var base_text : String
	var ruby_text : String
	
	func _init(b:String,r:String = ""):
		base_text = b;
		ruby_text = r;
		
	func has_ruby() -> bool:
		return not ruby_text.is_empty()


class AtTagContainer:
	class Tag:
		enum TagType {AT,BRACKET}
		var tag_type : TagType
		var line : int
		var name : String
		var value : String
		
		func _init(t,l,n,v):
			tag_type = t
			line = l
			name = n
			value = v
	
	var ruby_parent : String
	var ruby_begin : String
	var ruby_end : String
	var rubying : PackedStringArray
	var offset : float

	var tags : Array[Tag]
	
	var other_lines : PackedStringArray

	var _rubying_regex : RegEx
	var _ruby_pattern_regex : RegEx

	func _init(lyrics : String):
		var tt_regex := RegEx.create_from_string(TimeTag.LINE_PATTERN)
		var at_regex := RegEx.create_from_string("^@([^=]+)=(.*)")
		var tag_regex := RegEx.create_from_string("^\\[([^:]+):([^\\]]*)\\]$")
		_rubying_regex = RegEx.create_from_string("^\\[([^\\]]+)\\]((\\d+),(\\d+))?\\[([^\\]]+)\\]$");

		
		var lines := lyrics.replace("\r\n","\n").replace("\r","\n").split("\n")
		for i in lines.size():
			var line := lines[i] as String
			var at = at_regex.search(line)
			if at:
				var name = at.get_string(1).to_lower()
				var value = at.get_string(2)
				tags.append(Tag.new(Tag.TagType.AT,i,name,value))
				match name:
					"ruby_parent":
						ruby_parent = value
					"ruby_begin":
						ruby_begin = value
					"ruby_end":
						ruby_end = value
					"ruby_set":
# ルビ指定にタグと紛らわしい[]を使わないとするなら一行で書ける @ruby_set=[｜][《][》]
						var r = RegEx.create_from_string("\\[([^\\[\\]]+)\\]\\[([^\\[\\]]+)\\]\\[([^\\[\\]]+)\\]")
						var m = r.search(value)
						if m:
							ruby_parent = m.get_string(1)
							ruby_begin = m.get_string(2)
							ruby_end = m.get_string(3)
					"ruby":
						rubying.append(value)
					"offset":
						offset = float(value)
						if not value.contains(".") and offset > 10:
							offset = int(value) / 1000.0
					_:
						pass
				continue
			if tt_regex.search(line):
				other_lines.append(line)
				continue
			var tag := tag_regex.search(line)
			if tag:
				var name = tag.get_string(1).to_lower()
				var value = tag.get_string(2)
				tags.append(Tag.new(Tag.TagType.BRACKET,i,name,value))
				if name == "offset":
					offset = float(value)
					if not value.contains(".") and offset > 10:
						offset = int(value) / 1000.0
				continue
			other_lines.append(line)
		
		if not (ruby_parent.is_empty() || ruby_begin.is_empty() || ruby_end.is_empty()):
			var ep := AtTagContainer.escape_regex(ruby_parent)
			var eb := AtTagContainer.escape_regex(ruby_begin)
			var ee := AtTagContainer.escape_regex(ruby_end)
			_ruby_pattern_regex = RegEx.create_from_string(ep + "(.+?)" + eb + "(.+?)" +ee)
		else:
			_ruby_pattern_regex = null
		return

	func translate(text : String) -> Array[RubyUnit]:
		var target_text := text
		var result : Array[RubyUnit] = []
		if _ruby_pattern_regex:
			while true:
				var ruby = _ruby_pattern_regex.search(target_text)
				if ruby:
					if ruby.get_start() > 0:
						result.append(RubyUnit.new(target_text.substr(0,ruby.get_start())))
					result.append(RubyUnit.new(ruby.get_string(1),ruby.get_string(2)))
					if ruby.get_end() == target_text.length():
						break
					target_text = target_text.substr(ruby.get_end())
				else:
					result.append(RubyUnit.new(target_text))
					break
		else:
			result.append(RubyUnit.new(text))

		if not rubying.is_empty():
			var result_base : String = ""
			for i in result:
				result_base += i.base_text
			for r in rubying:
				var m = _rubying_regex.search(r)
				if not m:
					continue
				var parent_target := m.get_string(1)
				var ruby = m.get_string(5)
				var parent_offset := int(m.get_string(3)) if m.get_start(3) >= 0 else 0
				var parent_length := int(m.get_string(4)) if m.get_start(4) >= 0 else parent_target.length() - parent_offset
				var next := 0
				while true:
					var index := result_base.find(parent_target,next)
					if index < 0:
						break
					next = index + 1
					
					var count := 0
					index += parent_offset
					for i in result.size():
						if count > index:
							break
						if count + result[i].base_text.length() <= index:
							count += result[i].base_text.length()
							continue
						if result[i].has_ruby():
							break
						if index + parent_length > count + result[i].base_text.length():
							break
						
						var div1 := index - count
						var div2 := index - count + parent_length
						var target : String = result[i].base_text
						if div1 > 0 and div2 < target.length():
							result.remove_at(i)
							result.insert(i,RubyUnit.new(target.substr(0,div1)))
							result.insert(i + 1,RubyUnit.new(target.substr(div1,div2-div1),ruby))
							result.insert(i + 2,RubyUnit.new(target.substr(div2)))
						elif div1 == 0 and div2 < target.length():
							result.remove_at(i)
							result.insert(i,RubyUnit.new(target.substr(0,div2),ruby))
							result.insert(i + 1,RubyUnit.new(target.substr(div2)))
						elif div1 > 0 and div2 == target.length():
							result.remove_at(i)
							result.insert(i,RubyUnit.new(target.substr(0,div1)))
							result.insert(i + 1,RubyUnit.new(target.substr(div1,div2-div1),ruby))
						elif div1 == 0 and div2 == target.length():
							result[i] = RubyUnit.new(target,ruby)
						break
					
		return result
		

	static func escape_regex(text : String) -> String:
		for c in ["\\","*","+","?","|","{","}","[","]","(",")","^","$",".","#"]:
			text = text.replace(c,"\\"+c)
		return text
	
