extends PanelContainer

@onready var path_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/PathButton
@onready var bin_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/BinButton
@onready var custom_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CustomButton
@onready var compile_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CompileButton

func _ready() -> void:
	App.fix_button_width(path_button)
	App.fix_button_width(bin_button)
	App.fix_button_width(custom_button)
	App.fix_button_width(compile_button)
