
extends Node

class_name ReceiverManager

signal received(data : PlaybackData)


const RECEIVERS : Dictionary = {
	"WebSocket":preload("res://receiver/websocket/receiver.tscn"),
	"Spotify":preload("res://receiver/spotify/receiver.tscn"),
}

var _receiver : I_Receiver

var _receiver_name : String

@onready var receiver_window = $"../ReceiverWindow"

var receiver_menu_disabled_setter : Callable

func get_receiver() -> I_Receiver:
	return _receiver
	
func get_current_receiver_name() -> String:
	return _receiver_name

func change_receiver(receiver_name : String) -> bool:
	if not RECEIVERS.has(receiver_name):
		return false
	
	if _receiver:
		if receiver_window.get_child_count() == 1:
			var child := receiver_window.get_child(0)
			receiver_window.remove_child(child)
			child.queue_free()
		remove_child(_receiver)
		_receiver.queue_free()
	
	_receiver = RECEIVERS[receiver_name].instantiate()
	add_child(_receiver)
	_receiver.received.connect(_on_receiver_received)
	_receiver_name = receiver_name
	var controler := _receiver._get_controler()
	if controler:
		receiver_window.add_child(controler)
		receiver_menu_disabled_setter.call(false)
	else:
		receiver_window.hide()
		receiver_menu_disabled_setter.call(true)
	return true

func _on_receiver_received(data : PlaybackData):
	received.emit(data)

