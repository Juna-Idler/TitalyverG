extends Control

var settings : Settings
var receiver_manager : ReceiverManager

@onready var item_list := %ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func initialize(settings_ : Settings,receiver : ReceiverManager):
	settings = settings_
	receiver_manager = receiver
	
	for i in ReceiverManager.RECEIVERS.keys().size():
		var key : String = ReceiverManager.RECEIVERS.keys()[i]
		item_list.add_item(key)
		if key == receiver_manager.get_current_receiver_name():
			item_list.select(i)
			$VBoxContainer/Label.text = "now receiver : " + key
			
	var s := receiver_manager.get_receiver()._get_settings(settings.config)
	if s:
		%SettingContainer.add_child(s)



func _on_button_change_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		var receiver_name : String = item_list.get_item_text(index)
		if receiver_manager.change_receiver(receiver_name):
			$VBoxContainer/Label.text = "now receiver : " + receiver_name
			settings.config.set_value("Receiver","receiver",receiver_name)
			if %SettingContainer.get_child_count() == 1:
				var child = %SettingContainer.get_child(0)
				%SettingContainer.remove_child(child)
				child.free()
			var s := receiver_manager.get_receiver()._get_settings(settings.config)
			if s:
				%SettingContainer.add_child(s)

