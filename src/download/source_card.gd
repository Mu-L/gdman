extends PanelContainer

signal download(version_name: String)

var version_name: String = ""
var is_stable: bool = false

@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var unstable_icon: TextureRect = $HBoxContainer/UnstableIcon

func _ready() -> void:
	if version_name == "":
		return
	var split_name: PackedStringArray = version_name.split("-")
	if split_name.size() != 2:
		return
	var version: String = split_name[0]
	var flavor: String = split_name[1]
	is_stable = flavor == "stable"
	unstable_icon.visible = not is_stable
	var display_name: String = version
	if not is_stable:
		if flavor.begins_with("rc"):
			display_name = "%s RC %s" % [version, flavor.replace("rc", "")]
		elif flavor.begins_with("beta"):
			display_name = "%s Beta %s" % [version, flavor.replace("beta", "")]
		elif flavor.begins_with("dev"):
			display_name = "%s Dev %s" % [version, flavor.replace("dev", "")]
		elif flavor.begins_with("alpha"):
			display_name = "%s Alpha %s" % [version, flavor.replace("alpha", "")]
	name_label.text = display_name
	

func _on_download_button_pressed() -> void:
	download.emit(version_name)
