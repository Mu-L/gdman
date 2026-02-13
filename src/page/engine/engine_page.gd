extends VBoxContainer

const ENGINE_CARD: PackedScene = preload("uid://bu4qc2q2pjb0t")

@onready var card_container: GridContainer = $PanelContainer/ScrollContainer/MarginContainer/CardContainer

@onready var standard_check: CheckBox = $HBoxContainer/StandardCheck
@onready var dotnet_check: CheckBox = $HBoxContainer/DotnetCheck
@onready var stable_check: CheckBox = $HBoxContainer/StableCheck
@onready var unstable_check: CheckBox = $HBoxContainer/UnstableCheck

func _ready() -> void:
	_load_engine()
	standard_check.toggled.connect(_switch_display)
	dotnet_check.toggled.connect(_switch_display)
	stable_check.toggled.connect(_switch_display)
	unstable_check.toggled.connect(_switch_display)
	_switch_display(false)

func _load_engine() -> void:
	for card: Control in card_container.get_children():
		card.queue_free()
	var engine_ids: Array = EngineManager.local_engines.keys()
	engine_ids.sort()
	engine_ids.reverse()
	for local_engine_id: String in engine_ids:
		var local_engine: EngineManager.LocalEngine = EngineManager.local_engines.get(local_engine_id, null)
		if local_engine == null:
			continue
		var card: Control = ENGINE_CARD.instantiate()
		card.engine_id = local_engine.info.id
		card.dir_path = local_engine.dir_path
		card.executable_path = local_engine.executable_path
		card_container.add_child(card)

func _switch_display(_pass: bool) -> void:
	for card in card_container.get_children():
		var match_type: bool = (standard_check.button_pressed and not card.is_dotnet) or (dotnet_check.button_pressed and card.is_dotnet)
		var match_stability: bool = (stable_check.button_pressed and card.is_stable) or (unstable_check.button_pressed and not card.is_stable)
		card.visible = match_type and match_stability

func _on_refresh_button_pressed() -> void:
	_load_engine()
