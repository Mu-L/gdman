extends Node

const SOURCE_CODE_DIR: String = "user://code"

signal source_code_added(file_name: String)

func _command_to_version_text(path: String, args: PackedStringArray) -> String:
	var output: Array[String] = []
	if (OS.execute(path, args, output) != OK
		or output.size() == 0):
		return ""
	# 去除输出中的空行和首尾空白
	var lines: PackedStringArray = output[0].split("\n")
	var handled_lines: Array[String] = []
	for line: String in lines:
		if line.strip_edges() != "":
			handled_lines.append(line.strip_edges())
	return "\n".join(handled_lines)

func get_python_version() -> String:
	# python3 --version
	return _command_to_version_text("python3", ["--version"])

func get_scons_version() -> String:
	# scons --version
	return _command_to_version_text("scons", ["--version"])

func get_dotnet_version() -> String:
	# dotnet --version
	return _command_to_version_text("dotnet", ["--version"])

# MINGW_PREFIX
func get_mingw_version(custom_path: String) -> String:
	if OS.get_name() != "Windows":
		return ""
	# g++ --version
	var path: String = custom_path
	if path != "":
		path = path.path_join("bin/g++")
	else:
		path = OS.get_environment("MINGW_PREFIX")
		if path != "":
			path = path.path_join("bin/g++")
		else:
			path = "g++"
	return _command_to_version_text(path, ["--version"])

func get_vulkan_sdk_version() -> String:
	if OS.get_name() != "macOS":
		return ""
	var output: Array[String] = []
	if (OS.execute("vulkaninfo", ["--summary"], output) != OK
		or output.size() == 0):
		return ""
	var version_info: Array[String] = []
	for line: String in output[0].split("\n"):
		if line.containsn("version"):
			version_info.append(line.strip_edges())
	if version_info.size() == 0:
		return ""
	return "\n".join(version_info)

func get_emscripten_version() -> String:
	# emcc --version
	return _command_to_version_text("emcc", ["--version"])

# JAVA_HOME
func get_jdk_version(custom_path: String) -> String:
	var path: String = custom_path
	if path != "":
		path = path.path_join("bin/javac")
	else:
		path = OS.get_environment("JAVA_HOME")
		if path != "":
			path = path.path_join("bin/javac")
		else:
			path = "javac"
	return _command_to_version_text(path, ["--version"])

func get_android_sdk_platform_tools_version(custom_path: String) -> String:
	var path: String = custom_path if custom_path != "" else OS.get_environment("ANDROID_HOME")
	if path == "":
		return ""
	return _command_to_version_text(path.path_join("platform-tools/adb"), ["--version"])

func get_android_sdk_build_tools_version(custom_path: String) -> String:
	var path: String = custom_path if custom_path != "" else OS.get_environment("ANDROID_HOME")
	if path == "":
		return ""
	path = path.path_join("build-tools")
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var valid_versions: Array[String] = []
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if FileAccess.file_exists(path.path_join(file_name).path_join("lib/d8.jar")):
				valid_versions.append(file_name)
		file_name = dir.get_next()
	if valid_versions.size() == 0:
		return ""
	return "\n".join(valid_versions)

func get_android_sdk_platform_version(custom_path: String) -> String:
	var path: String = custom_path if custom_path != "" else OS.get_environment("ANDROID_HOME")
	if path == "":
		return ""
	path = path.path_join("platforms")
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var valid_versions: Array[String] = []
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if FileAccess.file_exists(path.path_join(file_name).path_join("android.jar")):
				valid_versions.append(file_name)
		file_name = dir.get_next()
	if valid_versions.size() == 0:
		return ""
	return "\n".join(valid_versions)

func get_android_sdk_command_line_tools_version(custom_path: String) -> String:
	var path: String = custom_path if custom_path != "" else OS.get_environment("ANDROID_HOME")
	if path == "":
		return ""
	var executable_name: String = "sdkmanager.bat" if OS.get_name() == "Windows" else "sdkmanager"
	if FileAccess.file_exists(path.path_join("cmdline-tools/latest/bin").path_join(executable_name)):
		return "latest"
	return ""

func get_android_cmake_version(custom_path: String) -> String:
	var path: String = custom_path if custom_path != "" else OS.get_environment("ANDROID_HOME")
	if path == "":
		var output: Array[String] = []
		if (OS.execute("cmake", ["--version"], output) != OK
			or output.size() == 0):
			return ""
		return output[0].strip_edges()
	path = path.path_join("cmake")
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var valid_versions: Array[String] = []
	var file_name: String = dir.get_next()
	var executable_name: String = "cmake.exe" if OS.get_name() == "Windows" else "cmake"
	while file_name != "":
		if dir.current_is_dir():
			if FileAccess.file_exists(path.path_join(file_name).path_join("bin").path_join(executable_name)):
				valid_versions.append(file_name)
		file_name = dir.get_next()
	if valid_versions.size() == 0:
		return ""
	return "\n".join(valid_versions)

func get_android_ndk_version(custom_path: String) -> String:
	var path: String = custom_path if custom_path != "" else OS.get_environment("ANDROID_HOME")
	if path == "":
		return ""
	path = path.path_join("ndk")
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var valid_versions: Array[String] = []
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if FileAccess.file_exists(path.path_join(file_name).path_join("build/ndk-build")):
				valid_versions.append(file_name)
		file_name = dir.get_next()
	if valid_versions.size() == 0:
		return ""
	return "\n".join(valid_versions)

func _pass() -> void:
	source_code_added.emit("")
