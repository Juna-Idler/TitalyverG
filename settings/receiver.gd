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
	
	var i := 0
	for k in ReceiverManager.RECEIVERS.keys():
		item_list.add_item(k)
		if k == receiver_manager.get_current_receiver_name():
			item_list.select(i)
			$VBoxContainer/Label.text = "now receiver : " + k
			$VBoxContainer/TabContainer.current_tab = i
		i += 1


func _on_button_change_pressed():
	var selected : PackedInt32Array = item_list.get_selected_items()
	if selected.size() == 1:
		var index : int = selected[0]
		item_list.get_item_text(index)
		if receiver_manager.change_receiver(item_list.get_item_text(index)):
			$VBoxContainer/Label.text = "now receiver : " + item_list.get_item_text(index)



func _on_item_list_item_selected(index):
	$VBoxContainer/TabContainer.current_tab = index

