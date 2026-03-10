extends PanelContainer

signal extracted()

var url: String = ""

var download_task_id: String = "" # 用于下载任务的唯一标识，防止重复下载
var cache_path: String = "" # 下载文件的临时路径
var download_path: String = "" # 下载完成后更名为该路径
var target_dir_path: String = "" # 提取目标路径

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
	_handle_component()
	Config.config_updated.connect(_config_update)
	if DirAccess.make_dir_recursive_absolute(DownloadManager.DOWNLOAD_DIR) != OK:
		_failed()
		return
	if not _handle_data():
		queue_free()
		return
	# 重复任务检查
	if DownloadManager.downloading_task.get(download_task_id, false):
		queue_free()
		return
	DownloadManager.downloading_task[download_task_id] = true
	download_icon.tooltip_text = url
	title_label.text = download_task_id
	title_label.tooltip_text = download_task_id
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

# 数据预处理，返回是否成功
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

func _pre_extract_file() -> bool:
	return true

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

func _pass() -> void:
	extracted.emit()
