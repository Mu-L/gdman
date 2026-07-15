extends AcceptDialog

const SHELLS: Array[String] = ["POSIX", "PowerShell", "CMD", "Fish"]

@onready var platform_option: OptionButton = $VBoxContainer/GridContainer/PlatformOption
@onready var architecture_option: OptionButton = $VBoxContainer/GridContainer/ArchitectureOption
@onready var shell_option: OptionButton = $VBoxContainer/GridContainer/ShellOption
@onready var command_text: RichTextLabel = $VBoxContainer/PanelContainer/MarginContainer/CommandText
@onready var copy_button: Button = $VBoxContainer/PanelContainer/MarginContainer/Control/CopyButton

var platform_param: String = ""
var architecture_param: String = ""

func _ready() -> void:
	copy_button.hide()
	var target_width: int = platform_option.get_theme_font_size("font_size") + platform_option.get_theme_constant("h_separation")
	for i: int in range(platform_option.get_item_count()):
		platform_option.get_popup().set_item_icon_max_width(i, target_width)
	for shell: String in SHELLS:
		shell_option.add_item(shell)
	
func display() -> void:
	platform_option.select(0)
	platform_param = ""
	architecture_option.select(0)
	architecture_param = ""
	_update_command()
	popup_centered()

func _update_command() -> void:
	var env_commands: Array[String] = []
	var shell: String = ""
	var selected_shell_id: int = shell_option.get_selected_id()
	if selected_shell_id >= 0:
		shell = shell_option.get_item_text(selected_shell_id)
		if Config.mingw_prefix != "":
			_append_env_command(env_commands, shell, "MINGW_PREFIX", Config.mingw_prefix)
		if platform_param == "android":
			if Config.java_home != "":
				_append_env_command(env_commands, shell, "JAVA_HOME", Config.java_home)
			if Config.android_home != "":
				_append_env_command(env_commands, shell, "ANDROID_HOME", Config.android_home)
	var command: String = ""
	if env_commands.size() > 0:
		var command_separator: String = " && " if shell == "CMD" else "; "
		command = command_separator.join(env_commands) + command_separator
	command += "scons"
	if platform_param != "":
		command += " platform=%s" % platform_param
	if architecture_param != "":
		command += " arch=%s" % architecture_param
	command_text.text = command

func _append_env_command(commands: Array[String], shell: String, environment_name: String, path: String) -> void:
	var command: String = CompileManager.format_shell_env_command(shell, environment_name, path)
	if command != "":
		commands.append(command)

func _on_platform_option_item_selected(index: int) -> void:
	match index:
		0:
			platform_param = ""
		1:
			platform_param = "windows"
		2:
			platform_param = "linuxbsd"
		3:
			platform_param = "macos"
		4:
			platform_param = "android"
		5:
			platform_param = "ios"
		6:
			platform_param = "visionos"
		7:
			platform_param = "web"
		_:
			platform_param = ""
	_update_command()


func _on_architecture_option_item_selected(index: int) -> void:
	match index:
		0:
			architecture_param = ""
		1:
			architecture_param = "x86_32"
		2:
			architecture_param = "x86_64"
		3:
			architecture_param = "arm32"
		4:
			architecture_param = "arm64"
		5:
			architecture_param = "rv64"
		6:
			architecture_param = "ppc64"
		7:
			architecture_param = "wasm32"
		8:
			architecture_param = "wasm64"
		9:
			architecture_param = "loongarch64"
		_:
			architecture_param = ""
	_update_command()


func _on_shell_option_item_selected(_index: int) -> void:
	_update_command()


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(command_text.text)


func _on_confirmed() -> void:
	DisplayServer.clipboard_set(command_text.text)


func _on_panel_container_mouse_entered() -> void:
	copy_button.show()


func _on_panel_container_mouse_exited() -> void:
	copy_button.hide()
