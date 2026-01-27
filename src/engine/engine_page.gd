extends VBoxContainer

const ENGINE_CARD: PackedScene = preload("uid://bu4qc2q2pjb0t")

@onready var refresh_button: Button = $HBoxContainer/RefreshButton
@onready var card_container: GridContainer = $PanelContainer/MarginContainer/ScrollContainer/CardContainer

func _ready() -> void:
	_load_engine()

func _load_engine() -> void:
	refresh_button.disabled = true
	for card: Control in card_container.get_children():
		card.queue_free()
	for local_engine: EngineManager.LocalEngine in EngineManager.local_engines:
		var card: Control = ENGINE_CARD.instantiate()
		card.engine_id = local_engine.info.id
		card.display_name = local_engine.info.name
		card.version = "%d.%d" % [local_engine.info.major_version, local_engine.info.minor_version]
		card.dir_path = local_engine.dir_path
		card.is_dotnet = local_engine.info.is_dotnet
		card.executable_path = local_engine.executable_path
		card_container.add_child(card)
	refresh_button.disabled = false

func _on_refresh_button_pressed() -> void:
	_load_engine()
