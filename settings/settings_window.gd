extends Window

class_name SettingsWindow


var settings : Settings

# Called when the node enters the scene tree for the first time.
func _ready():
#	%LineEditDirectory.text = ProjectSettings.globalize_path("user://")
	%LineEditDirectory.text = OS.get_user_data_dir()


func get_settings() -> Settings:
	return settings

func get_viewer_parent() -> Control:
	return %Viewer.get_node("VBoxContainer/ViewerContainer")

func initialize(settings_ : Settings,
		viewer : LyricsViewerManager,
		finders : LyricsFinders,
		savers : LyricsSavers,save_menu : PopupMenu,
		loaders : LyricsLoaders,load_menu : PopupMenu,
		image_manager : ImageManager,
		receiver : ReceiverManager):
	settings = settings_
	%Viewer.initialize(settings,viewer)
	%Finder.initialize(settings,finders)
	%Saver.initialize(settings,savers,save_menu)
	%Loader.initialize(settings,loaders,load_menu)
	
	%Receiver.initialize(settings,receiver)
	
	%ImageProcessor.initialize(settings,image_manager)
	%ImageFinder.initialize(settings,image_manager.finders)


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

