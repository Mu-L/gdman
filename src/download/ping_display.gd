@tool
extends HBoxContainer

@export var title: String = "ping":
	set(v):
		title = v
		if Engine.is_editor_hint() and is_node_ready():
			title_label.text = title

var start_time: int = 0
@onready var title_label: Label = $TitleLabel
@onready var texture_rect: TextureRect = $TextureRect
@onready var ping_label: Label = $PingLabel
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	title_label.text = title

func ping(url: String) -> void:
	tooltip_text = url
	http_request.cancel_request()
	start_time = Time.get_ticks_msec()
	ping_label.text = "..."
	texture_rect.modulate = Color.BLUE
	if http_request.request(url, [], HTTPClient.METHOD_HEAD) != OK:
		ping_label.text = "x"
		texture_rect.modulate = Color.RED

func _on_http_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code >= 200 and response_code < 400:
		var ping_time: float = float(Time.get_ticks_msec() - start_time) / 10
		ping_label.text = "%s" % roundi(ping_time)
		if ping_time < 100:
			texture_rect.modulate = Color.GREEN
		elif ping_time < 300:
			texture_rect.modulate = Color.YELLOW
		else:
			texture_rect.modulate = Color.ORANGE
