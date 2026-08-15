extends VBoxContainer

const VERSION_CONTAINER: PackedScene = preload("uid://byfxbqtgp68d")
const ENGINE_DOWNLOADER_CARD: PackedScene = preload("uid://dqqd7c1vpwb5y")
const CODE_DOWNLOADER_CARD: PackedScene = preload("uid://df2xo4wx3n3rc")

@onready var engine_download_dialog: ConfirmationDialog = $EngineDownloadDialog
@onready var code_download_dialog: ConfirmationDialog = $OptionContainer/CodeDownloadButton/CodeDownloadDialog

@onready var standard_check: CheckBox = $OptionContainer/StandardCheck
@onready var dotnet_check: CheckBox = $OptionContainer/DotnetCheck
@onready var stable_check: CheckBox = $OptionContainer/StableCheck
@onready var unstable_check: CheckBox = $OptionContainer/UnstableCheck
@onready var code_download_button: Button = $OptionContainer/CodeDownloadButton
@onready var update_prompt_button: LinkButton = $OptionContainer/UpdatePromptButton

@onready var card_container: VBoxContainer = $HSplitContainer/PanelContainer/MarginContainer/ScrollContainer/CardContainer
@onready var downloader_container: VBoxContainer = $HSplitContainer/PanelContainer2/MarginContainer/ScrollContainer/DownloaderContainer

var version_request: Array[String] = []

func _ready() -> void:
	set_process(false)
	update_prompt_button.hide()
	DownloadManager.source_updated.connect(_on_source_updated)
	_load_version()
	DownloadManager.source_loaded.connect(_load_version)
	_handle_component()
	Config.config_updated.connect(_config_update)

func _on_source_updated() -> void:
	if is_visible_in_tree():
		update_prompt_button.show()
	else:
		DownloadManager.load_source()

func _process(_delta: float) -> void:
	if version_request.size() <= 0:
		set_process(false)
	else:
		# 每帧只创建一个版本容器，避免大量节点同时实例化
		_add_version_container(version_request.pop_back())

func _load_version() -> void:
	for container: Control in card_container.get_children():
		container.queue_free()
	version_request.clear()
	for version: String in DownloadManager.valid_version.keys():
		version_request.append(version)
	# 待处理列表作为栈使用，反转后从新版本开始加载
	version_request.reverse()
	set_process(true)

func _add_version_container(version: String) -> void:
	var container: Control = VERSION_CONTAINER.instantiate()
	container.title = version
	container.download.connect(_on_version_container_download)
	card_container.add_child.call_deferred(container)

func _config_update(config_name: String) -> void:
	match config_name:
		"language":
			_handle_component()

func _handle_component() -> void:
	App.fix_button_width(code_download_button)

func _on_version_container_download(engine_id: String) -> void:
	engine_download_dialog.title = tr("DOWNLOAD_DIALOG_TITLE") % engine_id
	engine_download_dialog.display(engine_id)

func _switch_display() -> void:
	var version_containers: Array[Node] = get_tree().get_nodes_in_group("download_version_container")
	for container: Control in version_containers:
		container.switch_display()

func _on_engine_download_dialog_download(url: String, engine_id: String) -> void:
	var downloader_card: Control = ENGINE_DOWNLOADER_CARD.instantiate()
	downloader_card.url = url
	downloader_card.engine_id = engine_id
	# 固定任务创建时的架构，后续设置变化不应改变下载目标
	downloader_card.architecture = Config.get_architecture()
	downloader_container.add_child(downloader_card)


func _on_code_download_button_pressed() -> void:
	code_download_dialog.display()


func _on_code_download_dialog_download(url: String, file_name: String) -> void:
	var downloader_card: Control = CODE_DOWNLOADER_CARD.instantiate()
	downloader_card.url = url
	downloader_card.file_name = file_name
	downloader_container.add_child(downloader_card)


func _on_standard_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_standard = toggled_on
	_switch_display()


func _on_dotnet_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_dotnet = toggled_on
	_switch_display()


func _on_stable_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_stable = toggled_on
	_switch_display()


func _on_unstable_check_toggled(toggled_on: bool) -> void:
	DownloadManager.display_unstable = toggled_on
	_switch_display()
