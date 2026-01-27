extends VBoxContainer

const PROJECT_CARD: PackedScene = preload("uid://cphby36r2gwsb")

@onready var import_file_dialog: FileDialog = $HBoxContainer/ImportButton/ImportFileDialog
@onready var scan_file_dialog: FileDialog = $HBoxContainer/ScanButton/ScanFileDialog
@onready var card_container: GridContainer = $PanelContainer/ScrollContainer/MarginContainer/CardContainer

var project_cards: Dictionary[String, Node] = {}

func _ready() -> void:
	for project_path: String in Config.project_info.keys():
		var card: Node = PROJECT_CARD.instantiate()
		var project_config: ConfigFile = ConfigFile.new()
		if project_config.load(project_path.path_join("project.godot")) != OK:
			continue
		card.is_favorite = Config.project_info.get(project_path, false)
		card.project_icon_path = _get_icon_path(
			project_config.get_value("application", "config/icon", ""),
			project_path,
		)
		card.project_name = project_config.get_value("application", "config/name", "Unnamed Project")
		card.project_path = project_path
		card.project_version = _get_project_version(project_config)
		card.project_tags = _get_config_tags(project_config)
		card.last_edited_time = _get_directory_last_edited_time(project_path)
		card_container.add_child(card)

func _get_icon_path(path: String, project_root: String) -> String:
	if path.begins_with("res://"):
		return project_root.path_join(path.replace("res://", ""))
	if path.begins_with("uid://"):
		var res_path: String = _uid_path_to_res_path(path, project_root)
		if res_path != "":
			return project_root.path_join(res_path.replace("res://", ""))
	return ""

func _uid_path_to_res_path(uid_path: String, project_root: String) -> String:
	var dir: DirAccess = DirAccess.open(project_root)
	if dir == null:
		return ""
	var dirs_to_scan: Array[String] = [project_root]
	while dirs_to_scan.size() > 0:
		var current_path: String = dirs_to_scan.pop_back()
		var current_dir: DirAccess = DirAccess.open(current_path)
		if current_dir != null:
			current_dir.list_dir_begin()
			var file_name: String = current_dir.get_next()
			while file_name != "":
				if current_dir.current_is_dir():
					if file_name != "." and file_name != "..":
						dirs_to_scan.append(current_path.path_join(file_name))
				else:
					if file_name.ends_with(".import"):
						var import_config: ConfigFile = ConfigFile.new()
						if (import_config.load(current_path.path_join(file_name)) == OK
							and import_config.get_value("remap", "uid", "") == uid_path):
							current_dir.list_dir_end()
							return import_config.get_value("deps", "source_file", "")
				file_name = current_dir.get_next()
			current_dir.list_dir_end()
	return ""

func _get_project_version(config: ConfigFile) -> String:
	var feature: PackedStringArray = config.get_value("application", "config/features", ["unknown"])
	return feature[0]

func _get_config_tags(config: ConfigFile) -> Array[String]:
	var result: Array[String] = []
	var tags: PackedStringArray = config.get_value("application", "config/tags", [])
	for tag: String in tags:
		result.append(tag)
	return result

func _get_directory_last_edited_time(dir_path: String) -> int:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return 0
	var last_time: int = 0
	var dirs_to_scan: Array[String] = [dir_path]
	while dirs_to_scan.size() > 0:
		var current_path: String = dirs_to_scan.pop_back()
		var current_dir: DirAccess = DirAccess.open(current_path)
		if current_dir != null:
			current_dir.list_dir_begin()
			var file_name: String = current_dir.get_next()
			while file_name != "":
				if current_dir.current_is_dir():
					if file_name != "." and file_name != "..":
						dirs_to_scan.append(current_path.path_join(file_name))
				else:
					var file_time: int = FileAccess.get_modified_time(current_path.path_join(file_name))
					if file_time > last_time:
						last_time = file_time
				file_name = current_dir.get_next()
			current_dir.list_dir_end()
	return last_time

func _on_import_button_pressed() -> void:
	import_file_dialog.popup_centered()


func _on_scan_button_pressed() -> void:
	scan_file_dialog.popup_centered()


func _on_import_file_dialog_file_selected(path: String) -> void:
	print(path)


func _on_scan_file_dialog_dir_selected(dir: String) -> void:
	print(dir)
