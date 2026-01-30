extends ColorRect

@onready var page_container: TabContainer = $MarginContainer/HBoxContainer/PageContainer

func _on_project_button_pressed() -> void:
	page_container.current_tab = 0


func _on_engine_button_pressed() -> void:
	page_container.current_tab = 1


func _on_download_button_pressed() -> void:
	page_container.current_tab = 2


func _on_setting_button_pressed() -> void:
	pass # Replace with function body.


func _on_about_button_pressed() -> void:
	pass # Replace with function body.
