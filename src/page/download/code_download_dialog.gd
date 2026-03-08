extends ConfirmationDialog

const SOURCE_CODE_URL: String = "https://github.com/godotengine/godot-builds/releases/download/%s/godot-%s.tar.xz"

var valid_name_regex: RegEx = RegEx.new()

# https://help.interfaceware.com/v6/windows-reserved-file-names
const WINDOWS_RESERVED_FILE_NAMES: PackedStringArray = [
	"CON",
	"PRN",
	"AUX",
	"NUL",
	"COM1",
	"COM2",
	"COM3",
	"COM4",
	"COM5",
	"COM6",
	"COM7",
	"COM8",
	"COM9",
	"COM0",
	"LPT1",
	"LPT2",
	"LPT3",
	"LPT4",
	"LPT5",
	"LPT6",
	"LPT7",
	"LPT8",
	"LPT9",
	"LPT0"
]

signal download(url: String, file_name: String)

@onready var file_name_line: LineEdit = $VBoxContainer/FileNameLine
@onready var url_line: LineEdit = $VBoxContainer/HBoxContainer/URLLine
@onready var version_option: OptionButton = $VBoxContainer/HBoxContainer/VersionOption

func _ready() -> void:
	valid_name_regex.compile("^[\\p{L}\\p{N} ]+$")
	for id: String in DownloadManager.valid_id:
		version_option.add_item(id)

func display() -> void:
	file_name_line.text = ""
	url_line.text = ""
	version_option.select(0)
	url_line.editable = true
	_handle_ok()
	popup_centered()

func _is_valid_file_name(file_name: String) -> bool:
	if file_name == "":
		return false
	if file_name.length() > 200:
		return false
	# Windows保留名
	if WINDOWS_RESERVED_FILE_NAMES.has(file_name.to_upper()):
		return false
	if valid_name_regex.search(file_name) == null:
		return false
	return true

func _on_option_button_item_selected(index: int) -> void:
	url_line.editable = index == 0
	if index != 0:
		var version_id: String = version_option.get_item_text(index)
		url_line.text = SOURCE_CODE_URL % [version_id, version_id]
		url_line.tooltip_text = url_line.text
		url_line.text_changed.emit(url_line.text)
	else:
		url_line.tooltip_text = ""

func _handle_ok() -> void:
	var name_text: String = file_name_line.text.strip_edges()
	var url_text: String = url_line.text.strip_edges()
	get_ok_button().disabled = not (_is_valid_file_name(name_text)
		and App.is_valid_url(url_text))

func _on_url_line_text_changed(_new_text: String) -> void:
	_handle_ok()

func _on_file_name_line_text_changed(_new_text: String) -> void:
	_handle_ok()


func _on_confirmed() -> void:
	download.emit(url_line.text.strip_edges(), file_name_line.text.strip_edges())
