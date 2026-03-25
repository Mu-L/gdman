extends VBoxContainer

const ENGINE_DOWNLOADER_CARD = preload("uid://dqqd7c1vpwb5y")
const CODE_DOWNLOADER_CARD = preload("uid://df2xo4wx3n3rc")

@onready var engine_download_dialog: ConfirmationDialog = $EngineDownloadDialog
@onready var code_download_dialog: ConfirmationDialog = $OptionContainer/CodeDownloadButton/CodeDownloadDialog

@onready var standard_check: CheckBox = $OptionContainer/StandardCheck
@onready var dotnet_check: CheckBox = $OptionContainer/DotnetCheck
@onready var stable_check: CheckBox = $OptionContainer/StableCheck
@onready var unstable_check: CheckBox = $OptionContainer/UnstableCheck
@onready var code_download_button: Button = $OptionContainer/CodeDownloadButton
@onready var update_prompt_button: LinkButton = $OptionContainer/UpdatePromptButton

@onready var downloader_container: VBoxContainer = $HSplitContainer/PanelContainer2/MarginContainer/ScrollContainer/DownloaderContainer

func _ready() -> void:
	update_prompt_button.hide()
	DownloadManager.source_updated.connect(update_prompt_button.show)
	var version_containers: Array[Node] = get_tree().get_nodes_in_group("download_version_container")
	for container: Control in version_containers:
		container.download.connect(_on_version_container_download)
	_handle_component()
	Config.config_updated.connect(_config_update)

func _config_update(config_name: String) -> void:
	match config_name:
		"language":
			_handle_component()

func _handle_component() -> void:
	App.fix_button_width(code_download_button)

func _on_version_container_download(engine_id: String) -> void:
	engine_download_dialog.title = tr("DOWNLOAD_DIALOG_TITLE") % engine_id
	engine_download_dialog.display(engine_id)

func _switch_display() -> void:
	var version_containers: Array[Node] = get_tree().get_nodes_in_group("download_version_container")
	for container: Control in version_containers:
		container.switch_display()


func _on_engine_download_dialog_download(url: String, engine_id: String) -> void:
	var downloader_card: Control = ENGINE_DOWNLOADER_CARD.instantiate()
	downloader_card.url = url
	downloader_card.engine_id = engine_id
	downloader_container.add_child(downloader_card)


func _on_code_download_button_pressed() -> void:
	code_download_dialog.display()


func _on_code_download_dialog_download(url: String, file_name: String) -> void:
	var downloader_card: Control = CODE_DOWNLOADER_CARD.instantiate()
	downloader_card.url = url
	downloader_card.file_name = file_name
	downloader_container.add_child(downloader_card)


func _on_standard_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_standard = toggled_on
	_switch_display()


func _on_dotnet_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_dotnet = toggled_on
	_switch_display()


func _on_stable_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_stable = toggled_on
	_switch_display()


func _on_unstable_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_unstable = toggled_on
	_switch_display()
