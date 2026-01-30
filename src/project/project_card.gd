extends PanelContainer

const PROJECT_TAG: PackedScene = preload("res://src/project/project_tag.tscn")

var project_path: String = ""
var prefer_engine_id: String = ""

@onready var project_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ProjectIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var version_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/VersionLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var dotnet_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/DotnetIcon
@onready var path_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/PanelContainer/MarginContainer/PathLabel
@onready var tag_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer3/ScrollContainer/TagContainer
@onready var engine_option: OptionButton = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/EngineOption

func _ready() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(project_path.path_join("project.godot")) != OK:
		queue_free()
		return
	name_label.text = config.get_value("application", "config/name", "Unnamed Project")
	var icon_path: String = _get_icon_path(
		config.get_value("application", "config/icon", ""),
		project_path)
	if icon_path != "":
		var img: Image = Image.new()
		if img.load(icon_path) == OK:
			project_icon.texture = ImageTexture.create_from_image(img)
	version_label.text = _get_project_version(config)
	dotnet_icon.visible = config.has_section("dotnet")
	var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(
		_get_directory_last_edited_time(project_path))
	time_label.text = "%d/%d/%d-%0d:%0d:%0d" % [
		time_dict.get("year", 1970),
		time_dict.get("month", 1),
		time_dict.get("day", 1),
		time_dict.get("hour", 0),
		time_dict.get("minute", 0),
		time_dict.get("second", 0),
	]
	path_label.text = project_path
	engine_option.select_id(prefer_engine_id)
	
func _get_project_version(config: ConfigFile) -> String:
	var feature: PackedStringArray = config.get_value("application", "config/features", ["unknown"])
	return feature[0]

func _get_icon_path(path: String, project_root: String) -> String:
	if path.begins_with("res://"):
		return project_root.path_join(path.replace("res://", ""))
	if path.begins_with("uid://"):
		var res_path: String = _uid_path_to_res_path(path, project_root)
		if res_path != "":
			return project_root.path_join(res_path.replace("res://", ""))
	return ""

func _uid_path_to_res_path(uid_path: String, project_root: String) -> String:
	var dir: DirAccess = DirAccess.open(project_root)
	if dir == null:
		return ""
	var dirs_to_scan: Array[String] = [project_root]
	while dirs_to_scan.size() > 0:
		var current_path: String = dirs_to_scan.pop_back()
		var current_dir: DirAccess = DirAccess.open(current_path)
		if current_dir != null:
			current_dir.list_dir_begin()
			var file_name: String = current_dir.get_next()
			while file_name != "":
				if current_dir.current_is_dir():
					if file_name != "." and file_name != "..":
						dirs_to_scan.append(current_path.path_join(file_name))
				else:
					if file_name.ends_with(".import"):
						var import_config: ConfigFile = ConfigFile.new()
						if (import_config.load(current_path.path_join(file_name)) == OK
							and import_config.get_value("remap", "uid", "") == uid_path):
							current_dir.list_dir_end()
							return import_config.get_value("deps", "source_file", "")
				file_name = current_dir.get_next()
			current_dir.list_dir_end()
	return ""


func _get_directory_last_edited_time(dir_path: String) -> int:
	var os_name: String = OS.get_name()
	if os_name in ["Windows", "macOS", "Linux"]:
		var exit_code: int = -1
		var output: Array[String] = []
		match os_name:
			"Windows":
				exit_code = OS.execute("powershell",
				["-Command",
				"[DateTimeOffset]::new((Get-Item '%s').LastWriteTime).ToUnixTimeSeconds()" % dir_path],
				output)
			"macOS":
				exit_code = OS.execute("stat",
				["-f", "%m", dir_path],
				output)
			"Linux":
				exit_code = OS.execute("stat",
				["-c", "%Y", dir_path],
				output)
		if exit_code == 0 and not output.is_empty():
			return output[0].strip_edges().to_int()
	else:
		# Bad method
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			return 0
		var last_time: int = 0
		var dirs_to_scan: Array[String] = [dir_path]
		while dirs_to_scan.size() > 0:
			var current_path: String = dirs_to_scan.pop_back()
			var current_dir: DirAccess = DirAccess.open(current_path)
			if current_dir != null:
				current_dir.list_dir_begin()
				var file_name: String = current_dir.get_next()
				while file_name != "":
					if current_dir.current_is_dir():
						if file_name != "." and file_name != "..":
							dirs_to_scan.append(current_path.path_join(file_name))
					else:
						var file_time: int = FileAccess.get_modified_time(current_path.path_join(file_name))
						if file_time > last_time:
							last_time = file_time
					file_name = current_dir.get_next()
				current_dir.list_dir_end()
		return last_time
	return 0

func _get_config_tags(config: ConfigFile) -> Array[String]:
	var result: Array[String] = []
	var tags: PackedStringArray = config.get_value("application", "config/tags", [])
	for tag: String in tags:
		result.append(tag)
	return result

func _on_path_button_pressed() -> void:
	OS.shell_show_in_file_manager(project_path)


func _on_engine_button_pressed() -> void:
	var engine: EngineManager.LocalEngine = EngineManager.local_engines.get(
		engine_option.get_item_text(engine_option.selected), null)
	if engine == null:
		return
	OS.open_with_program(engine.executable_path, [project_path.path_join("project.godot")])
	print(engine.info.id)
	ProjectManager.project_info[project_path].prefer_engine_id = engine.info.id
	ProjectManager.store_config()


func _on_delete_icon_pressed() -> void:
	ProjectManager.project_info.erase(project_path)
	queue_free()
