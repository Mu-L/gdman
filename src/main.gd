extends ColorRect

const ENGINE_PAGE_PATH: String = "res://src/page/engine/engine_page.tscn"
const COMPILE_PAGE_PATH: String = "res://src/page/compile/compile_page.tscn"
const DOWNLOAD_PAGE_PATH: String = "res://src/page/download/download_page.tscn"
const SETTING_PAGE_PATH: String = "res://src/page/setting/setting_page.tscn"
const PAGE_PATH_LIST: Array[String] = [
	ENGINE_PAGE_PATH,
	COMPILE_PAGE_PATH,
	DOWNLOAD_PAGE_PATH,
	SETTING_PAGE_PATH,
]

@onready var side_bar: VBoxContainer = $MarginContainer/HBoxContainer/SideBar
@onready var page_container: TabContainer = $MarginContainer/HBoxContainer/PageContainer

@onready var project_nav: Button = $MarginContainer/HBoxContainer/SideBar/ProjectNav
@onready var engine_nav: Button = $MarginContainer/HBoxContainer/SideBar/EngineNav
@onready var compile_nav: Button = $MarginContainer/HBoxContainer/SideBar/CompileNav
@onready var download_nav: Button = $MarginContainer/HBoxContainer/SideBar/DownloadNav
@onready var setting_nav: Button = $MarginContainer/HBoxContainer/SideBar/SettingNav

var page_request: Array[String] = []
var pending_tab: int = -1
var pending_nav: Button = null

func _ready() -> void:
	set_process(false)
	project_nav.disabled = true
	_load_page()

func _process(_delta: float) -> void:
	if page_request.is_empty():
		set_process(false)
		return
	# 只消费队首，保证页面添加顺序与导航索引一致
	var page_path: String = page_request[0]
	var load_status: int = ResourceLoader.load_threaded_get_status(page_path)
	match load_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			var page_resource: Resource = ResourceLoader.load_threaded_get(page_path)
			if not (page_resource is PackedScene):
				_handle_page_load_failure(page_path, ResourceLoader.THREAD_LOAD_FAILED)
				return
			page_request.remove_at(0)
			_add_page(page_resource as PackedScene)
			if page_request.is_empty():
				set_process(false)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_handle_page_load_failure(page_path, load_status)

func _load_page() -> void:
	page_request.clear()
	for page_path: String in PAGE_PATH_LIST:
		var error: Error = ResourceLoader.load_threaded_request(page_path)
		if error != OK:
			_handle_page_load_failure(page_path, error)
			return
		page_request.append(page_path)
	set_process(not page_request.is_empty())

func _add_page(page_scene: PackedScene) -> void:
	var page: Control = page_scene.instantiate()
	page_container.add_child(page)
	_switch_pending_page()

func _handle_page_load_failure(page_path: String, error: int) -> void:
	push_error("页面资源加载失败：%s（错误码：%d）" % [page_path, error])
	page_request.clear()
	pending_tab = -1
	pending_nav = null
	set_process(false)

func _disable_nav(nav: Button) -> void:
	for nav_item: Control in side_bar.get_children():
		if nav_item is Button:
			nav_item.disabled = false
	nav.disabled = true

func _request_page(tab: int, nav: Button) -> void:
	# 目标页面可能仍在异步加载，先保存用户的导航意图
	pending_tab = tab
	pending_nav = nav
	_switch_pending_page()

func _switch_pending_page() -> void:
	if pending_nav == null or pending_tab < 0:
		return
	if pending_tab >= page_container.get_child_count():
		return
	page_container.current_tab = pending_tab
	_disable_nav(pending_nav)
	pending_tab = -1
	pending_nav = null

func _on_project_nav_pressed() -> void:
	_request_page(0, project_nav)


func _on_engine_nav_pressed() -> void:
	_request_page(1, engine_nav)

func _on_compile_nav_pressed() -> void:
	_request_page(2, compile_nav)


func _on_download_nav_pressed() -> void:
	_request_page(3, download_nav)


func _on_setting_nav_pressed() -> void:
	_request_page(4, setting_nav)
