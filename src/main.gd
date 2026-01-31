extends ColorRect

@onready var page_container: TabContainer = $MarginContainer/HBoxContainer/PageContainer


func _on_project_nav_pressed() -> void:
	page_container.current_tab = 0


func _on_engine_nav_pressed() -> void:
	page_container.current_tab = 1


func _on_download_nav_pressed() -> void:
	page_container.current_tab = 2


func _on_setting_nav_pressed() -> void:
	page_container.current_tab = 3
