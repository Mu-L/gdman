extends ConfirmationDialog

const PING_DISPLAY: PackedScene = preload("uid://o4df7hsmn462")

signal download(url: String, engine_id: String)

var last_engine_id: String = ""

var ping_display_dict: Dictionary[String, Control] = {}
var url_dict: Dictionary[String, String] = {}

@onready var ping_container: VBoxContainer = $VBoxContainer/PingContainer
@onready var source_option: OptionButton = $VBoxContainer/HBoxContainer/SourceOption
@onready var url_label: Label = $VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/UrlLabel

func _ready() -> void:
	_load_source()
	DownloadManager.source_loaded.connect(_load_source)

func _load_source() -> void:
	for ping_child: Control in ping_container.get_children():
		ping_child.queue_free()
	for source: String in DownloadManager.valid_source:
		var ping_display: Control = PING_DISPLAY.instantiate()
		ping_display.title = source
		ping_container.add_child(ping_display)
		ping_display_dict[source] = ping_display
		source_option.add_item(source)

func display(engine_id: String) -> void:
	if last_engine_id != engine_id:
		last_engine_id = engine_id
		title = "Download %s" % engine_id
		source_option.select(-1)
		get_ok_button().disabled = true
		url_label.text = ""
		for source: String in url_dict.keys():
			url_dict[source] = ""
		for i: int in source_option.get_item_count():
			if source_option.is_item_separator(i):
				continue
			source_option.set_item_disabled(i, true)
			var engine_info: EngineManager.EngineInfo = EngineManager.id_to_engine_info(engine_id)
			var handled_id: String = engine_id.replace("-dotnet", "")
			var url: String = DownloadManager.get_source_url(
				"%d.%d" % [engine_info.major_version, engine_info.minor_version],
				handled_id,
				engine_info.is_dotnet,
				source_option.get_item_text(i))
			if url != "":
				source_option.set_item_disabled(i, false)
				url_dict[source_option.get_item_text(i)] = url
				ping_display_dict[source_option.get_item_text(i)].ping(url)
	popup_centered()

func _on_source_option_item_selected(index: int) -> void:
	var url: String = url_dict.get(source_option.get_item_text(index), "")
	url_label.text = url
	if url == "":
		get_ok_button().disabled = true
	else:
		get_ok_button().disabled = false


func _on_confirmed() -> void:
	var url: String = url_dict.get(source_option.get_item_text(source_option.get_selected()), "")
	download.emit(url, last_engine_id)
