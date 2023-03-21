extends Control


var settings : Settings
var finders : ImageFinders

@onready var item_list := %ItemList
@onready var insert_b_popup : PopupMenu = %MenuButtonInsertB.get_popup()


func _set_config_plug_in():
	settings.config.set_value("Image","Finder_plug_in",finders.serialize())
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(settings_ : Settings,finders_ : ImageFinders):
	settings = settings_
	finders = finders_
	
	insert_b_popup.add_item(ImageFinders.COMMAND_IF_NOT_EMPTY_END_FIND)
	insert_b_popup.add_item(ImageFinders.COMMAND_END_FIND)
	insert_b_popup.add_item(ImageFinders.BUILTIN_FILE_PATH_FINDER)
	insert_b_popup.add_item(ImageFinders.BUILTIN_SPOTIFY_IMAGE_FINDER)
	
	insert_b_popup.index_pressed.connect(func (index : int):
			var builtin := insert_b_popup.get_item_text(index)
			var plugin := ImageFinders.Plugin.create(builtin)
			item_list.add_item(plugin.finder._get_name())
			finders.plugins.append(plugin)
			item_list.select(item_list.item_count - 1)
			_set_config_plug_in()
	)
	
	item_list.clear()
	for p in finders.plugins:
		var plugin := p as ImageFinders.Plugin
		item_list.add_item(plugin.finder._get_name())
#		item_list.set_item_tooltip()
			


func on_files_dropped(files : PackedStringArray):
	var file_path = files[0]
	if file_path.get_extension() == "gd":
		var plugin = ImageFinders.Plugin.create(file_path)
		if plugin:
			finders.plugins.append(plugin)
			item_list.add_item(plugin.finder._get_name())
			item_list.select(item_list.item_count - 1)
			_set_config_plug_in()


func _on_button_insert_plugin_pressed():
	$FileDialog.popup_centered(Vector2i(600,400))
	pass # Replace with function body.


func _on_file_dialog_file_selected(path : String):
	var plugin = ImageFinders.Plugin.create(path)
	if plugin:
		finders.plugins.append(plugin)
		item_list.add_item(plugin.finder._get_name())
		item_list.select(item_list.item_count - 1)
		_set_config_plug_in()


func _on_button_delete_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		item_list.remove_item(index)
		finders.plugins.remove_at(index)
		_set_config_plug_in()

func _on_button_up_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if index > 0:
			item_list.move_item(index,index-1)
			var tmp = finders.plugins[index]
			finders.plugins[index] = finders.plugins[index-1]
			finders.plugins[index-1] = tmp
			_set_config_plug_in()


func _on_button_down_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if index < item_list.item_count - 1:
			item_list.move_item(index,index+1)
			var tmp = finders.plugins[index]
			finders.plugins[index] = finders.plugins[index+1]
			finders.plugins[index+1] = tmp
			_set_config_plug_in()

