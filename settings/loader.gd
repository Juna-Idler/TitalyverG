extends Control


var settings : Settings
var loaders : LyricsLoaders
var menu : PopupMenu

@onready var item_list := %ItemList
@onready var insert_b_popup : PopupMenu = %MenuButtonInsertB.get_popup()


func _ready():
	pass # Replace with function body.

func initialize(settings_ : Settings,loaders_ : LyricsLoaders,menu_ : PopupMenu):
	settings = settings_
	loaders = loaders_
	menu = menu_
	
#	insert_b_popup.add_item(LyricsSavers.BUILTIN_LYRICS_FILE_SAVER)
	insert_b_popup.index_pressed.connect(func (index : int):
			var builtin := insert_b_popup.get_item_text(index)
			var plugin := LyricsSavers.Plugin.create(builtin)
			item_list.add_item(plugin.saver._get_name())
			loaders.plugins.append(plugin)
			item_list.select(item_list.item_count - 1)
			settings.config.set_value("Loader","plug_in",loaders.serialize())
			menu.add_item(plugin.loader._get_name())
	)
	
	item_list.clear()
	for p in loaders.plugins:
		var plugin := p as LyricsLoaders.Plugin
		item_list.add_item(plugin.loader._get_name())
#		item_list.set_item_tooltip()
	


func on_files_dropped(files : PackedStringArray):
	var file_path = files[0]
	if file_path.get_extension() == "gd":
		var plugin := LyricsLoaders.Plugin.create(file_path)
		if plugin:
			loaders.plugins.append(plugin)
			item_list.add_item(plugin.loader._get_name())
			item_list.select(item_list.item_count - 1)
			settings.config.set_value("Loader","plug_in",loaders.serialize())
			menu.add_item(plugin.loader._get_name())


func _on_button_insert_plugin_pressed():
	$FileDialog.popup_centered(Vector2i(600,400))
	pass # Replace with function body.


func _on_file_dialog_file_selected(path : String):
	var plugin := LyricsLoaders.Plugin.create(path)
	if plugin:
		loaders.plugins.append(plugin)
		item_list.add_item(plugin.loader._get_name())
		item_list.select(item_list.item_count - 1)
		settings.config.set_value("Loader","plug_in",loaders.serialize())
		menu.add_item(plugin.loader._get_name())
		

func _on_button_delete_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		item_list.remove_item(index)
		loaders.plugins.remove_at(index)
		settings.config.set_value("Loader","plug_in",loaders.serialize())
		menu.remove_item(index)

func _on_button_up_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if index > 0:
			item_list.move_item(index,index-1)
			var tmp = loaders.plugins[index]
			loaders.plugins[index] = loaders.plugins[index-1]
			loaders.plugins[index-1] = tmp
			settings.config.set_value("Loader","plug_in",loaders.serialize())
			menu.clear()
			for p in loaders.plugins:
				menu.add_item(p.loader._get_name())


func _on_button_down_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if index < item_list.item_count - 1:
			item_list.move_item(index,index+1)
			var tmp = loaders.plugins[index]
			loaders.plugins[index] = loaders.plugins[index+1]
			loaders.plugins[index+1] = tmp
			settings.config.set_value("Loader","plug_in",loaders.serialize())
			menu.clear()
			for p in loaders.plugins:
				menu.add_item(p.loader._get_name())

