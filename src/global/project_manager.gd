extends Node

const CONFIG_PATH: String = "user://project.cfg"

class ProjectInfo:
	var path: String = ""
	var prefer_engine_id: String = ""

var project_info: Dictionary[String, ProjectInfo] = {}

func _ready() -> void:
	load_config()

func store_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	for path: String in project_info.keys():
		var project: ProjectInfo = project_info.get(path, null)
		if project == null:
			continue
		config.set_value(project.path, "prefer_engine_id", project.prefer_engine_id)
	config.save(CONFIG_PATH)

func load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	project_info.clear()
	for path: String in config.get_sections():
		var project: ProjectInfo = ProjectInfo.new()
		project.path = path
		project.prefer_engine_id = config.get_value(path, "prefer_engine_id", "")
		project_info[path] = project

func add_project(dir_path: String) -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(dir_path.path_join("project.godot")) != OK:
		return
	var project: ProjectInfo = ProjectInfo.new()
	project.path = dir_path
	var project_version: String = config.get_value("application", "config/features", [""])[0]
	if project_version != "":
		for engine_id: String in EngineManager.local_engines.keys():
			if engine_id.begins_with(project_version):
				project.prefer_engine_id = engine_id
				break
	project_info[dir_path] = project
	store_config()
