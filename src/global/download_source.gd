extends Node

const ARCHITECTURE: Array[String] = [
	"windows_x86",
	"windows_x64",
	"windows_arm64",
	"linux_x64",
	"linux_arm64",
	"macos",
]

const OFFICIAL_SOURCE: Array[String] = ["godot", "github"]

var source_data: Dictionary[String, Array] = {
	"4.6": [
		{
			"id": "4.6_rc2",
			"name": "4.6 RC2",
			"stable": false,
			"standard": [
				{
					"source": "godot",
					"windows_x64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=win64.exe.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=windows_arm64.exe.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=linux.arm64.zip&platform=linux.arm64",
					"macos": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=macos.universal.zip&platform=macos.universal",
				},
				{
					"source": "github",
					"windows_x64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_win64.exe.zip",
					"windows_arm64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_windows_arm64.exe.zip",
					"linux_x64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_linux.x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_linux.x86_64.zip",
					"macos": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_macos.universal.zip",
				}
			],
			"dotnet": [
				{
					"source": "godot",
					"windows_x64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=mono_win64.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=mono_windows_arm64.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=mono_linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=mono_linux.arm64.zip&platform=linux.arm64",
					"macos": "https://downloads.godotengine.org/?version=4.6&flavor=rc2&slug=mono_macos.universal.zip&platform=macos.universal",
				},
				{
					"source": "github",
					"windows_x64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_mono_win64.zip",
					"windows_arm64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_mono_windows_arm64.zip",
					"linux_x64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_mono_linux_x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_mono_linux_arm64.zip",
					"macos": "https://github.com/godotengine/godot-builds/releases/download/4.6-rc2/Godot_v4.6-rc2_mono_macos.universal.zip",
				}
			]
		},
	],
	"4.5": [
		{
			"id": "4.5.1_stable",
			"name": "4.5.1",
			"stable": true,
			"standard": [
				{
					"source": "godot",
					"windows_x64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=win64.exe.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=windows_arm64.exe.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=linux.arm64.zip&platform=linux.arm64",
					"macos": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=macos.universal.zip&platform=macos.universal",
				},
				{
					"source": "github",
					"windows_x64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_win64.exe.zip",
					"windows_arm64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_windows_arm64.exe.zip",
					"linux_x64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_linux.x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_linux.x86_64.zip",
					"macos": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_macos.universal.zip",
				}
			],
			"dotnet": {
				"godot": {
					"windows_x64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=mono_win64.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=mono_windows_arm64.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=mono_linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=mono_linux.arm64.zip&platform=linux.arm64",
					"macos_universal": "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=mono_macos.universal.zip&platform=macos.universal",
				},
				"github": {
					"windows_x64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_mono_win64.zip",
					"windows_arm64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_mono_windows_arm64.zip",
					"linux_x64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_mono_linux_x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_mono_linux_arm64.zip",
					"macos": "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_mono_macos.universal.zip",
				}
			}
		},
		{
			"id": "4.5_stable",
			"name": "4.5",
			"stable": true,
			"standard": {
				"godot": {
					"windows_x64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=win64.exe.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=windows_arm64.exe.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=linux.arm64.zip&platform=linux.arm64",
					"macos": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=macos.universal.zip&platform=macos.universal",
				},
				"github": {
					"windows_x64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_win64.exe.zip",
					"windows_arm64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_windows_arm64.exe.zip",
					"linux_x64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_linux.x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_linux.arm64.zip",
					"macos": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_macos.universal.zip",
				}
			},
			"dotnet": {
				"godot": {
					"windows_x64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=mono_win64.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=mono_windows_arm64.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=mono_linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=mono_linux.arm64.zip&platform=linux.arm64",
					"macos_universal": "https://downloads.godotengine.org/?version=4.5&flavor=stable&slug=mono_macos.universal.zip&platform=macos.universal",
				},
				"github": {
					"windows_x64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_mono_win64.zip",
					"windows_arm64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_mono_windows_arm64.zip",
					"linux_x64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_mono_linux_x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_mono_linux_arm64.zip",
					"macos": "https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_mono_macos.universal.zip",
				}
			},
		}
	],
	"4.4": [
		{
			"id": "4.4.1_stable",
			"name": "4.4.1",
			"stable": true,
			"standard": {
				"godot": {
					"windows_x64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=win64.exe.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=windows_arm64.exe.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=linux.arm64.zip&platform=linux.arm64",
					"macos": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=macos.universal.zip&platform=macos.universal",
				},
				"github": {
					"windows_x64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_win64.exe.zip",
					"windows_arm64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_windows_arm64.exe.zip",
					"linux_x64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.arm64.zip",
					"macos": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_macos.universal.zip",
				},
			},
			"dotnet": {
				"godot": {
					"windows_x64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=mono_win64.zip&platform=windows.64",
					"windows_arm64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=mono_windows_arm64.zip&platform=windows.arm64",
					"linux_x64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=mono_linux.x86_64.zip&platform=linux.64",
					"linux_arm64": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=mono_linux.arm64.zip&platform=linux.arm64",
					"macos_universal": "https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=mono_macos.universal.zip&platform=macos.universal",
				},
				"github": {
					"windows_x64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_mono_win64.zip",
					"windows_arm64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_mono_windows_arm64.zip",
					"linux_x64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_mono_linux_x86_64.zip",
					"linux_arm64": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_mono_linux_arm64.zip",
					"macos": "https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_mono_macos.universal.zip",
				},
			},
		}
	]
}