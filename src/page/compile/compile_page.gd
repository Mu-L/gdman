extends VBoxContainer

const SOURCE_CODE_CARD: PackedScene = preload("uid://dnwx7tc3bvgu1")

@onready var card_container: GridContainer = $PanelContainer/ScrollContainer/MarginContainer/CardContainer
@onready var compile_dialog: AcceptDialog = $CompileDialog

var source_code_files: Array[String] = []

func _ready() -> void:
	_load_source_code()
	CompileManager.source_code_added.connect(_add_source_code)

func _process(_delta: float) -> void:
	if source_code_files.size() <= 0:
		set_process(false)
	else:
		var file_name: String = source_code_files.pop_back()
		_add_source_code(file_name)

func _load_source_code() -> void:
	for card: Control in card_container.get_children():
		card.queue_free()
	source_code_files.clear()
	var source_code_dir: DirAccess = DirAccess.open(CompileManager.SOURCE_CODE_DIR)
	if source_code_dir == null:
		return
	for dir_name: String in source_code_dir.get_directories():
		source_code_files.append(dir_name)
	set_process(true)

func _add_source_code(file_name: String) -> void:
	var card: Control = SOURCE_CODE_CARD.instantiate()
	card.file_name = file_name
	card.compile.connect(compile_dialog.display)
	card_container.add_child(card)


func _on_card_spin_value_changed(value: float) -> void:
	card_container.columns = int(value)
