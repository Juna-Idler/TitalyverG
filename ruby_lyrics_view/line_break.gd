
class_name LineBreak

class ILineBreak:
	func _is_link(_left : String,_right : String) -> bool:
		return true

class NoBreakLineBreak extends ILineBreak:
	func _is_link(_left : String,_right : String) -> bool:
		return true

class JapaneaseLineBreak extends ILineBreak:
	var force_break := " \t\r\n　@*|/";
	var force_link1 := "([{\"'<‘“（〔［｛〈《「『【";
	var force_link2 := ",.;:)]}\"'>、。，．’”）〕］｝〉》」』】";
	var not_begin := "・：；？！ヽヾゝゞ〃々ー―～…‥っゃゅょッャュョぁぃぅぇぉァィゥェォ";
	var next_break1 := ")]};>!%&?";
	var num_link_next_break1 := ".,-:$\\";
	var prev_break2 := "([{<";

	func _is_link(left : String,right : String) -> bool:
		var code1 := left.unicode_at(left.length() - 1)
		var code2 := right.unicode_at(0)
		var char1 = char(code1)
		var char2 = char(code2)
		if char1 in force_break or char2 in force_break:
			return false
		if char1 in force_link1 or char2 in force_link2:
			return true

		if code1 <= 0x7F:
			if char1 in next_break1:
				return false
			if char2 in prev_break2:
				return false
			if char1 in num_link_next_break1:
				if "0".unicode_at(0) <= code2 and code2 <= "9".unicode_at(0):
					return true
				else:
					return false

			if code2 <= 0x7F:
				return true
			return false

		if char2 in not_begin:
			return true

		return false

