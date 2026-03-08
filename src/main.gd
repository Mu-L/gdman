extends ColorRect

@onready var side_bar: VBoxContainer = $MarginContainer/HBoxContainer/SideBar
@onready var page_container: TabContainer = $MarginContainer/HBoxContainer/PageContainer

@onready var project_nav: Button = $MarginContainer/HBoxContainer/SideBar/ProjectNav
@onready var engine_nav: Button = $MarginContainer/HBoxContainer/SideBar/EngineNav
@onready var compile_nav: Button = $MarginContainer/HBoxContainer/SideBar/CompileNav
@onready var download_nav: Button = $MarginContainer/HBoxContainer/SideBar/DownloadNav
@onready var setting_nav: Button = $MarginContainer/HBoxContainer/SideBar/SettingNav

func _ready() -> void:
	project_nav.disabled = true

func _disable_nav(nav: Button) -> void:
	for nav_item: Control in side_bar.get_children():
		if nav_item is Button:
			nav_item.disabled = false
	nav.disabled = true

func _on_project_nav_pressed() -> void:
	page_container.current_tab = 0
	_disable_nav(project_nav)


func _on_engine_nav_pressed() -> void:
	page_container.current_tab = 1
	_disable_nav(engine_nav)

func _on_compile_nav_pressed() -> void:
	page_container.current_tab = 2
	_disable_nav(compile_nav)


func _on_download_nav_pressed() -> void:
	page_container.current_tab = 3
	_disable_nav(download_nav)


func _on_setting_nav_pressed() -> void:
	page_container.current_tab = 4
	_disable_nav(setting_nav)
