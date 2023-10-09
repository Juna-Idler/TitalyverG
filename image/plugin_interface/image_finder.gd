
class_name I_ImageFinder

 # _find()の返り値がnullでない場合、_get_result()が有効になったことを知らせる
 # _find()の返り値がnullの場合、emitされない
signal finished()


func _initialize(_script_path : String) -> bool:
	return true

func _get_name() -> String:
	return ""

func _find(_title : String,_artists : PackedStringArray,_album : String,
		_file_path : String,_meta : Dictionary) -> Node:
	return null

func _get_result() -> Array[Image]: # of Image
	return []
