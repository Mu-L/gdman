extends Node

signal small_update()

const ARCHITECTURE: Array[String] = [
	"windows_x86",
	"windows_x64",
	"windows_arm64",
	"linux_x86",
	"linux_x64",
	"linux_arm32",
	"linux_arm64",
	"macos",
]

var url_regex: RegEx = RegEx.new()

func _ready() -> void:
	_set_windowed()
	# 仅接受带有效主机名的 HTTPS 地址，同时保留自定义下载域名能力
	url_regex.compile(r"^https://(?:\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?)(?::([0-9]{1,5}))?(?:[/?#][^\s]*)?$")

func get_architecture() -> String:
	match OS.get_name():
		"Windows":
			match Engine.get_architecture_name():
				"x86_32":
					return "windows_x86"
				"x86_64":
					return "windows_x64"
				"arm64":
					return "windows_arm64"
		"macOS":
			return "macos"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			match Engine.get_architecture_name():
				"x86_32":
					return "linux_x86"
				"x86_64":
					return "linux_x64"
				"arm32":
					return "linux_arm32"
				"arm64":
					return "linux_arm64"
	return ""

# 将架构标识映射为压缩包内的可执行文件后缀
func architecture_to_executable_suffix(architecture: String) -> String:
	match architecture:
		"windows_x86", "windows_x64", "windows_arm64":
			return ".exe"
		"linux_x86":
			return "x86_32"
		"linux_x64":
			return "x86_64"
		"linux_arm32":
			return "arm32"
		"linux_arm64":
			return "arm64"
		"macos":
			return ".app"
	return "foo" # 上游仅应传入 ARCHITECTURE 中的有效值

# 选择第二大的可用尺寸，避免窗口接近占满屏幕
func _set_windowed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	var window_sizes: Array[Vector2i] = [
		Vector2i(3840, 2400), # 4K UHD
		Vector2i(3200, 2000), # QHD+
		Vector2i(2560, 1600), # QHD
		Vector2i(2048, 1280), # QWXGA
		Vector2i(1920, 1200), # Full HD
		Vector2i(1600, 1000), # HD+
		Vector2i(1366, 768), # FWXGA
		Vector2i(1280, 800), # HD
		Vector2i(1024, 640), # WSVGA
		Vector2i(960, 600), # qHD
		Vector2i(640, 400), # nHD
	]
	for idx: int in window_sizes.size():
		if window_sizes[idx] < DisplayServer.screen_get_size():
			DisplayServer.window_set_size(window_sizes[mini(idx + 1, window_sizes.size() - 1)])
			break
	get_window().move_to_center.call_deferred()

func _on_small_update_timer_timeout() -> void:
	small_update.emit()

# 不同语言会导致按钮的文本宽度不同，因此需要根据文本和图标的宽度来设置按钮的最小宽度
func fix_button_width(button: Button) -> void:
	if button.icon == null:
		return
	if button.text == "":
		button.custom_minimum_size.x = button.size.y
		return
	button.custom_minimum_size.x = button.get_theme_font("font").get_string_size(
		tr(button.text),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		button.get_theme_font_size("font_size")).x + button.get_theme_constant("h_separation") + button.size.y

func is_valid_url(url: String) -> bool:
	var matched_url: RegExMatch = url_regex.search(url)
	if matched_url == null:
		return false
	var port: String = matched_url.get_string(1)
	return port == "" or (port.to_int() >= 1 and port.to_int() <= 65535)

func is_unix_platform() -> bool:
	return OS.get_name() in ["macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", ]

# 优先直接删除，失败时回退到系统回收站
func remove_file(path: String) -> void:
	var handled_path: String = ProjectSettings.globalize_path(path)
	if DirAccess.remove_absolute(handled_path) != OK:
		OS.move_to_trash(handled_path)
