extends PanelContainer

signal extracted()

var url: String = ""

var download_task_id: String = "" # 用于下载任务的唯一标识，防止重复下载
var download_task_name: String = "" # 用于显示的下载任务名称
var cache_path: String = "" # 下载文件的临时路径
var download_path: String = "" # 下载完成后更名为该路径
var target_dir_path: String = "" # 提取目标路径

var _download_dir: String = DownloadManager.DOWNLOAD_DIR

var extract_task_id: int = -1

@onready var download_icon: TextureRect = $MarginContainer/VBoxContainer/TitleContainer/DownloadIcon
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleContainer/TitleLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoContainer/InfoLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/TitleContainer/CloseButton
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/InfoContainer/CancelButton
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var timer: Timer = $Timer

func _ready() -> void:
	_download_dir = ProjectSettings.globalize_path(DownloadManager.DOWNLOAD_DIR)
	_handle_component()
	Config.config_updated.connect(_config_update)
	if DirAccess.make_dir_recursive_absolute(DownloadManager.DOWNLOAD_DIR) != OK:
		_failed()
		return
	if not _handle_data() or not App.is_valid_url(url):
		queue_free()
		return
	# 以任务 ID 互斥，防止多个卡片并发写入同一缓存
	if DownloadManager.downloading_task.get(download_task_id, false):
		queue_free()
		return
	DownloadManager.downloading_task[download_task_id] = true
	download_icon.tooltip_text = url
	title_label.text = download_task_name
	title_label.tooltip_text = download_task_id
	# 完整缓存可直接进入提取流程，临时文件不会走到此分支
	if FileAccess.file_exists(download_path):
		_extract_file()
		return
	http_request.download_file = cache_path
	if http_request.request(url) != OK:
		_failed()
		return
	cancel_button.disabled = false
	timer.start()
	info_label.text = tr("DOWNLOADER_DOWNLOAD")

func _config_update(config_name: String) -> void:
	match config_name:
		"language":
			_handle_component()

func _handle_component() -> void:
	App.fix_button_width(cancel_button)

# 子类在下载前生成任务标识和全部路径
func _handle_data() -> bool:
	return false

func _failed(info: String = "") -> void:
	info_label.text = tr("DOWNLOADER_FAIL")
	info_label.tooltip_text = info
	cancel_button.disabled = true
	close_button.disabled = false
	timer.stop()
	DownloadManager.downloading_task.erase(download_task_id)
	if FileAccess.file_exists(download_path):
		App.remove_file(download_path)
	if FileAccess.file_exists(cache_path):
		App.remove_file(cache_path)
	

func _on_timer_timeout() -> void:
	var total: int = http_request.get_body_size()
	if total <= 0:
		return
	progress_bar.set_value_no_signal(
		float(http_request.get_downloaded_bytes()) / float(total) * 99)
	
	
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	timer.stop()
	cancel_button.disabled = true
	if (result != HTTPRequest.RESULT_SUCCESS
		or response_code != 200):
		_failed()
		return
	# 改名后才将临时文件视为可复用的完整缓存
	if DirAccess.rename_absolute(cache_path, download_path) != OK:
		_failed()
		return
	_extract_file()

func _extract_file() -> void:
	progress_bar.set_value_no_signal(99)
	info_label.text = tr("DOWNLOADER_EXTRACT")
	if (not _pre_extract_file()
		or DirAccess.make_dir_recursive_absolute(target_dir_path) != OK):
		_failed()
		return
	extract_task_id = WorkerThreadPool.add_task(_extract_task)

# 子类在创建目标目录前完成格式和路径安全校验
func _pre_extract_file() -> bool:
	return true

# 提取任务，必须在子线程中执行
func _extract_task() -> void:
	pass

func _on_extracted() -> void:
	WorkerThreadPool.wait_for_task_completion(extract_task_id)
	DownloadManager.downloading_task.erase(download_task_id)
	progress_bar.set_value_no_signal(100)
	info_label.text = tr("DOWNLOADER_COMPLETE")
	if (Config.delete_download_file
		and FileAccess.file_exists(download_path)):
		App.remove_file(download_path)
	close_button.disabled = false
	_succeeded()

func _succeeded() -> void:
	pass
	

func _on_cancel_button_pressed() -> void:
	http_request.cancel_request()
	DownloadManager.downloading_task.erase(download_task_id)
	info_label.text = tr("DOWNLOADER_CANCEL")
	close_button.disabled = false
	cancel_button.disabled = true
	if (download_path != ""
		and FileAccess.file_exists(download_path)):
		App.remove_file(download_path)


func _on_close_button_pressed() -> void:
	queue_free()

func encode_id(raw_id: String) -> String:
	# 转为 Base64（文本编码），避免任务 ID 中的字符污染缓存文件名
	return Marshalls.utf8_to_base64(raw_id)

func decode_id(encoded_id: String) -> String:
	# 从缓存文件名恢复原始任务 ID
	return Marshalls.base64_to_utf8(encoded_id)

func _pass() -> void:
	extracted.emit()
