extends MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func on_files_dropped(files : PackedStringArray):
	var file_path = files[0]
	if file_path.get_extension() == "gd":
		var plugin = load(file_path)
		if plugin is ILyricsFinder:
			
