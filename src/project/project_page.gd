extends VBoxContainer

const PROJECT_CARD: PackedScene = preload("uid://cphby36r2gwsb")

@onready var import_file_dialog: FileDialog = $HBoxContainer/ImportButton/ImportFileDialog
@onready var card_container: GridContainer = $PanelContainer/ScrollContainer/MarginContainer/CardContainer

var project_cards: Dictionary[String, Node] = {}

func _ready() -> void:
	for card: Control in card_container.get_children():
		card.queue_free()
	project_cards.clear()
	for project_path: String in ProjectManager.project_info.keys():
		var project: ProjectManager.ProjectInfo = ProjectManager.project_info.get(project_path, null)
		if project == null:
			continue
		var card: Control = PROJECT_CARD.instantiate()
		card.project_path = project.path
		card.prefer_engine_id = project.prefer_engine_id
		card_container.add_child(card)


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
	
	
func _on_scan_file_dialog_dir_selected(dir: String) -> void:
	print(dir)
