
class_name LyricsContainer

enum SyncMode { UNSYNC = 0, LINE = 1, KARAOKE = 3 }


var lines : Array
var at_tag_container : LyricsRuby.AtTagContainer
var sync_mode : SyncMode

static func default_splitter(text : String) -> PackedStringArray:
	if text.is_empty():
		return PackedStringArray([""])
	return text.split()
	
func _init(lyrics_text : String,splitter : Callable = default_splitter):
	at_tag_container = LyricsRuby.AtTagContainer.new(lyrics_text)
	for l in at_tag_container.remain_lines:
		lines.append(LyricsLine.new(l,at_tag_container,splitter))


class LyricsLine:
	var units : Array # of LyricsLine.Unit
	var start_time : float
	var end_time : float
	var sync_mode : SyncMode
	
	func _init(lyrics_line : String,at_tag : LyricsRuby.AtTagContainer,splitter : Callable):
		var ruby_units := at_tag.translate(lyrics_line)
		
		for u in ruby_units:
			var unit := u as LyricsRuby.RubyUnit
			units.append(Unit.new(LyricsTimeTag.Unit.create(unit.base_text,splitter),
					LyricsTimeTag.Unit.create(unit.ruby_text,splitter) if unit.has_ruby() else null))
		
		for i in units.size():
			var unit := units[i] as Unit
			if unit.base.characters.is_empty():
				if i + 1 < units.size() and units[i+1].base.start_times[0] < 0:
					units[i+1].base.start_times[0] = units[i].base.start_times[0]
					if units[i+1].ruby:
						units[i+1].ruby.start_times[0] = units[i].base.start_times[0]
				if i - 1 >= 0 and units[i-1].base.end_times[units[i-1].base.end_times.size()-1] < 0:
					if i == units.size() - 1 or (i + 1 < units.size() and units[i+1].base.start_times[0] >= 0):
						units[i-1].base.end_times[units[i-1].base.end_times.size()-1] = unit.base.start_times[0]
						if units[i-1].ruby:
							units[i-1].ruby.end_times[units[i-1].ruby.end_times.size()-1] = unit.base.start_times[0]

		start_time = units[0].base.start_times[0]
		end_time = units.back().base.end_times[units.back().base.end_times.size()-1]
#		if end_time < 0 and units.back().base.characters.is_empty():
#				end_time = units.back().base.start_times[0]
		units = units.filter(func(u:Unit) : return not u.base.characters.is_empty())

		var elements := LyricsTimeTag.parse(lyrics_line)
#		start_time = elements.front().start_time
#		end_time = elements.back().start_time if elements.back().text.is_empty() else -1
		if elements.size() == 1 and elements[0].start_time >= 0:
			sync_mode = SyncMode.LINE
		elif elements.size() <= 1:
			sync_mode = SyncMode.UNSYNC
		else:
			sync_mode = SyncMode.KARAOKE

	func get_base_text() -> String:
		var r : String
		for u in units:
			var unit := u as Unit
			r += unit.base.get_text()
		return r
	
	func get_phonetic_text() -> String:
		var r : String
		for u in units:
			var unit := u as Unit
			r += unit.ruby.get_text() if unit.has_ruby() else unit.base.get_text()
		return r

	class Unit:
		var base : LyricsTimeTag.Unit
		var ruby : LyricsTimeTag.Unit
		
		func _init(b,r):
			base = b
			ruby = r
			if ruby:
				if base.start_times[0] < 0 and ruby.start_times[0] >= 0:
					base.start_times[0] = ruby.start_times[0]
				if ruby.start_times[0] < 0 and base.start_times[0] >= 0:
					ruby.start_times[0] = base.start_times[0]
				if base.end_times[base.end_times.size()-1] < 0 and ruby.end_times[ruby.end_times.size()-1] >= 0:
					base.end_times[base.end_times.size()-1] = ruby.end_times[ruby.end_times.size()-1]
				if ruby.end_times[ruby.end_times.size()-1] < 0 and base.end_times[base.end_times.size()-1] >= 0:
					ruby.end_times[ruby.end_times.size()-1] = base.end_times[base.end_times.size()-1]
		
		func has_ruby() -> bool:
			return ruby != null


