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
const OFFICIAL_SOURCE: Array[String] = ["godot", "github"]

signal source_loaded()

var source: Dictionary = {}
var valid_version: Dictionary[String, Array] = {}
var valid_source: Array[String] = []
var downloading_task: Dictionary[String, bool] = {}

func _ready() -> void:
	load_source()

func load_source() -> void:
	var source_json: String = FileAccess.get_file_as_string("res://src/global/source/source.json")
	var json: JSON = JSON.new()
	if json.parse(source_json) != OK:
		return
	var arch: String = Config.get_architecture()
	var source_name_data: Dictionary = json.data
	for source_name: String in source_name_data.keys():
		var source_path: String = source_name_data[source_name]
		var source_file_json: String = FileAccess.get_file_as_string(source_path)
		if json.parse(source_file_json) != OK:
			continue
		var source_raw_data: Dictionary = json.data
		var source_data: Array = source_raw_data.get(source_name, [])
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
