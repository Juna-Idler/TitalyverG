extends Control


@export_multiline var input : String



# Called when the node enters the scene tree for the first time.
func _ready():

	var str = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	print(str)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
