extends Control


@export_multiline var input : String


var settings := Settings.new()


@onready var ruby_lyrics_view : RubyLyricsView = $RubyLyricsView

@onready var popup_menu = $PopupMenu
const MENU_ID_SETTINGS := 0
const MENU_ID_ALWAYS_ON_TOP := 1
const MENU_ID_SAVE := 2
const MENU_ID_LOAD := 3

@onready var receiver : ReceiverManager = $receiver_manager

var finders := LyricsFinders.new()
var savers := LyricsSavers.new()
var loaders := LyricsLoaders.new()

var source_texts : PackedStringArray
var source_text_index : int
var lyrics := LyricsContainer.new("")

var playback_data : PlaybackData = PlaybackData.new(false,0,0,0,"","",[],"",0,{})

var playing : bool = false

var time_offset : float = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().transparent_bg = true
	get_viewport().gui_embed_subwindows = false
	get_window().files_dropped.connect(on_files_dropped)

	popup_menu.add_item("Settings",MENU_ID_SETTINGS)
	popup_menu.add_separator("",100)
	popup_menu.add_check_item("Always on Top",MENU_ID_ALWAYS_ON_TOP)
	popup_menu.add_separator("",101)
	popup_menu.add_item("Save",MENU_ID_SAVE)
	popup_menu.set_item_submenu(popup_menu.get_item_index(MENU_ID_SAVE),"PopupMenuSave")
	popup_menu.add_item("Load",MENU_ID_LOAD)
	popup_menu.set_item_submenu(popup_menu.get_item_index(MENU_ID_LOAD),"PopupMenuLoad")
	
	settings.load_settings()
	
	settings.initialize_receiver_settings(receiver)
	
	$ColorRect.color = settings.get_background_color()
	settings.initialize_ruby_lyrics_view_settings(ruby_lyrics_view)
	settings.initialize_finders_settings(finders)
	settings.initialize_saver_settings(savers,$PopupMenu/PopupMenuSave)
	settings.initialize_loader_settings(loaders,$PopupMenu/PopupMenuLoad)
	
	reset_lyrics([input],0)

	%SettingsWindow.initialize(
			settings,ruby_lyrics_view,finders,
			savers,$PopupMenu/PopupMenuSave,
			loaders,$PopupMenu/PopupMenuLoad,
			receiver)


func _process(delta):
	ruby_lyrics_view.set_time_and_target_y(
			ruby_lyrics_view.time + (delta if playing else 0))


func _on_button_pressed():
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func on_files_dropped(files : PackedStringArray):
	var drop_texts : PackedStringArray = []
	for f in files:
		var file := FileAccess.open(f,FileAccess.READ)
		if file:
			drop_texts.append(file.get_as_text())
	if not drop_texts.is_empty():
		var index = source_texts.size()
		add_lyrics(drop_texts)
		change_lyrics_source(index)
		

func _on_window_ui_right_clicked(position_):
	var pos := Vector2(DisplayServer.window_get_position())
	popup_menu.popup(Rect2(pos + position_,Vector2.ZERO))


func _on_window_ui_wheel_moved(delta):
	ruby_lyrics_view.user_y_offset += delta * 30

func _on_window_ui_scroll_pad_dragging(delta):
	ruby_lyrics_view.user_y_offset += delta * ruby_lyrics_view.layout_height / ruby_lyrics_view.size.y

func _on_window_ui_middle_clicked():
	ruby_lyrics_view.user_y_offset = 0


func _on_popup_menu_id_pressed(id):
	match id:
		MENU_ID_SETTINGS: #Settings
			%SettingsWindow.hide()
			var rect := Rect2i((size - Vector2(%SettingsWindow.size))/2,%SettingsWindow.size)
			%SettingsWindow.popup_on_parent(rect)
		MENU_ID_ALWAYS_ON_TOP:
			var always = not get_window().always_on_top
			get_window().always_on_top = always
			var idx = popup_menu.get_item_index(MENU_ID_ALWAYS_ON_TOP)
			popup_menu.set_item_checked(idx,always)
			popup_menu.always_on_top = always
			%SettingsWindow.always_on_top = always
#			$PopupMenu/PopupMenuSave.always_on_top = always


func _on_popup_menu_save_index_pressed(index):
	var msg :String= savers.plugins[index].saver._save(playback_data.title,playback_data.artists,
			playback_data.album,playback_data.file_path,playback_data.meta_data,
			source_texts,source_text_index)
	if not msg.is_empty():
		$Notice.text = "Save result\n" + msg
		$Notice.show()

var display_loader : ILyricsLoader
func _on_popup_menu_load_index_pressed(index):
	var loader : ILyricsLoader = loaders.plugins[index].loader
	
	var window := $LoaderWindow
	if not loader.loaded.is_connected(_on_loader_loaded):
		loader.loaded.connect(_on_loader_loaded)
	
	var control = loader._open(playback_data.title,playback_data.artists,
			playback_data.album,playback_data.file_path,playback_data.meta_data)
	if control:
		for c in window.get_children():
			window.remove_child(c)
		window.add_child(control)
		window.title = loader._get_name()
		var rect := Rect2i((size - Vector2(control.size))/2,control.size)
		window.popup_on_parent(rect)
		display_loader = loader
	else:
		display_loader = null

func _on_loader_loaded(lyrics_ : PackedStringArray,msg : String):
	if not lyrics_.is_empty():
		add_lyrics(lyrics_,true)
	if not msg.is_empty():
		$Notice.text = "Load result\n" + msg
		$Notice.show()
	$LoaderWindow.hide()
	display_loader = null

func _on_loader_window_close_requested():
	$LoaderWindow.hide()
	if display_loader:
		display_loader._close()
		display_loader = null


func _on_resized():
	pass

func _on_receiver_received(data : PlaybackData):
	if data.playback_event & PlaybackData.PlaybackEvent.PLAY_FLAG:
		playing = true
	else:
		playing = false;

	if data.playback_only or playback_data.same_song(data):
		if data.playback_event & PlaybackData.PlaybackEvent.SEEK_FLAG:
			var msec := int(Time.get_unix_time_from_system() * 1000) % (24*60*60*1000)
			var time : float = data.seek_time + float(msec - data.time_of_day) / 1000.0 - lyrics.at_tag_container.offset
			ruby_lyrics_view.set_time_and_target_y(time + time_offset - lyrics.at_tag_container.offset)
		return
	playback_data = data
	
	ruby_lyrics_view.song_duration = data.duration

	var first := true
	var it := finders.get_iterator()
	while not it.is_end():
		var find := Callable(it.find).bind(data.title,data.artists,data.album,data.file_path,data.meta_data)
		var thread := Thread.new()
		thread.start(find)
		while thread.is_alive():
			await get_tree().create_timer(0.5).timeout
		var result : PackedStringArray = thread.wait_to_finish()
#		var result := it.find(data.title,data.artists,data.album,data.file_path,data.meta_data)
		if not result.is_empty():
			if first:
				var msec := int(Time.get_unix_time_from_system() * 1000) % (24*60*60*1000)
				var time : float = data.seek_time + float(msec - data.time_of_day) / 1000.0
				reset_lyrics(result,time)
				first = false
			else:
				add_lyrics(result)


func _on_button_prev_pressed():
	var index = source_text_index - 1
	if index < 0:
		index = source_texts.size() - 1
	change_lyrics_source(index)
	$LyricsCount/ButtonPrev.release_focus()

func _on_button_next_pressed():
	var index = source_text_index + 1
	if index >= source_texts.size():
		index = 0
	change_lyrics_source(index)
	$LyricsCount/ButtonNext.release_focus()


func reset_lyrics(lyrics_source : PackedStringArray,time_ : float):
	ruby_lyrics_view.user_y_offset = 0
	source_texts = lyrics_source.duplicate()
	source_text_index = 0
	lyrics = LyricsContainer.new(source_texts[0])
	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.build()
	ruby_lyrics_view.set_time_and_target_y(time_ + time_offset + lyrics.at_tag_container.offset)
	if source_texts.size() <= 1:
		$LyricsCount.hide()
	else:
		$LyricsCount.show()
		$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]

func add_lyrics(lyrics_source : PackedStringArray,change : bool = false):
	if lyrics_source.is_empty():
		return
	var index := source_texts.size()
	source_texts.append_array(lyrics_source)
	$LyricsCount.show()
	if change:
		change_lyrics_source(index)
	else:
		$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]

func change_lyrics_source(index : int):
	if source_texts.size() <= 1:
		return
	var old_offset := lyrics.at_tag_container.offset
	source_text_index = index
	lyrics = LyricsContainer.new(source_texts[source_text_index])
	ruby_lyrics_view.lyrics = lyrics
	ruby_lyrics_view.user_y_offset = 0
	ruby_lyrics_view.build()
	ruby_lyrics_view.set_time_and_target_y(ruby_lyrics_view.time
			- old_offset + lyrics.at_tag_container.offset)
	$LyricsCount.text = "<%d/%d>" % [source_text_index + 1,source_texts.size()]


func _on_settings_display_background_color_changed(color):
	$ColorRect.color = color


func _on_notice_gui_input(event):
	if (event is InputEventMouseButton and not event.pressed):
		$Notice.hide()


func _on_button_offset_toggled(button_pressed):
	$HSlider.visible = button_pressed

func _on_h_slider_value_changed(value):
	ruby_lyrics_view.time -= time_offset
	time_offset = value / 100.0
	ruby_lyrics_view.time += time_offset

func _on_h_slider_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				$HSlider.value = 0
#				ruby_lyrics_view.time -= time_offset
#				time_offset = 0
				accept_event()

