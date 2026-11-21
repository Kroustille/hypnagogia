class_name SettingsMenu
extends Control
## Settings menu: the four bus volumes, fullscreen, VSync and damage numbers. Changes go through Settings
## only (applied at once, saved by Settings). A dragged slider is previewed continuously and saved on
## release; a keyboard, gamepad or track change is saved at once. Pause, Start, Escape or B goes back.
## Texts come from tr() (localization/strings.csv), never from the scene.

signal back_requested

## Placeholder preview, replaced with story 7.7. Played on each saved SFX volume change, never while dragging.
const PREVIEW_SOUND: AudioStream = preload("res://audio/sfx/sfx_player_shot.wav")
## Slider units per linear volume unit (sliders go from 0 to 100 %, step 5).
const PERCENT: float = 100.0

## Slider of each bus, top to bottom.
@onready var _sliders: Dictionary[StringName, HSlider] = {
	Settings.MASTER_BUS: %MasterSlider,
	Settings.MUSIC_BUS: %MusicSlider,
	Settings.SFX_BUS: %SfxSlider,
	Settings.UI_BUS: %UiSlider,
}
@onready var _values: Dictionary[StringName, Label] = {
	Settings.MASTER_BUS: %MasterValue,
	Settings.MUSIC_BUS: %MusicValue,
	Settings.SFX_BUS: %SfxValue,
	Settings.UI_BUS: %UiValue,
}
@onready var _title: Label = %Title
@onready var _fullscreen_button: CheckButton = %FullscreenButton
@onready var _vsync_button: CheckButton = %VsyncButton
@onready var _damage_numbers_button: CheckButton = %DamageNumbersButton
@onready var _back_button: Button = %BackButton

var _dragging: Dictionary[StringName, bool] = {}


func _ready() -> void:
	_title.text = tr(&"UI_SETTINGS_TITLE")
	(%MasterLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_MASTER")
	(%MusicLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_MUSIC")
	(%SfxLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_SFX")
	(%UiLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_UI")
	_fullscreen_button.text = tr(&"UI_SETTINGS_FULLSCREEN")
	_vsync_button.text = tr(&"UI_SETTINGS_VSYNC")
	_damage_numbers_button.text = tr(&"UI_SETTINGS_DAMAGE_NUMBERS")
	_back_button.text = tr(&"UI_SETTINGS_BACK")
	for bus: StringName in _sliders:
		var slider: HSlider = _sliders[bus]
		_dragging[bus] = false
		slider.value_changed.connect(_on_slider_value_changed.bind(bus))
		slider.drag_started.connect(_on_slider_drag_started.bind(bus))
		slider.drag_ended.connect(_on_slider_drag_ended.bind(bus))
	_fullscreen_button.toggled.connect(_on_fullscreen_button_toggled)
	_vsync_button.toggled.connect(_on_vsync_button_toggled)
	_damage_numbers_button.toggled.connect(_on_damage_numbers_button_toggled)
	_back_button.pressed.connect(_on_back_button_pressed)
	hide()


## Reads every value from Settings (without writing anything back), shows the menu, focus on the first slider.
func open() -> void:
	for bus: StringName in _sliders:
		_dragging[bus] = false
		var percent: float = roundf(Settings.volume(bus) * PERCENT)
		_sliders[bus].set_value_no_signal(percent)
		_show_percent(bus, percent)
	_fullscreen_button.set_pressed_no_signal(Settings.fullscreen)
	_vsync_button.set_pressed_no_signal(Settings.vsync)
	_damage_numbers_button.set_pressed_no_signal(Settings.damage_numbers)
	show()
	_sliders[Settings.MASTER_BUS].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _show_percent(bus: StringName, percent: float) -> void:
	_values[bus].text = tr(&"UI_SETTINGS_PERCENT") % roundi(percent)


## Saves the volume (Settings skips an unchanged value) and plays the SFX preview.
func _commit_volume(bus: StringName, percent: float) -> void:
	Settings.set_volume(bus, percent / PERCENT)
	if bus == Settings.SFX_BUS:
		Audio.play_sfx(PREVIEW_SOUND)


func _on_slider_value_changed(percent: float, bus: StringName) -> void:
	_show_percent(bus, percent)
	if _dragging[bus]:
		Settings.preview_volume(bus, percent / PERCENT)
	else:
		_commit_volume(bus, percent)


func _on_slider_drag_started(bus: StringName) -> void:
	_dragging[bus] = true
	var percent: float = _sliders[bus].value
	_show_percent(bus, percent)
	Settings.preview_volume(bus, percent / PERCENT)


func _on_slider_drag_ended(_value_changed: bool, bus: StringName) -> void:
	_dragging[bus] = false
	var percent: float = _sliders[bus].value
	_show_percent(bus, percent)
	_commit_volume(bus, percent)


func _on_fullscreen_button_toggled(pressed: bool) -> void:
	Settings.set_fullscreen(pressed)


func _on_vsync_button_toggled(pressed: bool) -> void:
	Settings.set_vsync(pressed)


func _on_damage_numbers_button_toggled(pressed: bool) -> void:
	Settings.set_damage_numbers(pressed)


func _on_back_button_pressed() -> void:
	back_requested.emit()
