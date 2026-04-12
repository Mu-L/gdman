extends VBoxContainer

const SOURCE_CODE_CARD: PackedScene = preload("uid://dnwx7tc3bvgu1")

@onready var card_container: GridContainer = $PanelContainer/ScrollContainer/MarginContainer/CardContainer
@onready var compile_dialog: AcceptDialog = $CompileDialog

var source_code_request: Array[String] = []

func _ready() -> void:
	set_process(false)
	_load_source_code()
	CompileManager.source_code_added.connect(_add_source_code_card)

func _process(_delta: float) -> void:
	if source_code_request.size() <= 0:
		set_process(false)
	else:
		_add_source_code_card(source_code_request.pop_back())

func _load_source_code() -> void:
	for card: Control in card_container.get_children():
		card.queue_free()
	source_code_request.clear()
	var source_code_dir: DirAccess = DirAccess.open(CompileManager.SOURCE_CODE_DIR)
	if source_code_dir == null:
		return
	if Config.fast_load:
		for dir_name: String in source_code_dir.get_directories():
			source_code_request.append(dir_name)
		set_process(true)
	else:
		for dir_name: String in source_code_dir.get_directories():
			_add_source_code_card(dir_name)

func _add_source_code_card(file_name: String) -> void:
	var card: Control = SOURCE_CODE_CARD.instantiate()
	card.file_name = file_name
	card.compile.connect(compile_dialog.display)
	card_container.add_child.call_deferred(card)


func _on_card_spin_value_changed(value: float) -> void:
	card_container.columns = int(value)
