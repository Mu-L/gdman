extends VBoxContainer

@onready var language_option: OptionButton = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/LanguageOption
@onready var architecture_option: OptionButton = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/ArchitectureOption
@onready var delete_check: CheckButton = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/DeleteCheck
@onready var editor_path_line: LineEdit = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/HBoxContainer/EditorPathLine
@onready var editor_file_dialog: FileDialog = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/HBoxContainer/EditorSelectButton/EditorFileDialog
@onready var hide_path_check: CheckButton = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/HidePathCheck
@onready var version_label: Label = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/VersionLabel
@onready var user_path_button: Button = $HBoxContainer2/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer/UserPathButton

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
	for architecture: String in App.ARCHITECTURE:
		architecture_option.add_item(architecture)
	for i in range(architecture_option.get_item_count()):
		if architecture_option.get_item_text(i) == Config.architecture:
			architecture_option.select(i)
			break
	delete_check.button_pressed = Config.delete_download_file
	editor_path_line.text = Config.external_editor_path
	hide_path_check.button_pressed = Config.hide_path
	version_label.text = ProjectSettings.get_setting("application/config/version", "unknown")
	user_path_button.text = ProjectSettings.globalize_path("user://")

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
	Config.architecture = architecture_option.get_item_text(index)

func _on_delete_check_toggled(toggled_on: bool) -> void:
	Config.delete_download_file = toggled_on

func _on_editor_select_button_pressed() -> void:
	editor_file_dialog.current_dir = editor_path_line.text.get_base_dir()
	editor_file_dialog.popup_file_dialog()

func _on_editor_path_line_text_submitted(new_text: String) -> void:
	Config.external_editor_path = new_text

func _on_editor_file_dialog_file_selected(path: String) -> void:
	editor_path_line.text = path
	Config.external_editor_path = editor_path_line.text
	
func _on_hide_path_check_toggled(toggled_on: bool) -> void:
	Config.hide_path = toggled_on


func _on_user_path_button_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))
