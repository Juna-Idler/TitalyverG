extends Control


signal right_clicked(position : Vector2)
signal wheel_moved(delta : int)
signal scroll_pad_dragging(delta : int)


func _ready():
	pass # Replace with function body.

enum SizingDirection {NONE,TOP_LEFT,TOP,TOP_RIGHT,LEFT,RIGHT,BOTTOM_LEFT,BOTTOM,BOTTOM_RIGHT}

var sizing_direction : SizingDirection = SizingDirection.NONE
var pointer_position := Vector2i.ZERO

var _dragging := false
var _scroll_pad_dragging := false

func _on_gui_input(event : InputEvent):
	if event is InputEventMouseMotion and _dragging:
		var pos := DisplayServer.window_get_position()
		var move = pointer_position != pos + Vector2i(event.global_position)
		if move:
			var r := Vector2i(event.global_position) + pos - pointer_position
			pointer_position = Vector2i(event.global_position) + pos
			pos += r
			DisplayServer.window_set_position(pos)	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				var delta = int(event.button_index == MOUSE_BUTTON_WHEEL_UP) - int(event.button_index == MOUSE_BUTTON_WHEEL_DOWN)
				wheel_moved.emit(delta)
		else:
			_dragging = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if not event.pressed:
					right_clicked.emit(event.global_position)
			elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_dragging = true
				pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
	accept_event()




func _on_top_left_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position != pos + Vector2i(event.global_position)
		if sizing_direction == SizingDirection.TOP_LEFT and move:
			var r := Vector2i(event.global_position) + pos - pointer_position
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size -= r
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
			pos += r
			DisplayServer.window_set_position(pos)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.TOP_LEFT
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()

func _on_top_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position.y != int(pos.y + event.global_position.y)
		if sizing_direction == SizingDirection.TOP and move:
			var r : int = event.global_position.y + pos.y - pointer_position.y
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size.y -= r
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
			pos.y += r
			DisplayServer.window_set_position(pos)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.TOP
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()

func _on_top_right_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position != pos + Vector2i(event.global_position)
		if sizing_direction == SizingDirection.TOP_RIGHT and move:
			var r := Vector2i(event.global_position) + pos - pointer_position
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size.x += r.x
			win_size.y -= r.y
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
			pos.y += r.y
			DisplayServer.window_set_position(pos)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.TOP_RIGHT
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()

func _on_left_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position.x != int(pos.x + event.global_position.x)
		if sizing_direction == SizingDirection.LEFT and move:
			var r : int = event.global_position.x + pos.x - pointer_position.x
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size.x -= r
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
			pos.x += r
			DisplayServer.window_set_position(pos)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.LEFT
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()

func _on_right_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position.x != int(pos.x + event.global_position.x)
		if sizing_direction == SizingDirection.RIGHT and move:
			var r : int = pointer_position.x - (event.global_position.x + pos.x)
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size.x -= r
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.RIGHT
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()


func _on_bottom_left_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position != pos + Vector2i(event.global_position)
		if sizing_direction == SizingDirection.BOTTOM_LEFT and move:
			var r := Vector2i(event.global_position) + pos - pointer_position
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size.x -= r.x
			win_size.y += r.y
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
			pos.x += r.x
			DisplayServer.window_set_position(pos)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.BOTTOM_LEFT
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()

func _on_bottom_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position.y != int(pos.y + event.global_position.y)
		if sizing_direction == SizingDirection.RIGHT and move:
			var r : int = pointer_position.y - (event.global_position.y + pos.y)
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size.y -= r
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.RIGHT
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()
	

func _on_bottom_right_gui_input(event):
	if event is InputEventMouseMotion:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position != pos + Vector2i(event.global_position)
		if sizing_direction == SizingDirection.BOTTOM_RIGHT and move:
			var r := Vector2i(event.global_position) + pos - pointer_position
			pointer_position = Vector2i(event.global_position) + pos
			var win_size = DisplayServer.window_get_size()
			win_size += r
			DisplayServer.window_set_size(win_size)
			get_viewport().size = win_size
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sizing_direction = SizingDirection.BOTTOM_RIGHT
			pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
		else:
			sizing_direction = SizingDirection.NONE
	accept_event()


func _on_scroll_pad_gui_input(event):
	if event is InputEventMouseMotion and _scroll_pad_dragging:
		var pos := DisplayServer.window_get_position()
		var move := pointer_position != pos + Vector2i(event.global_position)
		if move:
			var r := Vector2i(event.global_position) + pos - pointer_position
			pointer_position = Vector2i(event.global_position) + pos
			scroll_pad_dragging.emit(-r.y)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				var delta = int(event.button_index == MOUSE_BUTTON_WHEEL_UP) - int(event.button_index == MOUSE_BUTTON_WHEEL_DOWN)
				wheel_moved.emit(delta)
		else:
			_scroll_pad_dragging = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if not event.pressed:
					right_clicked.emit(event.global_position)
			elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_scroll_pad_dragging = true
				pointer_position = Vector2i(event.global_position) + DisplayServer.window_get_position()
	accept_event()
