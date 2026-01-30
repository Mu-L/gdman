extends OptionButton

func _ready() -> void:
	load_engine()

func select_id(engine_id: String) -> void:
	for i: int in get_item_count():
		if is_item_separator(i) or is_item_disabled(i):
			continue
		if get_item_text(i) == engine_id:
			select(i)
			return

func load_engine() -> void:
	clear()
	for engine_id: String in EngineManager.local_engines.keys():
		add_item(engine_id)
