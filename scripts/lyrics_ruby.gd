
class_name LyricsRuby

class RubyUnit:
	var base_text : String
	var ruby_text : String
	
	func _init(b:String,r:String = ""):
		base_text = b;
		ruby_text = r;
		
	func has_ruby() -> bool:
		return not ruby_text.is_empty()


class AtTagContainer:
	var ruby_parent : String
	var ruby_begin : String
	var ruby_end : String
	var rubying : Array
	var offset : float

	var other_tags : Dictionary
	
	var remain_lines : PackedStringArray

	func _init(lyrics : String):
		var tt_regex := RegEx.create_from_string(LyricsTimeTag.LINE_HEAD_PATTERN)
		var at_regex := RegEx.create_from_string("^@([^=]+)=(.*)")
		var tag_regex := RegEx.create_from_string("^\\[([^:]+):([^\\]]*)\\]$")
		var lines := lyrics.replace("\r\n","\n").replace("\r","\n").split("\n")
		for l in lines:
			var line := l as String
			var at = at_regex.search(line)
			if at:
				var name = at.get_string(1).to_lower()
				var value = at.get_string(2)
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
						other_tags[name] = value
				continue
			if tt_regex.search(line):
				remain_lines.append(line)
				continue
			var tag := tag_regex.search(line)
			if tag:
				var name = tag.get_string(1).to_lower()
				var value = tag.get_string(2)
				if name == "offset":
					offset = float(value)
					if not value.contains(".") and offset > 10:
						offset = int(value) / 1000.0
				continue
			remain_lines.append(line)
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
			
