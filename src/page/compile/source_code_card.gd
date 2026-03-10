extends PanelContainer

const BASIC_CUSTOM_CONTENT: String = "production=\"yes\"\ntarget=\"template_release\"\ndebug_symbols=\"no\"\noptimize=\"size\"\nlto=\"full\"\n"

signal compile()

var file_name: String = ""

var dir_path: String = ""
var source_code_path: String = ""
var custom_file_path: String = ""
var bin_dir_path: String = ""

@onready var path_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/PathButton
@onready var bin_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/BinButton
@onready var custom_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CustomButton
@onready var compile_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CompileButton

@onready var name_label: Label = $MarginContainer/VBoxContainer/InfoContainer/NameLabel
@onready var path_line: LineEdit = $MarginContainer/VBoxContainer/PathLine

func _ready() -> void:
	dir_path = ProjectSettings.globalize_path(CompileManager.SOURCE_CODE_DIR.path_join(file_name))
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		queue_free()
		return
	var sub_dir: PackedStringArray = dir.get_directories()
	if sub_dir.size() == 0:
		queue_free()
		return
	for dir_name: String in sub_dir:
		var sub_dir_path: String = dir_path.path_join(dir_name)
		if FileAccess.file_exists(sub_dir_path.path_join("version.py")):
			source_code_path = sub_dir_path
			break
	if source_code_path == "":
		queue_free()
		return
	name_label.text = file_name
	path_line.secret = Config.hide_path
	path_line.text = source_code_path
	path_line.tooltip_text = source_code_path
	custom_file_path = source_code_path.path_join("custom.py")
	custom_button.disabled = Config.external_editor_path == ""
	bin_dir_path = source_code_path.path_join("bin")
	_handle_component()
	Config.config_updated.connect(_config_update)

	
func _config_update(config_name: String) -> void:
	match config_name:
		"language":
			_handle_component()
		"hide_path":
			path_line.secret = Config.hide_path
		"external_editor_path":
			custom_button.disabled = Config.external_editor_path == ""

func _handle_component() -> void:
	App.fix_button_width(path_button)
	App.fix_button_width(bin_button)
	App.fix_button_width(custom_button)
	App.fix_button_width(compile_button)

func _on_delete_button_pressed() -> void:
	App.remove_file(dir_path)
	queue_free()


func _on_path_button_pressed() -> void:
	OS.shell_show_in_file_manager(source_code_path)


func _on_bin_button_pressed() -> void:
	DirAccess.make_dir_recursive_absolute(bin_dir_path)
	OS.shell_show_in_file_manager(bin_dir_path)

func _on_custom_button_pressed() -> void:
	if not FileAccess.file_exists(custom_file_path):
		var file: FileAccess = FileAccess.open(custom_file_path, FileAccess.WRITE)
		if file != null:
			file.store_string(BASIC_CUSTOM_CONTENT)
			file.close()
	if FileAccess.file_exists(custom_file_path):
		OS.open_with_program(Config.external_editor_path, [custom_file_path])


func _on_compile_button_pressed() -> void:
	compile.emit()
	CompileManager.open_terminal_to_dir(source_code_path)
