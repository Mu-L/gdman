extends ConfirmationDialog

const GODOT_SOURCE_INDEX: int = 0
const GITHUB_SOURCE_INDEX: int = 1

signal download(url: String, engine_id: String)

var last_engine_id: String = ""

var url_dict: Dictionary[int, String] = {}

@onready var godot_ping_display: HBoxContainer = $VBoxContainer/PingContainer/GodotPingDisplay
@onready var git_hub_ping_display: HBoxContainer = $VBoxContainer/PingContainer/GitHubPingDisplay

@onready var ping_container: VBoxContainer = $VBoxContainer/PingContainer
@onready var source_option: OptionButton = $VBoxContainer/HBoxContainer/SourceOption
@onready var url_line: LineEdit = $VBoxContainer/HBoxContainer/UrlLine

func display(engine_id: String) -> void:
	if last_engine_id == engine_id:
		popup_centered()
		return
	last_engine_id = engine_id
	title = tr("DOWNLOAD_DIALOG_TITLE") % engine_id
	get_ok_button().disabled = true
	url_line.text = ""
	url_line.tooltip_text = ""
	url_dict.clear()
	url_dict[GODOT_SOURCE_INDEX] = DownloadManager.get_source_url_by_id(engine_id, "godot")
	url_dict[GITHUB_SOURCE_INDEX] = DownloadManager.get_source_url_by_id(engine_id, "github")
	source_option.set_item_disabled(GODOT_SOURCE_INDEX, url_dict[GODOT_SOURCE_INDEX] == "")
	source_option.set_item_disabled(GITHUB_SOURCE_INDEX, url_dict[GITHUB_SOURCE_INDEX] == "")
	godot_ping_display.ping(url_dict[GODOT_SOURCE_INDEX])
	git_hub_ping_display.ping(url_dict[GITHUB_SOURCE_INDEX])
	popup_centered()

func _on_source_option_item_selected(index: int) -> void:
	match index:
		GODOT_SOURCE_INDEX:
			url_line.text = url_dict[GODOT_SOURCE_INDEX]
		GITHUB_SOURCE_INDEX:
			url_line.text = url_dict[GITHUB_SOURCE_INDEX]
		_:
			url_line.text = ""
	url_line.tooltip_text = url_line.text
	get_ok_button().disabled = not App.is_valid_url(url_line.text)

func _on_confirmed() -> void:
	download.emit(url_line.text, last_engine_id)
