extends FoldableContainer

signal download(version_name: String, major_version: String)

const SOURCE_CARD = preload("res://src/download/source_card.tscn")

@onready var card_container: VBoxContainer = $HBoxContainer/CardContainer

func _ready() -> void:
	var version_data: Dictionary = DownloadSource.source_data.get("godot", {})
	if not version_data.has(title):
		return
	var version_list: Array = version_data.get(title, [])
	for version_name: String in version_list:
		var card: Node = SOURCE_CARD.instantiate()
		card.version_name = version_name
		card.download.connect(_on_download_card_download)
		card_container.add_child(card)

func switch_unstable_display(display: bool) -> void:
	for card: Control in card_container.get_children():
		if not card.is_stable:
			card.visible = display

func _on_download_card_download(version_name: String) -> void:
	download.emit(version_name, title)
