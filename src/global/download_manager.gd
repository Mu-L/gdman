extends Node

const MANIFEST_TEMPLATE: Dictionary = {
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
} # 源模板，用于参考

const DOWNLOAD_DIR: String = "user://.download" # 下载文件保存目录
# 构建类型，Godot有标准和 DotNet 两种构建类型
const BUILD_STANDARD: String = "standard"
const BUILD_DOTNET: String = "dotnet"

const PROVIDERS: Array[String] = ["godot", "github"] # 提供下载地址清单的来源
const BUILT_IN_MANIFEST_PATH: String = "res://src/global/source/%s.json" # 项目内置的下载地址清单路径
const LOCAL_MANIFEST_DIR: String = "user://.manifest" # 本地下载地址清单的目录
const LOCAL_MANIFEST_PATH: String = "user://.manifest/%s.json" # 本地下载地址清单路径
const LOCAL_MANIFEST_VERSION_PATH: String = "user://.manifest/version" # 本地下载地址清单版本路径
const REMOTE_MANIFEST_URL: String = "https://raw.githubusercontent.com/hbread00/gdman-source/main/%s.json" # 远程下载地址清单 URL
const REMOTE_MANIFEST_VERSION_URL: String = "https://api.github.com/repos/hbread00/gdman-source/git/ref/heads/main" # 远程下载地址清单版本 URL

signal source_loaded()
signal source_updated()

# 程序中动态生成的下载地址清单
const PROGRAM_MANIFEST_TEMPLATE: Dictionary = {
	"x.y": {
		"x.y.z-stable": {
			"standard": {
				"godot": "godot_url",
				"github": "github_url"
			},
			"dotnet": {
				"godot": "godot_url",
				"github": "github_url"
			}
		}
	}
} # 程序中动态生成的下载地址清单模板
var manifest: Dictionary = {}
var downloading_task: Dictionary[String, bool] = {}

var is_requesting_remote_manifest: bool = false
var remote_version_request: HTTPRequest = null
var remote_manifest_requests: Dictionary[String, HTTPRequest] = {}
var remote_version: String = ""

var display_standard: bool = true
var display_dotnet: bool = false
var display_stable: bool = true
var display_unstable: bool = false

func _ready() -> void:
	load_manifest()
	Config.config_updated.connect(_config_update)
	_request_remote_manifest()

func _exit_tree() -> void:
	if remote_version_request != null:
		remote_version_request.queue_free()
	for provider_name: String in remote_manifest_requests.keys():
		var request: HTTPRequest = remote_manifest_requests[provider_name]
		if request != null:
			request.queue_free()

func _config_update(config_name: String) -> void:
	match config_name:
		"architecture":
			load_manifest()

# 加载下载地址清单
func load_manifest() -> void:
	manifest.clear()
	# 只取所需的架构下载地址
	var arch: String = Config.get_architecture()
	for provider_name: String in PROVIDERS:
		var manifest_path: String = LOCAL_MANIFEST_PATH % provider_name
		var json: JSON = JSON.new()
		# 本地清单缺失或损坏时回退到内置清单
		if (not FileAccess.file_exists(manifest_path)
			or json.parse(FileAccess.get_file_as_string(manifest_path)) != OK):
			manifest_path = BUILT_IN_MANIFEST_PATH % provider_name
			# 内置清单也损坏直接跳过该来源
			if json.parse(FileAccess.get_file_as_string(manifest_path)) != OK:
				continue
		# 解析清单结构，提取可用的版本和下载地址
		if typeof(json.data) != TYPE_ARRAY:
			continue
		for version_data: Dictionary in json.data as Array[Dictionary]:
			var id: String = version_data.get("id", "")
			var base_version: String = version_data.get("base_version", "")
			if id == "" or base_version == "":
				continue
			if version_data.has(BUILD_STANDARD):
				var standard_url: String = version_data[BUILD_STANDARD].get(arch, "")
				if standard_url != "":
					_add_source_to_manifest(base_version, id, BUILD_STANDARD, provider_name, standard_url)
			if version_data.has(BUILD_DOTNET):
				var dotnet_url: String = version_data[BUILD_DOTNET].get(arch, "")
				if dotnet_url != "":
					_add_source_to_manifest(base_version, id, BUILD_DOTNET, provider_name, dotnet_url)
	source_loaded.emit()

# 往程序清单中添加来源的下载地址
func _add_source_to_manifest(base_version: String, id: String, build_type: String, provider: String, url: String) -> void:
	# 在第一次添加来源时创建嵌套字典
	if not manifest.has(base_version):
		manifest[base_version] = {}
	if not manifest[base_version].has(id):
		manifest[base_version][id] = {}
	if not manifest[base_version][id].has(build_type):
		manifest[base_version][id][build_type] = {}
	# 添加来源的下载地址
	manifest[base_version][id][build_type][provider] = url

# 获取指定版本和来源的下载地址
func get_download_url_by_id(engine_id: String, provider: String) -> String:
	var engine_info: EngineManager.EngineInfo = EngineManager.id_to_engine_info(engine_id)
	var handled_id: String = engine_id.replace("-dotnet", "")
	var build_type: String = BUILD_STANDARD if not engine_info.is_dotnet else BUILD_DOTNET
	return manifest.get(engine_info.base_version, {}).get(handled_id, {}).get(build_type, {}).get(provider, "")


func _request_remote_manifest() -> void:
	if is_requesting_remote_manifest:
		return
	is_requesting_remote_manifest = true
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOCAL_MANIFEST_PATH)) != OK:
		is_requesting_remote_manifest = false
		return
	# 先请求远程清单版本号
	var version_request: HTTPRequest = HTTPRequest.new()
	version_request.request_completed.connect(_on_version_request_completed)
	version_request.timeout = 10
	version_request.use_threads = true
	add_child(version_request)
	if version_request.request(REMOTE_MANIFEST_VERSION_URL) == OK:
		remote_version_request = version_request
	else:
		version_request.queue_free()
		is_requesting_remote_manifest = false

func _on_version_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	remote_version_request.queue_free()
	if result != OK or response_code != 200:
		is_requesting_remote_manifest = false
		return
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		is_requesting_remote_manifest = false
		return
	# 对比远程清单版本和本地清单版本
	remote_version = json.data.get("object", {}).get("sha", "")
	if remote_version == "" or remote_version == FileAccess.get_file_as_string(LOCAL_MANIFEST_VERSION_PATH):
		is_requesting_remote_manifest = false
		return
	# 如果不同则请求远程清单
	for provider_name: String in PROVIDERS:
		var manifest_request: HTTPRequest = HTTPRequest.new()
		manifest_request.request_completed.connect(_on_manifest_request_completed)
		manifest_request.timeout = 10
		manifest_request.use_threads = true
		add_child(manifest_request)
		if manifest_request.request(REMOTE_MANIFEST_URL % provider_name) == OK:
			remote_manifest_requests[provider_name] = manifest_request
		else:
			manifest_request.queue_free()
			is_requesting_remote_manifest = false
			break

func _on_manifest_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	pass