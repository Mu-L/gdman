extends FoldableContainer

signal download(engine_id: String)

const SOURCE_CARD: PackedScene = preload("uid://cvhkrjsovo0lf")

@onready var card_container: VBoxContainer = $HBoxContainer/CardContainer

func _ready() -> void:
	for engine_id: String in DownloadManager.valid_version.get(title, []):
		var card: Control = SOURCE_CARD.instantiate()
		card.engine_id = engine_id
		card.download.connect(_on_download_card_download)
		card_container.add_child(card)

func switch_display(standard: bool, dotnet: bool, stable: bool, unstable: bool) -> void:
	for card in card_container.get_children():
		var match_type: bool = (standard and not card.is_dotnet) or (dotnet and card.is_dotnet)
		var match_stability: bool = (stable and card.is_stable) or (unstable and not card.is_stable)
		card.visible = match_type and match_stability

func _on_download_card_download(engine_id: String) -> void:
	download.emit(engine_id)
