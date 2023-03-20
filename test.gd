extends Control

var Ncr := preload("res://plugins/named_character_references.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	print(Ncr.TABLE["&omega;"]["characters"])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
