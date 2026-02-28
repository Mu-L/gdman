extends GridContainer

@onready var version_name_label: Label = $VersionNameLabel
@onready var language_option: OptionButton = $LanguageOption
@onready var architecture_option: OptionButton = $ArchitectureOption
@onready var remote_source_check: CheckButton = $RemoteSourceCheck
@onready var delete_download_check: CheckButton = $DeleteDownloadCheck
@onready var editor_path_line: LineEdit = $EditorContainer/EditorPathLine
@onready var editor_file_dialog: FileDialog = $EditorContainer/EditorSelectButton/EditorFileDialog
@onready var hide_path_check: CheckButton = $HidePathCheck
@onready var user_path_line: LineEdit = $UserPathContainer/UserPathLine

func _ready() -> void:
	match Config.language:
		"auto":
			language_option.select(0)
		"en":
			language_option.select(1)
		"zh_CN":
			language_option.select(2)
		"zh_HK":
			language_option.select(3)
		_:
			language_option.select(0)
	language_option.set_item_text(0, tr("SELECT_AUTO") % OS.get_locale())
	for architecture: String in App.ARCHITECTURE:
		architecture_option.add_item(architecture)
	architecture_option.set_item_text(0, tr("SELECT_AUTO") % App.get_architecture())
	for i in range(architecture_option.get_item_count()):
		if architecture_option.get_item_text(i) == Config.architecture:
			architecture_option.select(i)
			break
	delete_download_check.button_pressed = Config.delete_download_file
	editor_path_line.text = Config.external_editor_path
	editor_path_line.tooltip_text = Config.external_editor_path
	hide_path_check.button_pressed = Config.hide_path
	remote_source_check.button_pressed = Config.remote_source
	version_name_label.text = ProjectSettings.get_setting("application/config/version", "unknown")
	user_path_line.text = ProjectSettings.globalize_path("user://")
	user_path_line.tooltip_text = ProjectSettings.globalize_path("user://")
	Config.config_updated.connect(_config_update)


func _config_update(config_name: String) -> void:
	match config_name:
		"language":
			language_option.set_item_text(0, tr("SELECT_AUTO") % OS.get_locale())
			architecture_option.set_item_text(0, tr("SELECT_AUTO") % App.get_architecture())

func _on_language_option_item_selected(index: int) -> void:
	match index:
		0:
			Config.language = "auto"
		1:
			Config.language = "en"
		2:
			Config.language = "zh_CN"
		3:
			Config.language = "zh_HK"
		_:
			Config.language = "auto"


func _on_architecture_option_item_selected(index: int) -> void:
	if index == 0:
		Config.architecture = "auto"
	else:
		Config.architecture = architecture_option.get_item_text(index)


func _on_remote_source_check_toggled(toggled_on: bool) -> void:
	Config.remote_source = toggled_on


func _on_delete_download_check_toggled(toggled_on: bool) -> void:
	Config.delete_download_file = toggled_on

func _on_editor_path_line_text_submitted(new_text: String) -> void:
	Config.external_editor_path = new_text

func _on_editor_select_button_pressed() -> void:
	editor_file_dialog.current_dir = editor_path_line.text.get_base_dir()
	editor_file_dialog.popup_centered()

func _on_hide_path_check_toggled(toggled_on: bool) -> void:
	Config.hide_path = toggled_on

func _on_user_path_button_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))
