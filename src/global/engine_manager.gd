extends Node

const ENGINE_DIR: String = "user://engine"

enum EngineFlavor {
	STABLE,
	RC,
	BETA,
	ALPHA,
	DEV,
}

const FLAVOR_NAME: Dictionary[EngineFlavor, String] = {
	EngineFlavor.RC: "RC",
	EngineFlavor.BETA: "Beta",
	EngineFlavor.ALPHA: "Alpha",
	EngineFlavor.DEV: "Dev",
}

class EngineInfo:
	var id: String # x.y[.z]-flavor[a][-dotnet]
	var name: String # Display name
	var major_version: int
	var minor_version: int
	var patch_version: int
	var flavor: EngineFlavor
	var build: int
	var is_dotnet: bool

class LocalEngine:
	var dir_path: String
	var executable_path: String
	var info: EngineInfo

var _cache_engine_info: Dictionary[String, EngineInfo] = {}

var local_engines: Dictionary[String, LocalEngine] = {}

func _ready() -> void:
	load_engines()

func load_engines() -> void:
	local_engines.clear()
	var engines_dir: DirAccess = DirAccess.open(ENGINE_DIR)
	if engines_dir == null:
		return
	for dir_name: String in engines_dir.get_directories():
		var engine_info: EngineInfo = id_to_engine_info(dir_name)
		if engine_info == null:
			continue
		var local_engine: LocalEngine = LocalEngine.new()
		local_engine.info = engine_info
		local_engine.dir_path = ProjectSettings.globalize_path(ENGINE_DIR.path_join(dir_name))
		local_engine.executable_path = ProjectSettings.globalize_path(_get_executable_path(dir_name))
		local_engines[engine_info.id] = local_engine

func id_to_engine_info(engine_id: String) -> EngineInfo:
	if _cache_engine_info.has(engine_id):
		return _cache_engine_info[engine_id]
	var info: PackedStringArray = engine_id.split("-")
	if info.size() != 2 and info.size() != 3:
		return null
	var engine_info: EngineInfo = EngineInfo.new()
	engine_info.id = engine_id
	# version
	var version_info: PackedStringArray = info[0].split(".")
	if version_info.size() >= 2:
		engine_info.major_version = version_info[0].to_int()
		engine_info.minor_version = version_info[1].to_int()
		if version_info.size() == 3:
			engine_info.patch_version = version_info[2].to_int()
	# flavor
	if info[1] == "stable":
		engine_info.flavor = EngineFlavor.STABLE
	elif info[1].begins_with("rc"):
		engine_info.flavor = EngineFlavor.RC
	elif info[1].begins_with("beta"):
		engine_info.flavor = EngineFlavor.BETA
	elif info[1].begins_with("alpha"):
		engine_info.flavor = EngineFlavor.ALPHA
	elif info[1].begins_with("dev"):
		engine_info.flavor = EngineFlavor.DEV
	engine_info.build = info[1].to_int()
	engine_info.is_dotnet = info.size() == 3 and info[2] == "dotnet"
	# name
	var name_array: Array[String] = []
	name_array.append("%d.%d" % [engine_info.major_version, engine_info.minor_version])
	if engine_info.patch_version > 0:
		name_array.append(".%d" % engine_info.patch_version)
	if engine_info.flavor != EngineFlavor.STABLE:
		name_array.append(" %s" % FLAVOR_NAME[engine_info.flavor])
	if engine_info.build > 0:
		name_array.append(" %d" % engine_info.build)
	if engine_info.is_dotnet:
		name_array.append(" (.NET)")
	engine_info.name = "".join(name_array)
	_cache_engine_info[engine_id] = engine_info
	return engine_info
	
func _get_executable_path(dir_name: String) -> String:
	var target_path: String = ""
	var target_suffix: String = App.architecture_to_executable_suffix(Config.get_architecture())
	var dirs_to_scan: Array[String] = [ENGINE_DIR.path_join(dir_name)]
	while dirs_to_scan.size() > 0:
		var current_path: String = dirs_to_scan.pop_back()
		var current_dir: DirAccess = DirAccess.open(current_path)
		if current_dir != null:
			current_dir.list_dir_begin()
			var file_name: String = current_dir.get_next()
			while file_name != "":
				if file_name.ends_with(target_suffix):
					target_path = current_path.path_join(file_name)
					break
				elif current_dir.current_is_dir():
					if file_name != "." and file_name != "..":
						dirs_to_scan.append(current_path.path_join(file_name))
				file_name = current_dir.get_next()
			current_dir.list_dir_end()
	return target_path
