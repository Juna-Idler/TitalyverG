extends Control


var settings : Settings
var finders : LyricsFinders

@onready var item_list := %ItemList
@onready var insert_b_popup : PopupMenu = %MenuButtonInsertB.get_popup()



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(settings_ : Settings,finders_ : LyricsFinders):
	settings = settings_
	finders = finders_
	
	insert_b_popup.add_item(LyricsFinders.COMMAND_IF_NOT_EMPTY_END_FIND)
	insert_b_popup.add_item(LyricsFinders.DEFAULT_LYRICS_FILE_FINDER)
	insert_b_popup.add_item(LyricsFinders.DEFAULT_NOT_FOUND_FINDER)
	insert_b_popup.index_pressed.connect(func (index : int):
			var builtin := insert_b_popup.get_item_text(index)
			item_list.add_item(builtin)
			finders.plugins.append(LyricsFinders.Plugin.create(builtin))
			item_list.select(item_list.item_count - 1)
			settings.config.set_value("Finder","plug_in",finders.serialize())
	)
	
	item_list.clear()
	for p in finders.plugins:
		var plugin := p as LyricsFinders.Plugin
		if plugin.file_path.is_absolute_path():
			item_list.add_item(plugin.file_path.get_file())
		else:
			item_list.add_item(plugin.file_path)
			


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func on_files_dropped(files : PackedStringArray):
	var file_path = files[0]
	if file_path.get_extension() == "gd":
		var plugin = LyricsFinders.Plugin.create(file_path)
		if plugin:
			finders.plugins.append(plugin)
			item_list.add_item(plugin.file_path.get_file())
			item_list.select(item_list.item_count - 1)
			settings.config.set_value("Finder","plug_in",finders.serialize())


func _on_button_insert_plugin_pressed():
	$FileDialog.popup_centered(Vector2i(600,400))
	pass # Replace with function body.


func _on_file_dialog_file_selected(path : String):
	var plugin = LyricsFinders.Plugin.create(path)
	if plugin:
		finders.plugins.append(plugin)
		item_list.add_item(plugin.file_path.get_file())
		item_list.select(item_list.item_count - 1)
		settings.config.set_value("Finder","plug_in",finders.serialize())


func _on_button_delete_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		item_list.remove_item(index)
		settings.config.set_value("Finder","plug_in",finders.serialize())

func _on_button_up_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if index > 0:
			item_list.move_item(index,index-1)
			var tmp = finders.plugins[index]
			finders.plugins[index] = finders.plugins[index-1]
			finders.plugins[index-1] = tmp
			settings.config.set_value("Finder","plug_in",finders.serialize())


func _on_button_down_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if index < item_list.item_count - 1:
			item_list.move_item(index,index+1)
			var tmp = finders.plugins[index]
			finders.plugins[index] = finders.plugins[index+1]
			finders.plugins[index+1] = tmp
			settings.config.set_value("Finder","plug_in",finders.serialize())

