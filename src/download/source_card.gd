extends PanelContainer

const DOTNET: CompressedTexture2D = preload("uid://b5cuh2fee8rn5")

signal download(engine_id: String)

var engine_id: String = ""

var is_stable: bool = false
var is_dotnet: bool = false

@onready var source_icon: TextureRect = $MarginContainer/HBoxContainer/SourceIcon
@onready var name_label: Label = $MarginContainer/HBoxContainer/NameLabel
@onready var id_label: Label = $MarginContainer/HBoxContainer/IDLabel
@onready var unstable_icon: TextureRect = $MarginContainer/HBoxContainer/MarginContainer/UnstableIcon
@onready var download_button: Button = $MarginContainer/HBoxContainer/DownloadButton

func _ready() -> void:
	unstable_icon.hide()
	if engine_id == "":
		return
	var info: EngineManager.EngineInfo = EngineManager.id_to_engine_info(engine_id)
	name_label.text = info.name
	id_label.text = engine_id
	is_stable = info.flavor == EngineManager.EngineFlavor.STABLE
	if not is_stable:
		unstable_icon.show()
	is_dotnet = info.is_dotnet
	if is_dotnet:
		source_icon.texture = DOTNET
	download_button.tooltip_text = tr("SOURCE_CARD_DOWNLOAD_HINT") % engine_id

func _on_download_button_pressed() -> void:
	download.emit(engine_id)
