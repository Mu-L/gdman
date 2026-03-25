extends "res://src/page/download/downloader/downloader_card.gd"

var engine_id: String = ""

func _handle_data() -> bool:
	if (engine_id == ""
		or url == ""):
		return false
	download_task_id = "engine-%s" % engine_id
	var download_dir: String = ProjectSettings.globalize_path(DownloadManager.DOWNLOAD_DIR)
	cache_path = download_dir.path_join("%s.tmp" % download_task_id)
	download_path = download_dir.path_join("%s.zip" % download_task_id)
	target_dir_path = ProjectSettings.globalize_path(
		EngineManager.ENGINE_DIR).path_join(engine_id)
	return true


func _pre_extract_file() -> bool:
	var zip: ZIPReader = ZIPReader.new()
	if zip.open(download_path) == OK:
		var files: PackedStringArray = zip.get_files()
		zip.close()
		if files.size() <= 0:
			return false
	return true

func _extract_task() -> void:
	var zip: ZIPReader = ZIPReader.new()
	if zip.open(download_path) != OK:
		zip.close()
		_failed.call_deferred()
		return
	var files: PackedStringArray = zip.get_files()
	for file_path: String in files:
		if file_path.ends_with("/"):
			if DirAccess.make_dir_recursive_absolute(target_dir_path.path_join(file_path)) != OK:
				zip.close()
				_failed.call_deferred()
				return
			continue
		var buffer: PackedByteArray = zip.read_file(file_path)
		if buffer.size() > 0:
			var full_path: String = target_dir_path.path_join(file_path)
			var file: FileAccess = FileAccess.open(full_path, FileAccess.WRITE)
			if file == null:
				zip.close()
				_failed.call_deferred()
				return
			file.store_buffer(buffer)
			file.close()
	zip.close()
	extracted.emit.call_deferred()

func _succeeded() -> void:
	EngineManager.load_engines.call_deferred()