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
var valid_version: Dictionary[String, Array] = {}
var valid_source: Array[String] = []
var downloading_task: Dictionary[String, bool] = {}

var remote_source_version: String = ""
var source_need_download_count: int = 0
var source_downloaded_count: int = 0
var source_downloaded_data: Dictionary[String, PackedByteArray] = {}

func _ready() -> void:
	load_source()
	Config.config_updated.connect(_config_update)
	_request_remote_source()

func load_source() -> void:
	source.clear()
	valid_version.clear()
	valid_source.clear()
	var arch: String = Config.get_architecture()
	for source_name: String in SOURCES:
		var source_path: String = LOCAL_SOURCE_PATH % source_name
		var json: JSON = JSON.new()
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
			if version_data.has(BUILD_STANDARD):
				var standard_url: String = version_data[BUILD_STANDARD].get(arch, "")
				if standard_url != "":
					_add_source(base_version, id, BUILD_STANDARD, source_name, standard_url)
			if version_data.has(BUILD_DOTNET):
				var dotnet_url: String = version_data[BUILD_DOTNET].get(arch, "")
				if dotnet_url != "":
					_add_source(base_version, id, BUILD_DOTNET, source_name, dotnet_url)
	source_loaded.emit()

func _config_update(config_name: String) -> void:
	if config_name == "architecture":
		load_source()

func _add_source(base_version: String, id: String, build_type: String, source_name: String, url: String) -> void:
	if not source.has(base_version):
		source[base_version] = {}
	if not source[base_version].has(id):
		source[base_version][id] = {}
	if not source[base_version][id].has(build_type):
		source[base_version][id][build_type] = {}
	source[base_version][id][build_type][source_name] = url
	# Record valid versions
	var handled_id: String = id if build_type == BUILD_STANDARD else "%s-dotnet" % id
	if not valid_version.has(base_version):
		valid_version[base_version] = []
	if handled_id not in valid_version[base_version]:
		valid_version[base_version].append(handled_id)
	# Record valid sources
	if source_name not in valid_source:
		valid_source.append(source_name)

func get_source_url(version: String, id: String, is_dotnet: bool, source_name: String) -> String:
	var build_type: String = BUILD_STANDARD
	if is_dotnet:
		build_type = BUILD_DOTNET
	return source.get(version, {}).get(id, {}).get(build_type, {}).get(source_name, "")

func _request_remote_source() -> void:
	if not Config.remote_source:
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOCAL_SOURCE_DIR)) != OK:
		return
	var version_request: HTTPRequest = HTTPRequest.new()
	version_request.timeout = 10
	add_child(version_request)
	version_request.request_completed.connect(_on_version_request_completed)
	version_request.request(REMOTE_SOURCE_VERSION_URL)


func _on_version_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		return
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	remote_source_version = (json.data as Dictionary).get("object", {}).get("sha", "")
	if remote_source_version == "":
		return
	# local version is up-to-date
	if FileAccess.file_exists(LOCAL_SOURCE_VERSION_PATH):
		var local_version: String = FileAccess.get_file_as_string(LOCAL_SOURCE_VERSION_PATH).strip_edges()
		if remote_source_version == local_version:
			return
	# download remote source files
	for source_name: String in SOURCES:
		var source_url: String = REMOTE_SOURCE_URL % source_name
		var source_request: HTTPRequest = HTTPRequest.new()
		source_request.timeout = 10
		add_child(source_request)
		source_request.request_completed.connect(_on_source_request_finished)
		source_request.request(source_url)
		source_need_download_count += 1

func _on_source_request_finished(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# check if the result is valid
	if result != OK or response_code != 200:
		return
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	var source_name: String = ""
	for key: String in (json.data as Dictionary).keys():
		if key in SOURCES:
			source_name = key
			break
	if source_name == "":
		return
	source_downloaded_data[source_name] = body
	source_downloaded_count += 1
	if source_downloaded_count == source_need_download_count:
		for downloaded_source_name: String in source_downloaded_data.keys():
			var source_file: FileAccess = FileAccess.open(LOCAL_SOURCE_PATH % downloaded_source_name, FileAccess.WRITE)
			source_file.store_string(source_downloaded_data[downloaded_source_name].get_string_from_utf8())
			source_file.close()
		var version_file: FileAccess = FileAccess.open(LOCAL_SOURCE_VERSION_PATH, FileAccess.WRITE)
		version_file.store_string(remote_source_version)
		version_file.close()
		source_updated.emit()