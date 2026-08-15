extends Node

const CONFIG_PATH: String = "user://config.cfg"
signal config_updated(config_name: String)

var _is_loading_config: bool = false

# 常规

var language: String = "auto":
	set(v):
		language = v
		if _is_loading_config:
			return
		_set_language()
		store_config.call_deferred()
		config_updated.emit("language")

var architecture: String = "auto":
	set(v):
		architecture = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("architecture")

var delete_download_file: bool = false:
	set(v):
		delete_download_file = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("delete_download_file")

var external_editor_path: String = "":
	set(v):
		external_editor_path = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("external_editor_path")

var hide_path: bool = false:
	set(v):
		hide_path = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("hide_path")

var remote_source: bool = false:
	set(v):
		remote_source = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("remote_source")

# 编译

var mingw_prefix: String = "": # MINGW_PREFIX
	set(v):
		mingw_prefix = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("mingw_prefix")

var java_home: String = "": # JAVA_HOME
	set(v):
		java_home = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("java_home")

var android_home: String = "": # ANDROID_HOME
	set(v):
		android_home = v
		if _is_loading_config:
			return
		store_config.call_deferred()
		config_updated.emit("android_home")

func _ready() -> void:
	load_config()

func _exit_tree() -> void:
	store_config()

func _set_language() -> void:
	if language == "auto":
		# 自动则根据系统语言设置
		var lang: PackedStringArray = OS.get_locale().split("_")
		if lang.size() < 1:
			TranslationServer.set_locale("en")
		else:
			match lang[0]:
				"zh":
					if lang.size() > 1:
						match lang[1]:
							"HK", "MO", "TW": # 港澳台使用繁体中文
								TranslationServer.set_locale("zh_HK")
							_:
								TranslationServer.set_locale("zh_CN")
					else:
						TranslationServer.set_locale("zh_CN")
				_:
					TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale(language)

func store_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("general", "language", language)
	config.set_value("general", "architecture", architecture)
	config.set_value("general", "delete_download_file", delete_download_file)
	config.set_value("general", "external_editor_path", external_editor_path)
	config.set_value("general", "hide_path", hide_path)
	config.set_value("general", "remote_source", remote_source)
	config.set_value("compile", "mingw_prefix", mingw_prefix)
	config.set_value("compile", "java_home", java_home)
	config.set_value("compile", "android_home", android_home)
	config.save(CONFIG_PATH)

func load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_set_language()
		return
	# 属性设置器在加载阶段只赋值，避免每个字段分别触发写盘和信号
	_is_loading_config = true
	language = config.get_value("general", "language", "auto")
	architecture = config.get_value("general", "architecture", "auto")
	delete_download_file = config.get_value("general", "delete_download_file", false)
	external_editor_path = config.get_value("general", "external_editor_path", "")
	hide_path = config.get_value("general", "hide_path", false)
	remote_source = config.get_value("general", "remote_source", false)
	mingw_prefix = config.get_value("compile", "mingw_prefix", "")
	java_home = config.get_value("compile", "java_home", "")
	android_home = config.get_value("compile", "android_home", "")
	_is_loading_config = false
	_set_language()

func get_architecture() -> String:
	if architecture == "auto":
		return App.get_architecture()
	return architecture
