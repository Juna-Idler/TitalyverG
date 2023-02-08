extends Window

var settings : Settings

# Called when the node enters the scene tree for the first time.
func _ready():
#	%LineEditDirectory.text = ProjectSettings.globalize_path("user://")
	%LineEditDirectory.text = OS.get_user_data_dir()
	

func initialize(settings_ : Settings,ruby_lyrics_view : RubyLyricsView,
		finders : LyricsFinders,savers : LyricsSavers,save_menu : PopupMenu):
	settings = settings_
	%Display.initialize(settings,ruby_lyrics_view)
	%Finder.initialize(settings,finders)
	%Unsync.initialize(settings,ruby_lyrics_view)
	%Saver.initialize(settings,savers,save_menu)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_about_to_popup():
	pass # Replace with function body.

func _on_close_requested():
	hide()
	pass # Replace with function body.


func _on_files_dropped(files):
	if %TabContainer.get_current_tab_control() == %Finder:
		%Finder.on_files_dropped(files)


func _on_button_save_pressed():
	settings.save_settings()


func _on_label_path_pressed():
	OS.shell_open(OS.get_user_data_dir())

