extends VBoxContainer

@onready var download_button: Button = $HBoxContainer/DownloadButton
@onready var download_source_code_dialog: ConfirmationDialog = $HBoxContainer/DownloadButton/DownloadSourceCodeDialog


func _ready() -> void:
	Config.config_updated.connect(_config_updated)
	_handle_component()

func _config_updated(config_name: String) -> void:
	match config_name:
		"language":
			_handle_component()

func _handle_component() -> void:
	App.fix_button_width(download_button)


func _on_download_button_pressed() -> void:
	download_source_code_dialog.display()
