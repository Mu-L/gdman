@tool
extends Button

enum FitMode {
	NONE,
	FIT_WIDTH,
	FIT_HEIGHT,
}

@export var fit_mode: FitMode = FitMode.NONE:
	set(v):
		fit_mode = v
		if Engine.is_editor_hint() and is_node_ready():
			match fit_mode:
				FitMode.NONE:
					custom_minimum_size = Vector2.ZERO
				FitMode.FIT_WIDTH:
					custom_minimum_size = Vector2(size.y, 0)
				FitMode.FIT_HEIGHT:
					custom_minimum_size = Vector2(0, size.x)

@export var image: Texture2D:
	set(v):
		image = v
		if Engine.is_editor_hint() and is_node_ready():
			texture_rect.texture = image

@export var margin_left: int = 1:
	set(v):
		margin_left = v
		if Engine.is_editor_hint() and is_node_ready():
			margin_container.add_theme_constant_override("margin_left", margin_left)
@export var margin_top: int = 1:
	set(v):
		margin_top = v
		if Engine.is_editor_hint() and is_node_ready():
			margin_container.add_theme_constant_override("margin_top", margin_top)
@export var margin_right: int = 1:
	set(v):
		margin_right = v
		if Engine.is_editor_hint() and is_node_ready():
			margin_container.add_theme_constant_override("margin_right", margin_right)
@export var margin_bottom: int = 1:
	set(v):
		margin_bottom = v
		if Engine.is_editor_hint() and is_node_ready():
			margin_container.add_theme_constant_override("margin_bottom", margin_bottom)

@onready var margin_container: MarginContainer = $MarginContainer
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

func _ready() -> void:
	match fit_mode:
		FitMode.NONE:
			custom_minimum_size = Vector2.ZERO
		FitMode.FIT_WIDTH:
			custom_minimum_size = Vector2(size.y, 0)
		FitMode.FIT_HEIGHT:
			custom_minimum_size = Vector2(0, size.x)
	margin_container.add_theme_constant_override("margin_left", margin_left)
	margin_container.add_theme_constant_override("margin_top", margin_top)
	margin_container.add_theme_constant_override("margin_right", margin_right)
	margin_container.add_theme_constant_override("margin_bottom", margin_bottom)
	texture_rect.texture = image
