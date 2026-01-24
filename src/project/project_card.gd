extends HBoxContainer

const PROJECT_TAG: PackedScene = preload("res://src/project/project_tag.tscn")

var is_favorite: bool = false
var project_icon_path: String = ""
var project_name: String = ""
var project_path: String = ""
var project_version: String = ""
var project_tags: Array[String] = []
var last_edited_time: int = 0

@onready var favorite_button: CheckButton = $VBoxContainer/FavoriteButton
@onready var confirmation_dialog: ConfirmationDialog = $VBoxContainer/DeleteButton/ConfirmationDialog
@onready var project_icon: TextureRect = $ProjectIcon
@onready var name_label: Label = $VBoxContainer2/HBoxContainer/NameLabel
@onready var tag_container: HBoxContainer = $VBoxContainer2/HBoxContainer/TagContainer
@onready var path_label: Label = $VBoxContainer2/HBoxContainer2/PathLabel
@onready var version_label: Label = $VBoxContainer2/HBoxContainer2/VersionLabel
@onready var time_label: Label = $VBoxContainer2/HBoxContainer2/TimeLabel

func _ready() -> void:
	favorite_button.button_pressed = is_favorite
	if project_icon_path != "":
		var img: Image = Image.new()
		if img.load(project_icon_path) == OK:
			project_icon.texture = ImageTexture.create_from_image(img)
	name_label.text = project_name
	for tag_text: String in project_tags:
		var tag: Control = PROJECT_TAG.instantiate()
		tag.text = tag_text
		tag_container.add_child(tag)
	path_label.text = project_path
	version_label.text = project_version
	var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(last_edited_time)
	time_label.text = "%d/%d/%d-%0d:%0d:%0d" % [
		time_dict.get("year", 1970),
		time_dict.get("month", 1),
		time_dict.get("day", 1),
		time_dict.get("hour", 0),
		time_dict.get("minute", 0),
		time_dict.get("second", 0),
	]


func _on_delete_button_pressed() -> void:
	confirmation_dialog.popup_centered()


func _on_confirmation_dialog_confirmed() -> void:
	pass # Replace with function body.


func _on_path_button_pressed() -> void:
	OS.shell_open(project_path)
