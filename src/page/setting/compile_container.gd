extends VBoxContainer

signal version_refreshed()

var check_version_task_id: int = -1


var regex: Dictionary[String, RegEx] = {}
var version_regex: Dictionary[String, String] = {
	"python": r"(\d+\.\d+\.\d+)",
	"scons": r"v(\d+\.\d+\.\d+)",
	"dotnet": r"(\d+\.\d+\.\d+)",
	"mingw": r"version\s+(\d+\.\d+\.\d+)",
	"vulkan_sdk": "",
	"jdk": r"(\d+\.\d+\.\d+)",
	"emscripten": r"\)\s+(\d+\.\d+\.\d+)\s+\(",
	"cmake": r"cmake version (\d+\.\d+\.\d+)",
}

@onready var refresh_button: Button = $RefreshButton
@onready var min_gw_path_line: LineEdit = $GridContainer/MinGWContainer/MinGWPathLine
@onready var min_gw_file_dialog: FileDialog = $GridContainer/MinGWContainer/MinGWPathButton/MinGWFileDialog
@onready var jdk_path_line: LineEdit = $GridContainer/JDKContainer/JDKPathLine
@onready var jdk_file_dialog: FileDialog = $GridContainer/JDKContainer/JDKPathButton/JDKFileDialog
@onready var android_sdk_path_line: LineEdit = $GridContainer/AndroidSDKContainer/AndroidSDKPathLine
@onready var android_sdk_file_dialog: FileDialog = $GridContainer/AndroidSDKContainer/AndroidSDKPathButton/AndroidSDKFileDialog

@onready var python_version_label: Label = $GridContainer/PythonVersionLabel
@onready var scons_version_label: Label = $GridContainer/SconsVersionLabel
@onready var dotnet_version_label: Label = $GridContainer/DotnetVersionLabel
@onready var min_gw_version_label: Label = $GridContainer/MinGWVersionLabel
@onready var vulkan_sdk_version_label: Label = $GridContainer/VulkanSDKVersionLabel
@onready var emscripten_version_label: Label = $GridContainer/EmscriptenVersionLabel
@onready var jdk_version_label: Label = $GridContainer/JDKVersionLabel

@onready var android_platform_tools_version_label: Label = $GridContainer/AndroidPlatformToolsVersionLabel
@onready var android_build_tools_version_label: Label = $GridContainer/AndroidBuildToolsVersionLabel
@onready var android_platform_version_label: Label = $GridContainer/AndroidPlatformVersionLabel
@onready var android_command_line_version_label: Label = $GridContainer/AndroidCommandLineVersionLabel
@onready var c_make_version_label: Label = $GridContainer/CMakeVersionLabel
@onready var ndk_version_label: Label = $GridContainer/NDKVersionLabel

func _ready() -> void:
	for key: String in version_regex.keys():
		regex[key] = RegEx.new()
		if regex[key].compile(version_regex[key]) != OK:
			regex.erase(key)
	refresh_button.disabled = true
	check_version_task_id = WorkerThreadPool.add_task(_check_version_task)
	
func _check_version_task() -> void:
	# Python：python3 --version
	python_version_label.set_deferred("text",
		_extract_version("python", ["--version"], "python"))
	# Scons：scons --version
	scons_version_label.set_deferred("text",
		_extract_version("scons", ["--version"], "scons"))
	# Dotnet：dotnet --version
	dotnet_version_label.set_deferred("text",
		_extract_version("dotnet", ["--version"], "dotnet"))
	# MinGW：g++ --version
	if min_gw_path_line.text == "":
		min_gw_version_label.set_deferred("text",
			_extract_version("g++", ["--version"], "mingw"))
	else:
		min_gw_version_label.set_deferred("text",
			_extract_version(min_gw_path_line.text.path_join("bin/g++.exe"), ["--version"], "mingw"))
	# Vulkan SDK：pass
	# Emscripten：emcc --version
	emscripten_version_label.set_deferred("text",
		_extract_version("emcc", ["--version"], "emscripten"))
	version_refreshed.emit.call_deferred()
	# JDK：javac --version
	if jdk_path_line.text == "":
		jdk_version_label.set_deferred("text",
		_extract_version("javac", ["--version"], "jdk"))
	else:
		jdk_version_label.set_deferred("text",
			_extract_version(jdk_path_line.text.path_join("bin/javac"), ["--version"], "jdk"))
	# Android SDK
	_check_android_sdk_version()

func _check_android_sdk_version() -> void:
	var sdk_path: String = android_sdk_path_line.text
	if sdk_path == "":
		sdk_path = OS.get_environment("ANDROID_HOME")
	if sdk_path == "":
		android_platform_tools_version_label.set_deferred("text", "?")
		android_build_tools_version_label.set_deferred("text", "?")
		android_platform_version_label.set_deferred("text", "?")
		android_command_line_version_label.set_deferred("text", "?")
		return
	if OS.get_name() == "Windows":
		sdk_path = sdk_path.path_join("cmdline-tools/latest/bin/sdkmanager.bat")
	else:
		sdk_path = sdk_path.path_join("cmdline-tools/latest/bin/sdkmanager")
	var output: Array[String] = []
	if (OS.execute(sdk_path, ["--list_installed"], output) != OK
		or output.size() == 0):
		android_platform_tools_version_label.set_deferred("text", "?")
		android_build_tools_version_label.set_deferred("text", "?")
		android_platform_version_label.set_deferred("text", "?")
		android_command_line_version_label.set_deferred("text", "?")
		return
	var tools_version: Dictionary[String, String] = {}
	for line: String in output[0].split("\n"):
		line = line.strip_edges()
		if (line.is_empty()
			or line.begins_with("Installed packages")
			or line.begins_with("Path")
			or line.begins_with("--")):
			continue
		var parts: PackedStringArray = line.split("|")
		if parts.size() < 2:
			continue
		var tool_name: String = parts[0].strip_edges().split(";")[0]
		var tool_version: String = parts[1].strip_edges()
		if tool_name == "platforms":
			tool_version = parts[0].strip_edges().split(";")[-1]
		tools_version[tool_name] = tool_version
		
		
	android_platform_tools_version_label.set_deferred("text",
		tools_version.get("platform-tools", "?"))
	android_build_tools_version_label.set_deferred("text",
		tools_version.get("build-tools", "?"))
	android_platform_version_label.set_deferred("text",
		tools_version.get("platforms", "?"))
	android_command_line_version_label.set_deferred("text",
		tools_version.get("cmdline-tools", "?"))
	if tools_version.has("cmake"):
		c_make_version_label.set_deferred("text", tools_version.get("cmake", "?"))
	else:
		c_make_version_label.set_deferred("text",
		_extract_version("cmake", ["--version"], "cmake"))
	ndk_version_label.set_deferred("text", tools_version.get("ndk", "?"))

func _extract_version(path: String, args: PackedStringArray, regex_key: String) -> String:
	if not regex.has(regex_key):
		return "?"
	var output: Array[String] = []
	if (OS.execute(path, args, output) != OK
		or output.size() == 0):
		return "?"
	var result: RegExMatch = regex[regex_key].search(output[0])
	if result == null:
		return "?"
	return result.get_string(1)


func _on_refresh_button_pressed() -> void:
	refresh_button.disabled = true
	check_version_task_id = WorkerThreadPool.add_task(_check_version_task)

func _on_version_refreshed() -> void:
	WorkerThreadPool.wait_for_task_completion(check_version_task_id)
	refresh_button.set_deferred("disabled", false)

func _on_min_gw_path_button_pressed() -> void:
	min_gw_file_dialog.popup_centered()

func _on_jdk_path_button_pressed() -> void:
	jdk_file_dialog.popup_centered()

func _on_android_sdk_path_button_pressed() -> void:
	android_sdk_file_dialog.popup_centered()


func _on_min_gw_file_dialog_dir_selected(dir: String) -> void:
	min_gw_path_line.text = dir

func _on_jdk_file_dialog_dir_selected(dir: String) -> void:
	jdk_path_line.text = dir

func _on_android_sdk_file_dialog_dir_selected(dir: String) -> void:
	android_sdk_path_line.text = dir


func _on_min_gw_path_line_text_submitted(new_text: String) -> void:
	Config.mingw_prefix = new_text


func _on_jdk_path_line_text_submitted(new_text: String) -> void:
	Config.java_home = new_text


func _on_android_sdk_path_line_text_submitted(new_text: String) -> void:
	Config.android_home = new_text
