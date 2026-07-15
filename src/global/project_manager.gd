extends Node

const CONFIG_PATH: String = "user://project.cfg"
const UID_SCAN_EXCLUDED_DIRECTORIES: Array[String] = [
	".git",
	".godot",
	".import",
	".mono",
	".cache",
	".venv",
	"__pycache__",
	"node_modules",
	"build",
	"dist",
	"bin",
]

signal uid_path_resolved(request_id: int, resource_path: String)

class ProjectInfo:
	var path: String = ""
	var prefer_engine_id: String = ""

var project_info: Dictionary[String, ProjectInfo] = {}
var _uid_scan_task_ids: Dictionary[int, int] = {}
var _next_uid_scan_request_id: int = 0

func _ready() -> void:
	load_config()

func _exit_tree() -> void:
	# Autoload 退出前回收所有扫描任务，避免工作线程继续访问已释放对象
	for request_id: int in _uid_scan_task_ids.keys():
		wait_for_uid_scan(request_id)

func request_uid_path(uid_path: String, project_root: String) -> int:
	_next_uid_scan_request_id += 1
	var request_id: int = _next_uid_scan_request_id
	var task_id: int = WorkerThreadPool.add_task(
		_scan_uid_path.bind(request_id, uid_path, project_root))
	if task_id < 0:
		return -1
	_uid_scan_task_ids[request_id] = task_id
	return request_id

func wait_for_uid_scan(request_id: int) -> void:
	var task_id: int = _uid_scan_task_ids.get(request_id, -1)
	if task_id < 0:
		return
	WorkerThreadPool.wait_for_task_completion(task_id)
	_uid_scan_task_ids.erase(request_id)

func _scan_uid_path(request_id: int, uid_path: String, project_root: String) -> void:
	var resource_path: String = ""
	var dirs_to_scan: Array[String] = [project_root]
	while dirs_to_scan.size() > 0 and resource_path == "":
		var current_path: String = dirs_to_scan.pop_back()
		var current_dir: DirAccess = DirAccess.open(current_path)
		if current_dir == null:
			continue
		current_dir.list_dir_begin()
		var file_name: String = current_dir.get_next()
		while file_name != "":
			# 目录和文件链接均跳过，防止扫描逃逸项目目录或形成循环
			if (file_name == "." or file_name == ".."
				or current_dir.is_link(file_name)):
				file_name = current_dir.get_next()
				continue
			if current_dir.current_is_dir():
				if file_name not in UID_SCAN_EXCLUDED_DIRECTORIES:
					dirs_to_scan.append(current_path.path_join(file_name))
			elif file_name.ends_with(".import"):
				var import_config: ConfigFile = ConfigFile.new()
				if (import_config.load(current_path.path_join(file_name)) == OK
					and import_config.get_value("remap", "uid", "") == uid_path):
					resource_path = import_config.get_value("deps", "source_file", "")
					break
			file_name = current_dir.get_next()
		current_dir.list_dir_end()
	_complete_uid_scan.call_deferred(request_id, resource_path)

func _complete_uid_scan(request_id: int, resource_path: String) -> void:
	if not _uid_scan_task_ids.has(request_id):
		return
	var task_id: int = _uid_scan_task_ids[request_id]
	WorkerThreadPool.wait_for_task_completion(task_id)
	_uid_scan_task_ids.erase(request_id)
	uid_path_resolved.emit(request_id, resource_path)

func store_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	for path: String in project_info.keys():
		var project: ProjectInfo = project_info.get(path, null)
		if project == null:
			continue
		config.set_value(project.path, "prefer_engine_id", project.prefer_engine_id)
	config.save(CONFIG_PATH)

func load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	project_info.clear()
	for path: String in config.get_sections():
		var project: ProjectInfo = ProjectInfo.new()
		project.path = path
		project.prefer_engine_id = config.get_value(path, "prefer_engine_id", "")
		project_info[path] = project

func add_project(dir_path: String) -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(dir_path.path_join("project.godot")) != OK:
		return
	var project: ProjectInfo = ProjectInfo.new()
	project.path = dir_path
	var project_version: String = config.get_value("application", "config/features", [""])[0]
	if project_version != "":
		for engine_id: String in EngineManager.local_engines.keys():
			if engine_id.begins_with(project_version):
				project.prefer_engine_id = engine_id
				break
	project_info[dir_path] = project
	store_config()
