extends Control


var timer : Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	%Label.text = "wait %.3f sec" % timer.time_left
