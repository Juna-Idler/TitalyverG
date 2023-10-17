
class_name Settings

const CONFIG_FILE_PATH := "user://settings.cfg"

var config : ConfigFile = ConfigFile.new()


func load_settings() -> bool:
	if config.load(CONFIG_FILE_PATH) != OK:
		return false
	return true

func save_settings():
	config.save(CONFIG_FILE_PATH)
	
func initialize_receiver_settings(receiver : ReceiverManager):
	var receiver_name : String = config.get_value("Receiver","receiver",ReceiverManager.RECEIVERS.keys()[0])
	receiver.change_receiver(receiver_name)

func initialize_image_settings(image_manager : ImageManager):
	image_manager.set_bg_color(config.get_value("Window","background_color",Color(0,0,0,0.8)))
	
	var plugins = config.get_value("Image","Finder_plug_in",[])
	if plugins.is_empty():
		image_manager.finders.plugins.append(ImageFinders.Plugin.create(ImageFinders.BUILTIN_FILE_PATH_FINDER))
		image_manager.finders.plugins.append(ImageFinders.Plugin.create(ImageFinders.BUILTIN_SPOTIFY_IMAGE_FINDER))
	else:
		image_manager.finders.deserialize(plugins)
		#正常に読めたもののみ書き戻す
		config.set_value("Image","Finder_plug_in",image_manager.finders.serialize())

	plugins = config.get_value("Image","Processor_plug_in",[])
	if plugins.is_empty():
		image_manager.plugins.append(ImageManager.Plugin.create(ImageManager.BUILTIN_NO_IMAGE_PROCESSOR))
		image_manager.plugins.append(ImageManager.Plugin.create(ImageManager.BUILTIN_DEFAULT_IMAGE_PROCESSOR))
	else:
		image_manager.deserialize_processors(plugins)
		#正常に読めたもののみ書き戻す
		config.set_value("Image","Processor_plug_in",image_manager.serialize_processors())
	
	image_manager.set_processor(config.get_value("Image","processor",""))

func initialize_viewer_settings(viewer : LyricsViewerManager):
	viewer.initialize_unsync_viewer(config)
	var viewer_name : String = config.get_value("LyricsViewer","viewer",LyricsViewerManager.VIEWERS.keys()[0])
	if not viewer.change_sync_viewer(viewer_name,config):
		viewer.change_sync_viewer(LyricsViewerManager.VIEWERS.keys()[0],config)
		


func initialize_finders_settings(finders : LyricsFinders):
	var plugins = config.get_value("Finder","plug_in",[])
	if plugins.is_empty():
		finders.plugins.append(LyricsFinders.Plugin.create(LyricsFinders.DEFAULT_LYRICS_FILE_FINDER))
		finders.plugins.append(LyricsFinders.Plugin.create(LyricsFinders.COMMAND_IF_NOT_EMPTY_END_FIND))
		finders.plugins.append(LyricsFinders.Plugin.create(LyricsFinders.DEFAULT_NOT_FOUND_FINDER))
	else:
		finders.deserialize(plugins)
		#正常に読めたもののみ書き戻す
		config.set_value("Finder","plug_in",finders.serialize())

func initialize_saver_settings(saver : LyricsSavers,menu : PopupMenu):
	var plugins = config.get_value("Saver","plug_in",[])
	if plugins.is_empty():
		saver.plugins.append(LyricsSavers.Plugin.create(LyricsSavers.BUILTIN_LYRICS_FILE_SAVER))
		saver.plugins.append(LyricsSavers.Plugin.create(LyricsSavers.BUILTIN_LYRICS_FILE_SAVER_OVERWRITE))
		saver.plugins.append(LyricsSavers.Plugin.create(LyricsSavers.BUILTIN_LYRICS_TEXT_SHELL_OPENER))
	else:
		saver.deserialize(plugins)
		config.set_value("Saver","plug_in",saver.serialize())
		
	for p in saver.plugins:
		menu.add_item(p.saver._get_name())

func initialize_loader_settings(loader : LyricsLoaders,menu : PopupMenu):
	var plugins = config.get_value("Loader","plug_in",[])
	if plugins.is_empty():
#		loader.plugins.append()
		pass
	else:
		loader.deserialize(plugins)
		config.set_value("Loader","plug_in",loader.serialize())
	
	for p in loader.plugins:
		menu.add_item(p.loader._get_name())
	


