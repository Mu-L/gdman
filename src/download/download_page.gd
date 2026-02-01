extends VBoxContainer

const DOWNLOADER_CARD: PackedScene = preload("uid://bgk1814jgblda")

@onready var download_confirm: ConfirmationDialog = $DownloadConfirm

@onready var standard_check: CheckBox = $OptionContainer/StandardCheck
@onready var dotnet_check: CheckBox = $OptionContainer/DotnetCheck
@onready var stable_check: CheckBox = $OptionContainer/StableCheck
@onready var unstable_check: CheckBox = $OptionContainer/UnstableCheck

@onready var downloader_container: VBoxContainer = $HSplitContainer/PanelContainer2/MarginContainer/ScrollContainer/DownloaderContainer

func _ready() -> void:
	var version_containers: Array[Node] = get_tree().get_nodes_in_group("download_version_container")
	for container: Control in version_containers:
		container.download.connect(_on_version_container_download)
	standard_check.toggled.connect(_switch_display)
	dotnet_check.toggled.connect(_switch_display)
	stable_check.toggled.connect(_switch_display)
	unstable_check.toggled.connect(_switch_display)
	_switch_display(false)

func _on_version_container_download(engine_id: String) -> void:
	download_confirm.title = tr("DOWNLOAD_CONFIRM_TITLE") % engine_id
	download_confirm.display(engine_id)

func _switch_display(_pass: bool) -> void:
	var version_containers: Array[Node] = get_tree().get_nodes_in_group("download_version_container")
	for container: Control in version_containers:
		container.switch_display(
			standard_check.button_pressed,
			dotnet_check.button_pressed,
			stable_check.button_pressed,
			unstable_check.button_pressed
		)


func _on_download_confirm_download(url: String, engine_id: String) -> void:
	var downloader_card: Control = DOWNLOADER_CARD.instantiate()
	downloader_card.url = url
	downloader_card.file_name = engine_id
	downloader_container.add_child(downloader_card)
