extends VBoxContainer

const DOWNLOADER_CARD: PackedScene = preload("res://src/download/downloader_card.tscn")

@onready var download_confirm: ConfirmationDialog = $DownloadConfirm

@onready var standard_check: CheckBox = $TopBarContainer/OptionContainer/StandardCheck
@onready var dotnet_check: CheckBox = $TopBarContainer/OptionContainer/DotnetCheck
@onready var stable_check: CheckBox = $TopBarContainer/OptionContainer/StableCheck
@onready var unstable_check: CheckBox = $TopBarContainer/OptionContainer/UnstableCheck

@onready var downloader_container: VBoxContainer = $HSplitContainer/ScrollContainer2/DownloaderContainer

func _ready() -> void:
	var version_container: Array[Node] = get_tree().get_nodes_in_group("download_version_container")
	for container: Control in version_container:
		container.download.connect(_on_version_container_download)

func _on_version_container_download(engine_id: String) -> void:
	download_confirm.display(engine_id)


func _on_download_confirm_download() -> void:
	var downloader_card: Control = DOWNLOADER_CARD.instantiate()
	downloader_container.add_child(downloader_card)
