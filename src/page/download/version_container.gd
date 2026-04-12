extends FoldableContainer

signal download(engine_id: String)

const SOURCE_CARD: PackedScene = preload("uid://cvhkrjsovo0lf")

@onready var card_container: VBoxContainer = $HBoxContainer/CardContainer

var engine_id_request: Array[String] = []

func _ready() -> void:
	set_process(false)
	_load_source()
	DownloadManager.source_loaded.connect(_load_source)

func _process(_delta: float) -> void:
	if engine_id_request.size() <= 0:
		set_process(false)
	else:
		_add_source_card(engine_id_request.pop_back())

func _load_source() -> void:
	for card: Control in card_container.get_children():
		card.queue_free()
	engine_id_request.clear()
	if Config.fast_load:
		for engine_id: String in DownloadManager.valid_version.get(title, []):
			engine_id_request.append(engine_id)
		set_process(true)
	else:
		for engine_id: String in DownloadManager.valid_version.get(title, []):
			_add_source_card(engine_id)

func _add_source_card(engine_id: String) -> void:
	var card: Control = SOURCE_CARD.instantiate()
	card.engine_id = engine_id
	card.download.connect(_on_download_card_download)
	card_container.add_child.call_deferred(card)

func switch_display() -> void:
	for card: Control in card_container.get_children():
		card._switch_display()

func _on_download_card_download(engine_id: String) -> void:
	download.emit(engine_id)
