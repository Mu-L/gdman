extends PanelContainer

const DOTNET: CompressedTexture2D = preload("uid://b5cuh2fee8rn5")

var engine_id: String = ""
var dir_path: String = ""
var executable_path: String = ""
var is_stable: bool = false
var is_dotnet: bool = false

@onready var engine_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/EngineIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var version_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/VersionLabel
@onready var id_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/IDLabel
@onready var unstable_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/UnstableIcon
@onready var path_line: LineEdit = $MarginContainer/VBoxContainer/PathLine
@onready var path_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/PathButton
@onready var run_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/RunButton

func _ready() -> void:
	id_label.text = engine_id
	path_line.text = dir_path
	path_line.tooltip_text = dir_path
	path_line.secret = Config.hide_path
	var engine_info: EngineManager.EngineInfo = EngineManager.id_to_engine_info(engine_id)
	if engine_info == null:
		return
	name_label.text = engine_info.name
	version_label.text = "%d.%d" % [engine_info.major_version, engine_info.minor_version]
	if engine_info.is_dotnet:
		engine_icon.texture = DOTNET
	is_stable = engine_info.flavor == EngineManager.EngineFlavor.STABLE
	is_dotnet = engine_info.is_dotnet
	unstable_icon.visible = not is_stable
	Config.config_updated.connect(_config_updated)
	_handle_component()
	
func _config_updated(config_name: String) -> void:
	match config_name:
		"hide_path":
			path_line.secret = Config.hide_path
		"language":
			_handle_component()

func _handle_component() -> void:
	App.fix_button_width(path_button)
	App.fix_button_width(run_button)

func _on_delete_button_pressed() -> void:
	OS.move_to_trash(dir_path)
	queue_free()


func _on_run_button_pressed() -> void:
	match OS.get_name():
		"Linux", "macOS":
			OS.execute("chmod", ["-R", "+x", executable_path])
	OS.create_process(executable_path, [])


func _on_path_button_pressed() -> void:
	OS.shell_show_in_file_manager(dir_path)
