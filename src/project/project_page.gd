extends VBoxContainer

const PROJECT_CARD: PackedScene = preload("res://src/project/project_card.tscn")

@onready var import_file_dialog: FileDialog = $OptionContainer/ImportButton/ImportFileDialog
@onready var scan_file_dialog: FileDialog = $OptionContainer/ScanButton/ScanFileDialog
@onready var filter_button: OptionButton = $OptionContainer/FilterButton
@onready var card_container: VBoxContainer = $ScrollContainer/CardContainer

func _on_import_button_pressed() -> void:
	import_file_dialog.popup_centered()


func _on_scan_button_pressed() -> void:
	scan_file_dialog.popup_centered()


func _on_import_file_dialog_file_selected(path: String) -> void:
	print(path)


func _on_scan_file_dialog_dir_selected(dir: String) -> void:
	print(dir)
