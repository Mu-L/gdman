extends Node

signal small_update

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

# resolution
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

var url_regex: RegEx = RegEx.new()

func _ready() -> void:
	url_regex.compile(r"^https?://[^\s/$.?#].[^\s]*$")
	_set_windowed()

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
	return "foo" # Should not reach here


func set_language(locale: String) -> void:
	var lang: PackedStringArray = locale.split("_")
	if lang.size() < 1:
		TranslationServer.set_locale("en")
	else:
		match lang[0]:
			"zh":
				if lang.size() > 1:
					match lang[1]:
						"HK", "MO", "TW": # Hong Kong, Macau, Taiwan use Traditional Chinese
							TranslationServer.set_locale("zh_HK")
						_:
							TranslationServer.set_locale("zh_CN")
				else:
					TranslationServer.set_locale("zh_CN")
			_:
				TranslationServer.set_locale("en")


func _set_windowed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	for idx: int in window_sizes.size():
		if window_sizes[idx] < DisplayServer.screen_get_size():
			DisplayServer.window_set_size(window_sizes[mini(idx + 1, window_sizes.size() - 1)])
			break
	get_window().move_to_center.call_deferred()

func _on_small_update_timer_timeout() -> void:
	small_update.emit()

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
	return url_regex.search(url) != null
