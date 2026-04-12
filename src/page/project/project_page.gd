extends VBoxContainer

const PROJECT_CARD: PackedScene = preload("uid://cphby36r2gwsb")

@onready var import_button: Button = $HBoxContainer/ImportButton
@onready var import_file_dialog: FileDialog = $HBoxContainer/ImportButton/ImportFileDialog
@onready var card_container: GridContainer = $PanelContainer/ScrollContainer/MarginContainer/CardContainer

var project_request: Array[String] = []

func _ready() -> void:
	set_process(false)
	_load_project()
	_handle_component()
	Config.config_updated.connect(_config_update)

func _process(_delta: float) -> void:
	if project_request.size() <= 0:
		import_button.disabled = false
		set_process(false)
	else:
		_add_project_card(project_request.pop_back())

func _load_project() -> void:
	import_button.disabled = true
	for card: Control in card_container.get_children():
		card.queue_free()
	project_request = ProjectManager.project_info.keys()
	if Config.fast_load:
		set_process(true)
	else:
		for project_path: String in project_request:
			_add_project_card(project_path)
		import_button.disabled = false

func _add_project_card(project_path: String) -> void:
	var project: ProjectManager.ProjectInfo = ProjectManager.project_info.get(project_path, null)
	if project == null:
		return
	var card: Control = PROJECT_CARD.instantiate()
	card.project_path = project.path
	card.prefer_engine_id = project.prefer_engine_id
	card_container.add_child.call_deferred(card)

func _config_update(config_name: String) -> void:
	match config_name:
		"language":
			_handle_component()
			
func _handle_component() -> void:
	App.fix_button_width(import_button)

func _on_import_button_pressed() -> void:
	import_file_dialog.popup_centered()

func _on_import_file_dialog_file_selected(path: String) -> void:
	if not path.ends_with("project.godot"):
		return
	var dir_path: String = path.get_base_dir()
	if ProjectManager.project_info.has(dir_path):
		return
	ProjectManager.add_project(dir_path)
	var project: ProjectManager.ProjectInfo = ProjectManager.project_info.get(dir_path, null)
	if project == null:
		return
	var card: Control = PROJECT_CARD.instantiate()
	card.project_path = project.path
	card.prefer_engine_id = project.prefer_engine_id
	card_container.add_child(card)


func _on_card_spin_value_changed(value: float) -> void:
	card_container.columns = int(value)
