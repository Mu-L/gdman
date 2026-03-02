extends VBoxContainer

signal version_refreshed()

var check_version_task_id: int = -1


@onready var refresh_button: Button = $RefreshButton
@onready var mingw_path_line: LineEdit = $GridContainer/MingwContainer/MingwPathLine
@onready var mingw_path_button: Button = $GridContainer/MingwContainer/MingwPathButton
@onready var mingw_file_dialog: FileDialog = $GridContainer/MingwContainer/MingwPathButton/MingwFileDialog
@onready var jdk_path_line: LineEdit = $GridContainer/JDKContainer/JDKPathLine
@onready var jdk_file_dialog: FileDialog = $GridContainer/JDKContainer/JDKPathButton/JDKFileDialog
@onready var android_sdk_path_line: LineEdit = $GridContainer/AndroidSDKContainer/AndroidSDKPathLine
@onready var android_sdk_file_dialog: FileDialog = $GridContainer/AndroidSDKContainer/AndroidSDKPathButton/AndroidSDKFileDialog

@onready var python_check: CheckBox = $GridContainer/PythonCheck
@onready var scons_check: CheckBox = $GridContainer/SconsCheck
@onready var dotnet_check: CheckBox = $GridContainer/DotnetCheck
@onready var mingw_check: CheckBox = $GridContainer/MingwCheck
@onready var vulkan_sdk_check: CheckBox = $GridContainer/VulkanSDKCheck
@onready var emscripten_check: CheckBox = $GridContainer/EmscriptenCheck
@onready var jdk_check: CheckBox = $GridContainer/JDKCheck

@onready var android_platform_tools_check: CheckBox = $GridContainer/AndroidPlatformToolsCheck
@onready var android_build_tools_check: CheckBox = $GridContainer/AndroidBuildToolsCheck
@onready var android_platform_check: CheckBox = $GridContainer/AndroidPlatformCheck
@onready var android_command_line_tools_check: CheckBox = $GridContainer/AndroidCommandLineToolsCheck
@onready var android_cmake_check: CheckBox = $GridContainer/AndroidCmakeCheck
@onready var android_ndk_check: CheckBox = $GridContainer/AndroidNDKCheck

func _ready() -> void:
	mingw_path_line.text = Config.mingw_prefix
	jdk_path_line.text = Config.java_home
	android_sdk_path_line.text = Config.android_home
	refresh_button.disabled = true
	check_version_task_id = WorkerThreadPool.add_task(_check_version_task)
	if OS.get_name() != "Windows":
		mingw_path_line.editable = false
		mingw_path_button.disabled = true
	
func _check_version_task() -> void:
	var python_version: String = CompileManager.get_python_version()
	python_check.set_deferred("button_pressed",
		python_version != "")
	python_check.set_deferred("tooltip_text", python_version)
	var scons_version: String = CompileManager.get_scons_version()
	scons_check.set_deferred("button_pressed",
		scons_version != "")
	scons_check.set_deferred("tooltip_text", scons_version)
	var dotnet_version: String = CompileManager.get_dotnet_version()
	dotnet_check.set_deferred("button_pressed",
		dotnet_version != "")
	dotnet_check.set_deferred("tooltip_text", dotnet_version)
	var mingw_version: String = CompileManager.get_mingw_version(mingw_path_line.text)
	mingw_check.set_deferred("button_pressed",
		mingw_version != "")
	mingw_check.set_deferred("tooltip_text", mingw_version)
	var vulkan_sdk_version: String = CompileManager.get_vulkan_sdk_version()
	vulkan_sdk_check.set_deferred("button_pressed",
		vulkan_sdk_version != "")
	vulkan_sdk_check.set_deferred("tooltip_text", vulkan_sdk_version)
	var emscripten_version: String = CompileManager.get_emscripten_version()
	emscripten_check.set_deferred("button_pressed",
		emscripten_version != "")
	emscripten_check.set_deferred("tooltip_text", emscripten_version)
	var jdk_version: String = CompileManager.get_jdk_version(jdk_path_line.text)
	jdk_check.set_deferred("button_pressed",
		jdk_version != "")
	jdk_check.set_deferred("tooltip_text", jdk_version)
	var android_platform_tools_version: String = CompileManager.get_android_sdk_platform_tools_version(android_sdk_path_line.text)
	android_platform_tools_check.set_deferred("button_pressed",
		android_platform_tools_version != "")
	android_platform_tools_check.set_deferred("tooltip_text", android_platform_tools_version)
	var android_build_tools_version: String = CompileManager.get_android_sdk_build_tools_version(android_sdk_path_line.text)
	android_build_tools_check.set_deferred("button_pressed",
		android_build_tools_version != "")
	android_build_tools_check.set_deferred("tooltip_text", android_build_tools_version)
	var android_platform_version: String = CompileManager.get_android_sdk_platform_version(android_sdk_path_line.text)
	android_platform_check.set_deferred("button_pressed",
		android_platform_version != "")
	android_platform_check.set_deferred("tooltip_text", android_platform_version)
	var android_command_line_tools_version: String = CompileManager.get_android_sdk_command_line_tools_version(android_sdk_path_line.text)
	android_command_line_tools_check.set_deferred("button_pressed",
		android_command_line_tools_version != "")
	android_command_line_tools_check.set_deferred("tooltip_text", android_command_line_tools_version)
	var android_cmake_version: String = CompileManager.get_android_cmake_version(android_sdk_path_line.text)
	android_cmake_check.set_deferred("button_pressed",
		android_cmake_version != "")
	android_cmake_check.set_deferred("tooltip_text", android_cmake_version)
	var android_ndk_version: String = CompileManager.get_android_ndk_version(android_sdk_path_line.text)
	android_ndk_check.set_deferred("button_pressed",
		android_ndk_version != "")
	android_ndk_check.set_deferred("tooltip_text", android_ndk_version)
	version_refreshed.emit.call_deferred()

func _on_refresh_button_pressed() -> void:
	refresh_button.disabled = true
	check_version_task_id = WorkerThreadPool.add_task(_check_version_task)

func _on_version_refreshed() -> void:
	WorkerThreadPool.wait_for_task_completion(check_version_task_id)
	refresh_button.set_deferred("disabled", false)

func _on_mingw_path_button_pressed() -> void:
	mingw_file_dialog.popup_centered()

func _on_jdk_path_button_pressed() -> void:
	jdk_file_dialog.popup_centered()

func _on_android_sdk_path_button_pressed() -> void:
	android_sdk_file_dialog.popup_centered()

func _on_mingw_file_dialog_dir_selected(dir: String) -> void:
	mingw_path_line.text = dir
	Config.mingw_prefix = dir

func _on_jdk_file_dialog_dir_selected(dir: String) -> void:
	jdk_path_line.text = dir
	Config.java_home = dir

func _on_android_sdk_file_dialog_dir_selected(dir: String) -> void:
	android_sdk_path_line.text = dir
	Config.android_home = dir

func _on_mingw_path_line_text_submitted(new_text: String) -> void:
	Config.mingw_prefix = new_text


func _on_jdk_path_line_text_submitted(new_text: String) -> void:
	Config.java_home = new_text


func _on_android_sdk_path_line_text_submitted(new_text: String) -> void:
	Config.android_home = new_text
