extends "res://src/page/download/downloader/downloader_card.gd"

var file_name: String = ""

func _handle_data() -> bool:
	if (file_name == ""
		or url == ""):
		return false
	download_task_name = file_name
	download_task_id = Marshalls.utf8_to_base64("code:%s:%d" % [
		file_name, Time.get_unix_time_from_system()])
	cache_path = _download_dir.path_join("%s.tmp" % download_task_id)
	download_path = _download_dir.path_join("%s.tar.xz" % download_task_id)
	target_dir_path = ProjectSettings.globalize_path(
		CompileManager.SOURCE_CODE_DIR).path_join(file_name)
	return true

func _extract_task() -> void:
	# tar.xz 交由系统 tar 解压，失败结果延迟回主线程处理
	if OS.execute("tar", ["-xJf", download_path, "-C", target_dir_path]) != OK:
		_failed.call_deferred()
		return
	extracted.emit.call_deferred()

func _succeeded() -> void:
	CompileManager.source_code_added.emit.call_deferred(file_name)
