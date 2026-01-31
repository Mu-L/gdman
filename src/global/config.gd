extends Node

const CONFIG_PATH: String = "user://config.cfg"
signal config_updated(config_name: String)

var language: String = "auto":
	set(v):
		language = v
		if language == "auto":
			App.set_language(OS.get_locale())
		else:
			TranslationServer.set_locale(language)
		store_config()
		config_updated.emit("language")

var architecture: String = "auto":
	set(v):
		architecture = v
		store_config()
		config_updated.emit("architecture")

var delete_download_file: bool = false:
	set(v):
		delete_download_file = v
		store_config()
		config_updated.emit("delete_download_file")

var external_editor_path: String = "":
	set(v):
		external_editor_path = v
		store_config()
		config_updated.emit("external_editor_path")

var hide_path: bool = false:
	set(v):
		hide_path = v
		store_config()
		config_updated.emit("hide_path")

func _ready() -> void:
	load_config()

func _exit_tree() -> void:
	store_config()

func store_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("general", "language", language)
	config.set_value("general", "architecture", architecture)
	config.set_value("general", "delete_download_file", delete_download_file)
	config.set_value("general", "external_editor_path", external_editor_path)
	config.set_value("general", "hide_path", hide_path)
	config.save(CONFIG_PATH)

func load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	language = config.get_value("general", "language", "auto")
	architecture = config.get_value("general", "architecture", "auto")
	delete_download_file = config.get_value("general", "delete_download_file", false)
	external_editor_path = config.get_value("general", "external_editor_path", "")
	hide_path = config.get_value("general", "hide_path", false)

func get_architecture() -> String:
	if architecture == "auto":
		return App.get_architecture()
	return architecture
