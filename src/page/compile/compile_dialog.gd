extends AcceptDialog

@onready var platform_option: OptionButton = $VBoxContainer/GridContainer/PlatformOption
@onready var architecture_option: OptionButton = $VBoxContainer/GridContainer/ArchitectureOption
@onready var command_line: LineEdit = $VBoxContainer/HBoxContainer/CommandLine

var file_path: String = ""

var platform_param: String = ""
var architecture_param: String = ""

func _ready() -> void:
	var target_width: int = platform_option.get_theme_font_size("font_size") + platform_option.get_theme_constant("h_separation")
	for i: int in range(platform_option.get_item_count()):
		platform_option.get_popup().set_item_icon_max_width(i, target_width)
	
func display() -> void:
	platform_option.select(0)
	platform_param = ""
	architecture_option.select(0)
	architecture_param = ""
	_update_command()
	popup_centered()

func _update_command() -> void:
	var env_commands: Array[String] = []
	if Config.mingw_prefix != "":
		match CompileManager.shell:
			CompileManager.SHELL_TYPE.WIN_PS7, CompileManager.SHELL_TYPE.WIN_PS:
				env_commands.append("$env:MINGW_PREFIX = \"%s\"" % Config.mingw_prefix)
			CompileManager.SHELL_TYPE.WIN_CMD:
				env_commands.append("set MINGW_PREFIX=%s" % Config.mingw_prefix)
	if platform_param == "android":
		match CompileManager.shell:
			CompileManager.SHELL_TYPE.WIN_PS7, CompileManager.SHELL_TYPE.WIN_PS:
				if Config.java_home != "":
					env_commands.append("$env:JAVA_HOME = \"%s\"" % Config.java_home)
				if Config.android_home != "":
					env_commands.append("$env:ANDROID_HOME = \"%s\"" % Config.android_home)
			CompileManager.SHELL_TYPE.WIN_CMD:
				if Config.java_home != "":
					env_commands.append("set JAVA_HOME=%s" % Config.java_home)
				if Config.android_home != "":
					env_commands.append("set ANDROID_HOME=%s" % Config.android_home)
			_:
				if Config.java_home != "":
					env_commands.append("export JAVA_HOME=\"%s\"" % Config.java_home)
				if Config.android_home != "":
					env_commands.append("export ANDROID_HOME=\"%s\"" % Config.android_home)
	var command: String = ""
	if env_commands.size() > 0:
		command = "; ".join(env_commands) + "; "
	command += "scons"
	if platform_param != "":
		command += " platform=%s" % platform_param
	if architecture_param != "":
		command += " arch=%s" % architecture_param
	command_line.text = command
	command_line.tooltip_text = command

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


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(command_line.text)


func _on_confirmed() -> void:
	DisplayServer.clipboard_set(command_line.text)
