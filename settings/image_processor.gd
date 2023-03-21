extends Control

var settings : Settings
var image_manager : ImageManager

@onready var item_list := %ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _set_config_plug_in():
	settings.config.set_value("Image","Processor_plug_in",image_manager.serialize_processors())

func initialize(settings_ : Settings,manager : ImageManager):
	settings = settings_
	image_manager = manager
	
	var processor_name := image_manager.get_processor()._get_name()
	$VBoxContainer/Label.text = "now processor : " + processor_name
	
	for i in image_manager.plugins.size():
		var n : String = image_manager.plugins[i].processor._get_name()
		item_list.add_item(n)
		if n == processor_name:
			item_list.select(i)
	
	var s := image_manager.get_processor()._get_settings(settings.config)
	if s:
		%SettingContainer.add_child(s)



func _on_button_change_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if image_manager.change_processor(index):
			var processor_name := image_manager.get_processor()._get_name()
			$VBoxContainer/Label.text = "now processor : " + processor_name
			settings.config.set_value("Image","processor",processor_name)
			if %SettingContainer.get_child_count() == 1:
				var child = %SettingContainer.get_child(0)
				%SettingContainer.remove_child(child)
				child.free()
			var s := image_manager.get_processor()._get_settings(settings.config)
			if s:
				%SettingContainer.add_child(s)


func _on_button_insert_plugin_pressed():
	$FileDialog.popup_centered(Vector2i(600,400))

func _on_file_dialog_file_selected(path):
	var plugin := ImageManager.Plugin.create(path)
	if plugin:
		image_manager.plugins.append(plugin)
		item_list.add_item(plugin.processor._get_name())
		item_list.select(item_list.item_count - 1)
		_set_config_plug_in()

func _on_button_delete_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		if image_manager.plugins[index].file_path.begins_with("[Built-in]"):
			return
		item_list.remove_item(index)
		image_manager.plugins.remove_at(index)
		_set_config_plug_in()
