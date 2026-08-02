extends OptionButton

func _ready() -> void:
	load_engine()
	select(-1)

func select_id(engine_id: String) -> void:
	for i: int in get_item_count():
		if is_item_separator(i) or is_item_disabled(i):
			continue
		if get_item_text(i) == engine_id:
			select(i)
			return
	select(-1)

func load_engine() -> void:
	select(-1)
	clear()
	var engine_ids: Array = EngineManager.local_engines.keys()
	engine_ids.sort()
	engine_ids.reverse()
	for engine_id: String in engine_ids:
		add_item(engine_id)
		var local_engine: EngineManager.LocalEngine = EngineManager.local_engines.get(
			engine_id, null)
		set_item_disabled(get_item_count() - 1,
			local_engine == null or not local_engine.can_run)
