extends Node

const CONFIG_PATH: String = "user://config.cfg"

# resolution
var window_sizes: Array[Vector2i] = [
	Vector2i(3200, 2400), # QUXGA
	Vector2i(2800, 2100), # QSXGA+
	Vector2i(2048, 1536), # QXGA
	Vector2i(1600, 1200), # UXGA
	Vector2i(1440, 1080), # HDV 1080i
	Vector2i(1400, 1050), # SXGA+
	Vector2i(1280, 960), # SXGA-
	Vector2i(1152, 864), # XGA+
	Vector2i(1024, 768), # XGA
	Vector2i(800, 600), # SVGA
	Vector2i(768, 576), # PAL (4:3)
	Vector2i(640, 480), # VGA
]

# key: project path
# value: is_favorite
var project_info: Dictionary[String, bool] = {
}

func _ready() -> void:
	load_config()

func _exit_tree() -> void:
	store_config()

func store_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	for project_key: String in project_info.keys():
		config.set_value("project", project_key, project_info[project_key])
	config.save(CONFIG_PATH)

func load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	if config.has_section("project"):
		for project_key: String in config.get_section_keys("project"):
			var is_favorite: bool = config.get_value("project", project_key, false)
			project_info[project_key] = is_favorite
