extends HBoxContainer

var is_favorite: bool = false
var project_icon_path: String = ""
var project_name: String = ""
var project_path: String = ""
var project_version: String = ""
var project_tags: Array[String] = []
var last_edited_time: int = 0

@onready var favorite_button: CheckButton = $FavoriteButton
@onready var project_icon: TextureRect = $ProjectIcon
@onready var name_label: Label = $InfoContainer/MarkContainer/NameLabel
@onready var tag_container: HBoxContainer = $InfoContainer/MarkContainer/TagContainer
@onready var path_button: TextureButton = $InfoContainer/FeatherContainer/PathButton
@onready var path_label: Label = $InfoContainer/FeatherContainer/PathLabel
@onready var version_label: Label = $InfoContainer/FeatherContainer/VersionLabel
@onready var time_label: Label = $InfoContainer/FeatherContainer/TimeLabel
@onready var edit_button: Button = $EditButton
@onready var extra_button: MenuButton = $ExtraButton

func _ready() -> void:
	favorite_button.button_pressed = is_favorite
	if project_icon_path != "":
		var icon_texture: Texture = load(project_icon_path)
		if icon_texture != null:
			project_icon.texture = icon_texture
	name_label.text = project_name
	for tag_text: String in project_tags:
		pass
	path_label.text = project_path
	version_label.text = project_version
	var time_dict: Dictionary = Time.get_date_dict_from_unix_time(last_edited_time)
	time_label.text = "%d/%d/%d-%d:%d:%d" % [
		time_dict.get("year", 1970),
		time_dict.get("month", 1),
		time_dict.get("day", 1),
		time_dict.get("hour", 0),
		time_dict.get("minute", 0),
		time_dict.get("second", 0),
	]
