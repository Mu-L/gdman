extends PanelContainer

const PROJECT_TAG: PackedScene = preload("uid://46nlwtxtu0rn")

var project_path: String = ""
var prefer_engine_id: String = ""
var uid_scan_request_id: int = -1

@onready var project_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ProjectIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var version_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/VersionLabel
@onready var dotnet_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/DotnetIcon
@onready var time_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var tag_container: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/TagContainer
@onready var path_line: LineEdit = $MarginContainer/VBoxContainer/PathLine
@onready var path_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/PathButton
@onready var editor_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/EditorButton
@onready var engine_option: OptionButton = $MarginContainer/VBoxContainer/HBoxContainer2/EngineOption
@onready var engine_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/EngineButton

func _ready() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(project_path.path_join("project.godot")) != OK:
		queue_free()
		return
	name_label.text = config.get_value("application", "config/name", "Unnamed Project")
	name_label.tooltip_text = name_label.text
	var configured_icon_path: String = config.get_value("application", "config/icon", "")
	if configured_icon_path.begins_with("res://"):
		_load_project_icon(configured_icon_path)
	elif configured_icon_path.begins_with("uid://"):
		ProjectManager.uid_path_resolved.connect(_on_uid_path_resolved)
		uid_scan_request_id = ProjectManager.request_uid_path(configured_icon_path, project_path)
	version_label.text = _get_project_version(config)
	dotnet_icon.visible = config.has_section("dotnet")
	var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(
		_get_directory_last_edited_time(project_path))
	time_label.text = "%d/%d/%d-%d:%d:%d" % [
		time_dict.get("year", 1970),
		time_dict.get("month", 1),
		time_dict.get("day", 1),
		time_dict.get("hour", 0),
		time_dict.get("minute", 0),
		time_dict.get("second", 0),
	]
	path_line.text = project_path
	path_line.tooltip_text = project_path
	path_line.secret = Config.hide_path
	for tag: String in config.get_value("application", "config/tags", []):
		var tag_node: Control = PROJECT_TAG.instantiate()
		tag_node.text = tag
		tag_container.add_child(tag_node)
	editor_button.disabled = Config.external_editor_path == ""
	refresh_engines()
	App.small_update.connect(_small_update)
	Config.config_updated.connect(_config_update)
	_handle_component()

func _exit_tree() -> void:
	if uid_scan_request_id >= 0:
		ProjectManager.wait_for_uid_scan(uid_scan_request_id)

func _small_update() -> void:
	var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(
		_get_directory_last_edited_time(project_path))
	time_label.text = "%d/%d/%d-%d:%d:%d" % [
		time_dict.get("year", 1970),
		time_dict.get("month", 1),
		time_dict.get("day", 1),
		time_dict.get("hour", 0),
		time_dict.get("minute", 0),
		time_dict.get("second", 0),
	]

func _config_update(config_name: String) -> void:
	match config_name:
		"hide_path":
			path_line.secret = Config.hide_path
		"external_editor_path":
			editor_button.disabled = Config.external_editor_path == ""
		"language":
			_handle_component()

func _handle_component() -> void:
	App.fix_button_width(path_button)
	App.fix_button_width(editor_button)
	App.fix_button_width(engine_button)

func refresh_engines() -> void:
	engine_option.load_engine()
	engine_option.select_id(prefer_engine_id)
	engine_button.disabled = engine_option.get_selected_id() == -1

func _get_project_version(config: ConfigFile) -> String:
	var feature: PackedStringArray = config.get_value("application", "config/features", ["unknown"])
	return feature[0]

func _load_project_icon(resource_path: String) -> void:
	if not resource_path.begins_with("res://"):
		return
	var icon_path: String = project_path.path_join(resource_path.trim_prefix("res://"))
	var image: Image = Image.new()
	if image.load(icon_path) == OK:
		project_icon.texture = ImageTexture.create_from_image(image)

func _on_uid_path_resolved(request_id: int, resource_path: String) -> void:
	if request_id != uid_scan_request_id:
		return
	uid_scan_request_id = -1
	_load_project_icon(resource_path)


func _get_directory_last_edited_time(dir_path: String) -> int:
	# Godot 平台层支持直接读取目录修改时间，避免启动外部进程阻塞主线程
	var modified_time: int = FileAccess.get_modified_time(dir_path)
	if modified_time <= 0:
		return 0
	return modified_time + Time.get_time_zone_from_system().bias * 60

func _on_path_button_pressed() -> void:
	OS.shell_show_in_file_manager(project_path)


func _on_engine_button_pressed() -> void:
	var selected_index: int = engine_option.selected
	if selected_index < 0 or engine_option.is_item_disabled(selected_index):
		return
	var engine: EngineManager.LocalEngine = EngineManager.local_engines.get(
		engine_option.get_item_text(selected_index), null)
	if engine == null or not engine.can_run:
		return
	if App.is_unix_platform():
		OS.execute("chmod", ["-R", "+x", engine.executable_path])
	OS.open_with_program(engine.executable_path, [project_path.path_join("project.godot")])
	ProjectManager.project_info[project_path].prefer_engine_id = engine.info.id
	ProjectManager.store_config()


func _on_remove_button_pressed() -> void:
	ProjectManager.project_info.erase(project_path)
	ProjectManager.store_config()
	queue_free()


func _on_editor_button_pressed() -> void:
	if Config.external_editor_path == "":
		return
	OS.open_with_program(Config.external_editor_path, [project_path])


func _on_engine_option_item_selected(index: int) -> void:
	if index < 0 or engine_option.is_item_disabled(index):
		engine_button.disabled = true
		return
	var engine: EngineManager.LocalEngine = EngineManager.local_engines.get(
		engine_option.get_item_text(index), null)
	engine_button.disabled = engine == null or not engine.can_run
