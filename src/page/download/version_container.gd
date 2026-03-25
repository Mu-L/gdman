extends FoldableContainer

signal download(engine_id: String)

const SOURCE_CARD: PackedScene = preload("uid://cvhkrjsovo0lf")

@onready var card_container: VBoxContainer = $HBoxContainer/CardContainer

var engine_ids: Array[String] = []

func _ready() -> void:
	_load_source()
	DownloadManager.source_loaded.connect(_load_source)

func _process(_delta: float) -> void:
	if engine_ids.size() <= 0:
		set_process(false)
	else:
		var card: Control = SOURCE_CARD.instantiate()
		card.engine_id = engine_ids.pop_back()
		card.download.connect(_on_download_card_download)
		card_container.add_child.call_deferred(card)

func _load_source() -> void:
	for card: Control in card_container.get_children():
		card.queue_free()
	for engine_id: String in DownloadManager.valid_version.get(title, []):
		engine_ids.append(engine_id)
	set_process(true)

func switch_display() -> void:
	for card: Control in card_container.get_children():
		card._switch_display()

func _on_download_card_download(engine_id: String) -> void:
	download.emit(engine_id)
