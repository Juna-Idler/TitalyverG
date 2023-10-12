extends TabContainer

class_name RubyLyricsViewSettings


func initialize(config : ConfigFile,view : RubyLyricsView):
	$Display.initialize(config,view)
	$Unsync.initialize(config,view)


