
class_name LyricsContainer


enum SyncMode { UNSYNC = 0, LINE = 1, KARAOKE = 3 }


var lines : Array
var at_tag_container : AtTagContainer
var sync_mode : SyncMode

#static func default_splitter(text : String) -> PackedStringArray:
#	if text.is_empty():
#		return PackedStringArray([""])
#	return text.split()
	
func _init(lyrics_text : String):
	at_tag_container = AtTagContainer.new(lyrics_text)
	for l in at_tag_container.other_lines:
		var line := LyricsLine.new(l,at_tag_container)
		lines.append(line)
		@warning_ignore(int_assigned_to_enum)
		sync_mode = sync_mode | line.sync_mode
		


class LyricsLine:
	var units : Array # of LyricsLine.Unit
	var sync_mode : SyncMode
	
	func _init(u,sm):
		units = u
		sync_mode = sm
	
	static func create(lyrics_line : String,at_tag : AtTagContainer) -> LyricsLine:
		var units_ : Array = []
		var sync_mode_ : SyncMode
		var ruby_units := at_tag.translate(lyrics_line)
		var tt_count := 0
		for u in ruby_units:
			var unit := u as RubyUnit
			var base := TimeTag.parse(unit.base_text)
			var ruby := TimeTag.parse(unit.ruby_text) if unit.has_ruby() else []
			units_.append(Unit.new(base,ruby))
			
			if base[0].start_time >= 0 or base.size() > 1:
				tt_count += base.size()
			if not ruby.is_empty() and (ruby[0].start_time >= 0 or ruby.size() > 1):
				tt_count += ruby.size()
		if tt_count > 1:
			sync_mode_ = SyncMode.KARAOKE
		elif tt_count == 1:
			if (units_[0].base[0].start_time > 0 or 
				(not units_[0].ruby.is_empty() and units_[0].ruby[0].start_time > 0)):
				sync_mode_ = SyncMode.LINE
			else:
				sync_mode_ = SyncMode.KARAOKE
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
		return units.back().get_end_time()

	class Unit:
		var base : Array # of TimeTag
		var ruby : Array # of TimeTag
		
		func _init(b,r):
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
			var rstart : float = ruby[0].start_time if not ruby.is_empty() else -1
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
			var end = base.back().start_time if base.back().text.is_empty() else -1
			var rend = ruby.back().start_time if not ruby.is_empty() and ruby.back().text.is_empty() else -1
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
				if base[i].end_time >= 0:
					end = base[i].end_time
					break
			for i in range(ruby.size()-1,-1,-1):
				if ruby[i].end_time >= 0:
					end = max(end,ruby[i].end_time)
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

	static func parse(text_ : String) -> Array:
		var karaoke_regex := RegEx.create_from_string(KARAOKE_PATTERN)
		var k = karaoke_regex.search_all(text_)
		if k.is_empty():
			return [TimeTag.create(text_)]
		if k[0].get_start() > 0:
			var elements := [TimeTag.create(text_.substr(0,k[0].get_start()))]
			elements.append_array(k.map(func(v) : return TimeTag.create(v.get_string())))
			return elements
		return k.map(func(v) : return TimeTag.create(v.get_string()))



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
	var rubying : Array
	var offset : float

	var tags : Array
	
	var other_lines : PackedStringArray

	func _init(lyrics : String):
		var tt_regex := RegEx.create_from_string(TimeTag.LINE_PATTERN)
		var at_regex := RegEx.create_from_string("^@([^=]+)=(.*)")
		var tag_regex := RegEx.create_from_string("^\\[([^:]+):([^\\]]*)\\]$")
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
		return

	func translate(text : String) -> Array:
		
		var ruby_pattern = AtTagContainer.escape_regex(ruby_parent) + "(.+?)" +\
				AtTagContainer.escape_regex(ruby_begin) + "(.+?)" +\
				AtTagContainer.escape_regex(ruby_end)
		var r = RegEx.create_from_string(ruby_pattern)

		var target := text
		var result : Array = []
		while true:
			var ruby = r.search(target)
			if ruby:
				if ruby.get_start() > 0:
					result.append(RubyUnit.new(target.substr(0,ruby.get_start())))
				result.append(RubyUnit.new(ruby.get_string(1),ruby.get_string(2)))
				if ruby.get_end() == target.length():
					break
				target = target.substr(ruby.get_end())
			else:
				result.append(RubyUnit.new(target))
				break
		return result

	static func escape_regex(text : String) -> String:
		for c in ["\\","*","+","?","|","{","}","[","]","(",")","^","$",".","#"]:
			text = text.replace(c,"\\"+c)
		return text
			
