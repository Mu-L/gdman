extends PanelContainer

signal extracted()

var url: String = ""
var file_name: String = ""

var download_path: String = ""
var extract_task_id: int = -1

@onready var title_container: HBoxContainer = $MarginContainer/VBoxContainer/TitleContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleContainer/TitleLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var close_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CloseButton
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var timer: Timer = $Timer

func _ready() -> void:
	if DownloadManager.downloading_task.get(file_name, false):
		queue_free()
		return
	DownloadManager.downloading_task[file_name] = true
	title_container.tooltip_text = url
	title_label.text = file_name
	# Check cached file
	var cached_file_path: String = ProjectSettings.globalize_path(
		DownloadManager.DOWNLOAD_DIR.path_join("%s.zip" % file_name))
	if FileAccess.file_exists(cached_file_path):
		var zip: ZIPReader = ZIPReader.new()
		# Can open and can get files mean valid cached file
		if zip.open(cached_file_path) == OK:
			var files: PackedStringArray = zip.get_files()
			zip.close()
			if files.size() > 0:
				_extract_file(cached_file_path)
				return
	if DirAccess.make_dir_recursive_absolute(DownloadManager.DOWNLOAD_DIR) != OK:
		return
	download_path = ProjectSettings.globalize_path(
		DownloadManager.DOWNLOAD_DIR.path_join("%s.tmp" % file_name))
	http_request.download_file = download_path
	if http_request.request(url) != OK:
		return
	cancel_button.disabled = false
	timer.start()

func _failed() -> void:
	info_label.text = "Failed"
	cancel_button.disabled = false
	timer.stop()
	if (download_path != ""
		and FileAccess.file_exists(download_path)):
		OS.move_to_trash(download_path)
	
func _on_timer_timeout() -> void:
	var total: int = http_request.get_body_size()
	if total <= 0:
		return
	var downloaded: int = http_request.get_downloaded_bytes()
	progress_bar.set_value_no_signal(float(downloaded) / float(total) * 98)
	
	
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	# Check download result
	if (result != HTTPRequest.RESULT_SUCCESS
		or response_code != 200):
		_failed()
		return
	timer.stop()
	progress_bar.set_value_no_signal(98)
	# Rename file
	var new_file_path: String = ProjectSettings.globalize_path(
		DownloadManager.DOWNLOAD_DIR.path_join("%s.zip" % file_name))
	if DirAccess.rename_absolute(download_path, new_file_path) != OK:
		_failed()
		return
	_extract_file(new_file_path)

func _extract_file(file_path: String) -> void:
	progress_bar.set_value_no_signal(99)
	var finish_dir: String = EngineManager.ENGINE_DIR.path_join(file_name)
	if DirAccess.make_dir_recursive_absolute(finish_dir) != OK:
		_failed()
		return
	info_label.text = tr("DOWNLOADER_EXTRACT")
	cancel_button.disabled = true
	extract_task_id = WorkerThreadPool.add_task(_extract_task.bind(file_path, finish_dir))
	
func _extract_task(zip_path: String, output_dir: String) -> void:
	var zip: ZIPReader = ZIPReader.new()
	if zip.open(zip_path) != OK:
		zip.close()
		_failed.call_deferred()
		return
	var files: PackedStringArray = zip.get_files()
	for file_path: String in files:
		if file_path.ends_with("/"):
			if DirAccess.make_dir_recursive_absolute(output_dir.path_join(file_path)) != OK:
				zip.close()
				_failed.call_deferred()
				return
			continue
		var buffer: PackedByteArray = zip.read_file(file_path)
		if buffer.size() > 0:
			var full_path: String = output_dir.path_join(file_path)
			var file: FileAccess = FileAccess.open(full_path, FileAccess.WRITE)
			if file == null:
				zip.close()
				_failed.call_deferred()
				return
			file.store_buffer(buffer)
			file.close()
	zip.close()
	extracted.emit.call_deferred()

func _on_extracted() -> void:
	WorkerThreadPool.wait_for_task_completion(extract_task_id)
	info_label.text = tr("DOWNLOADER_COMPLETE")
	progress_bar.set_value_no_signal(100)
	if (download_path != ""
		and FileAccess.file_exists(download_path)):
		OS.move_to_trash(download_path)
	DownloadManager.downloading_task.erase(file_name)
	close_button.disabled = false
	if Config.delete_download_file:
		var zip_path: String = ProjectSettings.globalize_path(
			DownloadManager.DOWNLOAD_DIR.path_join("%s.zip" % file_name))
		if FileAccess.file_exists(zip_path):
			OS.move_to_trash(zip_path)

func _on_cancel_button_pressed() -> void:
	http_request.cancel_request()
	DownloadManager.downloading_task.erase(file_name)
	info_label.text = tr("DOWNLOADER_CANCEL")
	close_button.disabled = false
	cancel_button.disabled = true


func _on_close_button_pressed() -> void:
	queue_free()
