extends Control


var settings : Settings
var savers : LyricsSavers
var menu : PopupMenu




func _ready():
	pass # Replace with function body.

func initialize(settings_ : Settings,savers_ : LyricsSavers,menu_ : PopupMenu):
	settings = settings_
	savers = savers_
	menu = menu_

