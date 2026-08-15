extends "res://src/page/download/downloader/downloader_card.gd"

var engine_id: String = ""
var architecture: String = ""

func _handle_data() -> bool:
	if (engine_id == ""
			or architecture == ""
			or url == ""):
		return false
	download_task_name = "%s:%s" % [engine_id, architecture]
	# 架构写入任务 ID，使同版本的不同架构拥有独立缓存
	download_task_id = encode_id("engine:%s:%s" % [architecture, engine_id])
	cache_path = _download_dir.path_join("%s.tmp" % download_task_id)
	download_path = _download_dir.path_join("%s.zip" % download_task_id)
	target_dir_path = ProjectSettings.globalize_path(
		EngineManager.get_architecture_engine_dir(
		architecture).path_join(engine_id))
	return true

func _pre_extract_file() -> bool:
	var zip: ZIPReader = ZIPReader.new()
	if zip.open(download_path) != OK:
		zip.close()
		return false
	var files: PackedStringArray = zip.get_files()
	if files.size() <= 0:
		zip.close()
		return false
	# 提取前完整校验条目，避免写入一半后才发现越界路径
	for file_path: String in files:
		if DownloadManager.resolve_safe_zip_entry_path(target_dir_path, file_path) == "":
			zip.close()
			return false
	zip.close()
	return true

func _extract_task() -> void:
	var zip: ZIPReader = ZIPReader.new()
	if zip.open(download_path) != OK:
		zip.close()
		_failed.call_deferred()
		return
	var files: PackedStringArray = zip.get_files()
	for file_path: String in files:
		# 写入前重新解析安全路径，不复用未经约束的压缩包条目
		var full_path: String = DownloadManager.resolve_safe_zip_entry_path(
			target_dir_path, file_path)
		if full_path == "":
			zip.close()
			_failed.call_deferred()
			return
		if file_path.ends_with("/"):
			if DirAccess.make_dir_recursive_absolute(full_path) != OK:
				zip.close()
				_failed.call_deferred()
				return
			continue
		if DirAccess.make_dir_recursive_absolute(full_path.get_base_dir()) != OK:
			zip.close()
			_failed.call_deferred()
			return
		var buffer: PackedByteArray = zip.read_file(file_path)
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
