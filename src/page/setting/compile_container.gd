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
	
# 外部命令在线程池执行，控件状态延迟回主线程更新
func _check_version_task() -> void:
	_set_version_check(python_check,
		CompileManager.get_python_version())
	_set_version_check(scons_check,
		CompileManager.get_scons_version())
	_set_version_check(dotnet_check,
		CompileManager.get_dotnet_version())
	_set_version_check(mingw_check,
		CompileManager.get_mingw_version(Config.mingw_prefix))
	_set_version_check(vulkan_sdk_check,
		CompileManager.get_vulkan_sdk_version())
	_set_version_check(emscripten_check,
		CompileManager.get_emscripten_version())
	_set_version_check(jdk_check,
		CompileManager.get_jdk_version(Config.java_home))
	_set_version_check(android_platform_tools_check,
		CompileManager.get_android_sdk_platform_tools_version(Config.android_home))
	_set_version_check(android_build_tools_check,
		CompileManager.get_android_sdk_build_tools_version(Config.android_home))
	_set_version_check(android_platform_check,
		CompileManager.get_android_sdk_platform_version(Config.android_home))
	_set_version_check(android_command_line_tools_check,
		CompileManager.get_android_sdk_command_line_tools_version(Config.android_home))
	_set_version_check(android_cmake_check,
		CompileManager.get_android_cmake_version(Config.android_home))
	_set_version_check(android_ndk_check,
		CompileManager.get_android_ndk_version(Config.android_home))
	version_refreshed.emit.call_deferred()

func _set_version_check(checkbox: CheckBox, version: String) -> void:
	checkbox.set_deferred("button_pressed", version != "")
	checkbox.set_deferred("tooltip_text", version)

func _on_refresh_button_pressed() -> void:
	refresh_button.disabled = true
	check_version_task_id = WorkerThreadPool.add_task(_check_version_task)

func _on_version_refreshed() -> void:
	WorkerThreadPool.wait_for_task_completion(check_version_task_id)
	refresh_button.set_deferred("disabled", false)

func _on_mingw_path_button_pressed() -> void:
	if mingw_path_line.text != "":
		mingw_file_dialog.current_dir = mingw_path_line.text.get_base_dir()
	mingw_file_dialog.popup_centered()

func _on_jdk_path_button_pressed() -> void:
	if jdk_path_line.text != "":
		jdk_file_dialog.current_dir = jdk_path_line.text.get_base_dir()
	jdk_file_dialog.popup_centered()

func _on_android_sdk_path_button_pressed() -> void:
	if android_sdk_path_line.text != "":
		android_sdk_file_dialog.current_dir = android_sdk_path_line.text.get_base_dir()
	android_sdk_file_dialog.popup_centered()

func _on_mingw_file_dialog_dir_selected(dir: String) -> void:
	_store_compile_path(mingw_path_line, "mingw_prefix", dir)

func _on_jdk_file_dialog_dir_selected(dir: String) -> void:
	_store_compile_path(jdk_path_line, "java_home", dir)

func _on_android_sdk_file_dialog_dir_selected(dir: String) -> void:
	_store_compile_path(android_sdk_path_line, "android_home", dir)

func _on_mingw_path_line_text_submitted(new_text: String) -> void:
	_store_compile_path(mingw_path_line, "mingw_prefix", new_text)


func _on_jdk_path_line_text_submitted(new_text: String) -> void:
	_store_compile_path(jdk_path_line, "java_home", new_text)


func _on_android_sdk_path_line_text_submitted(new_text: String) -> void:
	_store_compile_path(android_sdk_path_line, "android_home", new_text)

func _store_compile_path(path_line: LineEdit, config_name: String, new_path: String) -> void:
	if not CompileManager.is_safe_shell_path(new_path):
		# 非法输入不写入配置，并恢复最近一次有效值
		var stored_path: String = str(Config.get(config_name))
		path_line.text = stored_path
		path_line.tooltip_text = stored_path
		return
	path_line.text = new_path
	path_line.tooltip_text = new_path
	Config.set(config_name, new_path)
