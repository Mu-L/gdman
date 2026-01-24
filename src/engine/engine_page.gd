extends VBoxContainer

const ENGINE_CARD: PackedScene = preload("uid://bu4qc2q2pjb0t")

@onready var card_container: VBoxContainer = $ScrollContainer/CardContainer
@onready var refresh_button: Button = $TopBarContainer/OptionContainer/RefreshButton

func _ready() -> void:
	_load_engine()

func _load_engine() -> void:
	refresh_button.disabled = true
	var engine_dir: DirAccess = DirAccess.open(App.ENGINE_DIR)
	if engine_dir == null:
		return
	for dir_name: String in engine_dir.get_directories():
		var info: PackedStringArray = dir_name.split("-")
		if info.size() == 2:
			pass
		elif info.size() == 3:
			pass
		else:
			continue


func _on_refresh_button_pressed() -> void:
	_load_engine()
