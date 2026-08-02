extends VBoxContainer

const PROJECT_CARD_PATH: String = "res://src/page/project/project_card.tscn"

@onready var import_button: Button = $HBoxContainer/ImportButton
@onready var import_file_dialog: FileDialog = $HBoxContainer/ImportButton/ImportFileDialog
@onready var card_container: GridContainer = $PanelContainer/ScrollContainer/MarginContainer/CardContainer

var project_request: Array[String] = []
var project_card_scene: PackedScene = null
var project_card_requested: bool = false

func _ready() -> void:
	set_process(false)
	_load_project()
	_request_project_card()
	EngineManager.engines_loaded.connect(_refresh_project_engines)
	_handle_component()
	Config.config_updated.connect(_config_update)

func _process(_delta: float) -> void:
	if project_card_scene == null:
		if not project_card_requested:
			return
		var load_status: int = ResourceLoader.load_threaded_get_status(PROJECT_CARD_PATH)
		match load_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				return
			ResourceLoader.THREAD_LOAD_LOADED:
				var card_resource: Resource = ResourceLoader.load_threaded_get(PROJECT_CARD_PATH)
				if not (card_resource is PackedScene):
					_handle_project_card_load_failure(ResourceLoader.THREAD_LOAD_FAILED)
					return
				project_card_scene = card_resource as PackedScene
				project_card_requested = false
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_handle_project_card_load_failure(load_status)
				return
	if project_request.is_empty():
		import_button.disabled = false
		set_process(false)
	else:
		_add_project_card(project_request.pop_back())

func _load_project() -> void:
	import_button.disabled = true
	for card: Control in card_container.get_children():
		card.queue_free()
	project_request = ProjectManager.project_info.keys()

func _request_project_card() -> void:
	var error: Error = ResourceLoader.load_threaded_request(PROJECT_CARD_PATH)
	if error != OK:
		_handle_project_card_load_failure(error)
		return
	project_card_requested = true
	set_process(true)

func _handle_project_card_load_failure(error: int) -> void:
	push_error("项目卡片资源加载失败（错误码：%d）" % error)
	project_card_requested = false
	project_request.clear()
	set_process(false)

func _add_project_card(project_path: String) -> void:
	var project: ProjectManager.ProjectInfo = ProjectManager.project_info.get(project_path, null)
	if project == null or project_card_scene == null:
		return
	var card: Control = project_card_scene.instantiate()
	card.project_path = project.path
	card.prefer_engine_id = project.prefer_engine_id
	card_container.add_child.call_deferred(card)

# 页面统一分发刷新，避免每张项目卡片重复连接全局信号
func _refresh_project_engines() -> void:
	for card: Control in card_container.get_children():
		card.refresh_engines()

func _config_update(config_name: String) -> void:
	match config_name:
		"language":
			_handle_component()
			
func _handle_component() -> void:
	App.fix_button_width(import_button)

func _on_import_button_pressed() -> void:
	import_file_dialog.popup_centered()

func _on_import_file_dialog_file_selected(path: String) -> void:
	if not path.ends_with("project.godot"):
		return
	var dir_path: String = path.get_base_dir()
	if ProjectManager.project_info.has(dir_path):
		return
	ProjectManager.add_project(dir_path)
	_add_project_card(dir_path)


func _on_card_spin_value_changed(value: float) -> void:
	card_container.columns = int(value)
