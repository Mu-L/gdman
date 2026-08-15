extends Node

const SOURCE_TEMPLATE: Dictionary = {
	"x.y": {
		"x.y.z-stable": {
			"standard": {
				"foo": "fool_url",
				"bar": "bar_url"
			},
			"dotnet": {
				"foo": "fool_url",
				"bar": "bar_url"
			}
		}
	}
}

const DOWNLOAD_DIR: String = "user://.download"
const BUILD_STANDARD: String = "standard"
const BUILD_DOTNET: String = "dotnet"

const SOURCES: Array[String] = ["godot", "github"]
const BUILT_IN_SOURCE_PATH: String = "res://src/global/source/%s.json"
const LOCAL_SOURCE_DIR: String = "user://.source"
const LOCAL_SOURCE_VERSION_PATH: String = "user://.source/version"
const LOCAL_SOURCE_PATH: String = "user://.source/%s.json"
const REMOTE_SOURCE_VERSION_URL: String = "https://api.github.com/repos/hbread00/gdman-source/git/ref/heads/main"
const REMOTE_SOURCE_URL: String = "https://raw.githubusercontent.com/hbread00/gdman-source/main/%s.json"

signal source_loaded()
signal source_updated()

var source: Dictionary = {}
var valid_id: Array[String] = []
var valid_version: Dictionary[String, Array] = {}
var valid_source: Array[String] = []
var downloading_task: Dictionary[String, bool] = {}

var remote_source_version: String = ""
var source_downloaded_data: Dictionary[String, PackedByteArray] = {}
var _remote_source_batch_id: int = 0
var _remote_requests: Array[HTTPRequest] = []

var display_standard: bool = true
var display_dotnet: bool = false
var display_stable: bool = true
var display_unstable: bool = false

func resolve_safe_zip_entry_path(target_root: String, entry_path: String) -> String:
	var normalized_entry: String = entry_path.replace("\\", "/")
	if normalized_entry == "" or normalized_entry.begins_with("/"):
		return ""
	# 显式拒绝 Windows 盘符路径，避免 ZIP 条目覆盖目标目录之外的文件
	if normalized_entry.length() >= 2:
		var drive_letter: int = normalized_entry.unicode_at(0)
		if ((drive_letter >= 65 and drive_letter <= 90)
			or (drive_letter >= 97 and drive_letter <= 122)):
			if normalized_entry.unicode_at(1) == 58:
				return ""
	for character: String in normalized_entry:
		var codepoint: int = character.unicode_at(0)
		if codepoint < 32 or codepoint == 127:
			return ""
	var handled_entry: String = normalized_entry.trim_suffix("/")
	if handled_entry == "":
		return ""
	for segment: String in handled_entry.split("/", false):
		if segment == "." or segment == "..":
			return ""
	var normalized_root: String = target_root.replace("\\", "/").simplify_path().trim_suffix("/")
	var resolved_path: String = normalized_root.path_join(handled_entry).simplify_path()
	# 添加目录分隔符，避免 /target-other 通过 /target 的前缀检查
	if not resolved_path.begins_with(normalized_root + "/"):
		return ""
	return resolved_path

func _ready() -> void:
	load_source()
	Config.config_updated.connect(_config_update)
	_request_remote_source()

func _exit_tree() -> void:
	_clear_remote_requests()

func load_source() -> void:
	source.clear()
	valid_id.clear()
	valid_version.clear()
	valid_source.clear()
	var arch: String = Config.get_architecture()
	for source_name: String in SOURCES:
		var source_path: String = LOCAL_SOURCE_PATH % source_name
		var json: JSON = JSON.new()
		# 本地清单缺失或损坏时回退到内置清单
		if (not FileAccess.file_exists(source_path)
			or json.parse(FileAccess.get_file_as_string(source_path)) != OK):
			source_path = BUILT_IN_SOURCE_PATH % source_name
			if json.parse(FileAccess.get_file_as_string(source_path)) != OK:
				continue
		var source_data: Array = (json.data as Dictionary).get(source_name, [])
		for version_data: Dictionary in source_data:
			var id: String = version_data.get("id", "")
			var base_version: String = version_data.get("base_version", "")
			if id == "" or base_version == "":
				continue
			if id not in valid_id:
				valid_id.append(id)
			if version_data.has(BUILD_STANDARD):
				var standard_url: String = version_data[BUILD_STANDARD].get(arch, "")
				if standard_url != "":
					_add_source(base_version, id, BUILD_STANDARD, source_name, standard_url)
			if version_data.has(BUILD_DOTNET):
				var dotnet_url: String = version_data[BUILD_DOTNET].get(arch, "")
				if dotnet_url != "":
					_add_source(base_version, id, BUILD_DOTNET, source_name, dotnet_url)
	_sort_valid_version()
	source_loaded.emit()

func _config_update(config_name: String) -> void:
	match config_name:
		"architecture":
			load_source()
		"remote_source":
			_request_remote_source()
	

func _add_source(base_version: String, id: String, build_type: String, source_name: String, url: String) -> void:
	if not source.has(base_version):
		source[base_version] = {}
	if not source[base_version].has(id):
		source[base_version][id] = {}
	if not source[base_version][id].has(build_type):
		source[base_version][id][build_type] = {}
	source[base_version][id][build_type][source_name] = url
	# 记录可展示的版本
	var handled_id: String = id if build_type == BUILD_STANDARD else "%s-dotnet" % id
	if not valid_version.has(base_version):
		valid_version[base_version] = []
	if handled_id not in valid_version[base_version]:
		valid_version[base_version].append(handled_id)
	# 记录实际提供下载地址的来源
	if source_name not in valid_source:
		valid_source.append(source_name)

func _sort_valid_version() -> void:
	var versions: Array[String] = []
	for version: String in valid_version.keys():
		versions.append(version)
	versions.sort_custom(_is_base_version_newer)
	var sorted_valid_version: Dictionary[String, Array] = {}
	for version: String in versions:
		var engine_ids: Array[String] = []
		for engine_id: String in valid_version[version]:
			engine_ids.append(engine_id)
		engine_ids.sort_custom(_is_engine_id_newer)
		sorted_valid_version[version] = engine_ids
	valid_version = sorted_valid_version

func _is_base_version_newer(version_a: String, version_b: String) -> bool:
	return version_a.naturalnocasecmp_to(version_b) > 0

func _is_engine_id_newer(engine_id_a: String, engine_id_b: String) -> bool:
	var info_a: EngineManager.EngineInfo = EngineManager.id_to_engine_info(engine_id_a)
	var info_b: EngineManager.EngineInfo = EngineManager.id_to_engine_info(engine_id_b)
	if info_a == null or info_b == null:
		return engine_id_a.naturalnocasecmp_to(engine_id_b) > 0
	if info_a.major_version != info_b.major_version:
		return info_a.major_version > info_b.major_version
	if info_a.minor_version != info_b.minor_version:
		return info_a.minor_version > info_b.minor_version
	if info_a.patch_version != info_b.patch_version:
		return info_a.patch_version > info_b.patch_version
	# 发布阶段枚举值按 stable 到 dev 排列，较小值代表更新版本
	if info_a.flavor != info_b.flavor:
		return info_a.flavor < info_b.flavor
	if info_a.build != info_b.build:
		return info_a.build > info_b.build
	if info_a.is_dotnet != info_b.is_dotnet:
		return not info_a.is_dotnet
	return engine_id_a.naturalnocasecmp_to(engine_id_b) > 0

func get_source_url(version: String, id: String, is_dotnet: bool, source_name: String) -> String:
	var build_type: String = BUILD_STANDARD
	if is_dotnet:
		build_type = BUILD_DOTNET
	return source.get(version, {}).get(id, {}).get(build_type, {}).get(source_name, "")

func get_source_url_by_id(engine_id: String, source_name: String) -> String:
	var engine_info: EngineManager.EngineInfo = EngineManager.id_to_engine_info(engine_id)
	var handled_id: String = engine_id.replace("-dotnet", "")
	return get_source_url(
		"%d.%d" % [engine_info.major_version, engine_info.minor_version],
		handled_id,
		engine_info.is_dotnet,
		source_name)


func _request_remote_source() -> void:
	# 新批次会令旧回调失效，并释放尚未结束的请求节点
	_remote_source_batch_id += 1
	_clear_remote_requests()
	remote_source_version = ""
	source_downloaded_data.clear()
	if not Config.remote_source:
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOCAL_SOURCE_DIR)) != OK:
		return
	var batch_id: int = _remote_source_batch_id
	var version_request: HTTPRequest = HTTPRequest.new()
	version_request.timeout = 10
	add_child(version_request)
	_remote_requests.append(version_request)
	version_request.request_completed.connect(
		_on_version_request_completed.bind(version_request, batch_id))
	if version_request.request(REMOTE_SOURCE_VERSION_URL) != OK:
		_abort_remote_source_batch(batch_id)


func _on_version_request_completed(result: int, response_code: int, _headers: PackedStringArray,
	body: PackedByteArray, request: HTTPRequest, batch_id: int) -> void:
	_release_remote_request(request)
	if batch_id != _remote_source_batch_id:
		return
	if result != OK or response_code != 200:
		return
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not (json.data is Dictionary):
		return
	remote_source_version = (json.data as Dictionary).get("object", {}).get("sha", "")
	if remote_source_version == "":
		return
	# 本地清单已经对应当前远程提交
	if FileAccess.file_exists(LOCAL_SOURCE_VERSION_PATH):
		var local_version: String = FileAccess.get_file_as_string(LOCAL_SOURCE_VERSION_PATH).strip_edges()
		if remote_source_version == local_version:
			return
	# 仅在版本变化时下载整批来源清单
	for source_name: String in SOURCES:
		var source_url: String = REMOTE_SOURCE_URL % source_name
		var source_request: HTTPRequest = HTTPRequest.new()
		source_request.timeout = 10
		add_child(source_request)
		_remote_requests.append(source_request)
		source_request.request_completed.connect(
			_on_source_request_finished.bind(source_name, source_request, batch_id))
		if source_request.request(source_url) != OK:
			_abort_remote_source_batch(batch_id)
			return

func _on_source_request_finished(result: int, response_code: int, _headers: PackedStringArray,
	body: PackedByteArray, source_name: String, request: HTTPRequest, batch_id: int) -> void:
	_release_remote_request(request)
	if batch_id != _remote_source_batch_id:
		return
	# 任一来源失败都会废弃整批结果
	if result != OK or response_code != 200:
		_abort_remote_source_batch(batch_id)
		return
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not (json.data is Dictionary):
		_abort_remote_source_batch(batch_id)
		return
	# 请求创建时已绑定来源，只接受与请求来源一致的清单结构
	if not (json.data as Dictionary).has(source_name):
		_abort_remote_source_batch(batch_id)
		return
	source_downloaded_data[source_name] = body
	# 收齐全部来源后再写盘，避免单个响应提前触发更新
	if source_downloaded_data.size() == SOURCES.size():
		if not _store_remote_source_data():
			_abort_remote_source_batch(batch_id)
			return
		source_downloaded_data.clear()
		source_updated.emit()

func _store_remote_source_data() -> bool:
	for source_name: String in SOURCES:
		if not source_downloaded_data.has(source_name):
			return false
		var source_file: FileAccess = FileAccess.open(
			LOCAL_SOURCE_PATH % source_name, FileAccess.WRITE)
		if source_file == null:
			return false
		source_file.store_string(source_downloaded_data[source_name].get_string_from_utf8())
		source_file.close()
	# 最后写入版本号，避免不完整清单在下次启动时被视为最新
	var version_file: FileAccess = FileAccess.open(LOCAL_SOURCE_VERSION_PATH, FileAccess.WRITE)
	if version_file == null:
		return false
	version_file.store_string(remote_source_version)
	version_file.close()
	return true

func _release_remote_request(request: HTTPRequest) -> void:
	_remote_requests.erase(request)
	if is_instance_valid(request):
		request.queue_free()

func _clear_remote_requests() -> void:
	for request: HTTPRequest in _remote_requests:
		if is_instance_valid(request):
			request.cancel_request()
			request.queue_free()
	_remote_requests.clear()

func _abort_remote_source_batch(batch_id: int) -> void:
	if batch_id != _remote_source_batch_id:
		return
	# 递增批次号，使尚未返回的同批回调全部失效
	_remote_source_batch_id += 1
	_clear_remote_requests()
	remote_source_version = ""
	source_downloaded_data.clear()
