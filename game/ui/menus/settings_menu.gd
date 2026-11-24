class_name SettingsMenu
extends Control
## Settings menu: the four bus volumes, fullscreen, VSync, damage numbers, and the screen effects (distortion and
## shake intensity, photosensitivity mode). Changes go through Settings
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
@onready var _distortion_slider: HSlider = %DistortionSlider
@onready var _shake_slider: HSlider = %ShakeSlider
@onready var _distortion_value: Label = %DistortionValue
@onready var _shake_value: Label = %ShakeValue
@onready var _photosensitive_button: CheckButton = %PhotosensitiveButton
@onready var _back_button: Button = %BackButton

var _dragging: Dictionary[StringName, bool] = {}
## A screen effect slider is being dragged: its value is saved on release (every step would write the file).
var _distortion_dragging: bool = false
var _shake_dragging: bool = false


func _ready() -> void:
	_title.text = tr(&"UI_SETTINGS_TITLE")
	(%MasterLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_MASTER")
	(%MusicLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_MUSIC")
	(%SfxLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_SFX")
	(%UiLabel as Label).text = tr(&"UI_SETTINGS_VOLUME_UI")
	_fullscreen_button.text = tr(&"UI_SETTINGS_FULLSCREEN")
	_vsync_button.text = tr(&"UI_SETTINGS_VSYNC")
	_damage_numbers_button.text = tr(&"UI_SETTINGS_DAMAGE_NUMBERS")
	(%DistortionLabel as Label).text = tr(&"UI_SETTINGS_DISTORTION")
	(%ShakeLabel as Label).text = tr(&"UI_SETTINGS_SHAKE")
	_photosensitive_button.text = tr(&"UI_SETTINGS_PHOTOSENSITIVE")
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
	_distortion_slider.value_changed.connect(_on_distortion_value_changed)
	_distortion_slider.drag_started.connect(_on_distortion_drag_started)
	_distortion_slider.drag_ended.connect(_on_distortion_drag_ended)
	_shake_slider.value_changed.connect(_on_shake_value_changed)
	_shake_slider.drag_started.connect(_on_shake_drag_started)
	_shake_slider.drag_ended.connect(_on_shake_drag_ended)
	_photosensitive_button.toggled.connect(_on_photosensitive_button_toggled)
	_back_button.pressed.connect(_on_back_button_pressed)
	hide()


## A slider hidden mid-drag (Escape, Start or B while the mouse holds it) never gets drag_ended: save the
## previewed value now, so the bus, Settings and settings.cfg stay in sync.
func _notification(what: int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED or is_visible_in_tree():
		return
	if _distortion_dragging:
		_distortion_dragging = false
		Settings.set_distortion_intensity(_distortion_slider.value / PERCENT)
	if _shake_dragging:
		_shake_dragging = false
		Settings.set_shake_intensity(_shake_slider.value / PERCENT)
	for bus: StringName in _dragging:
		if _dragging[bus]:
			_dragging[bus] = false
			_commit_volume(bus, _sliders[bus].value)


## Reads every value from Settings (without writing anything back), shows the menu, focus on the first slider.
func open() -> void:
	for bus: StringName in _sliders:
		_dragging[bus] = false
		var slider: HSlider = _sliders[bus]
		slider.set_value_no_signal(roundf(Settings.volume(bus) * PERCENT))
		# The slider snaps to its step: show its value, not the stored one (0.83 shows 85 %, like the slider).
		_show_percent(bus, slider.value)
	_fullscreen_button.set_pressed_no_signal(Settings.fullscreen)
	_vsync_button.set_pressed_no_signal(Settings.vsync)
	_damage_numbers_button.set_pressed_no_signal(Settings.damage_numbers)
	_distortion_dragging = false
	_shake_dragging = false
	_distortion_slider.set_value_no_signal(roundf(Settings.distortion_intensity * PERCENT))
	_shake_slider.set_value_no_signal(roundf(Settings.shake_intensity * PERCENT))
	_distortion_value.text = tr(&"UI_SETTINGS_PERCENT") % roundi(_distortion_slider.value)
	_shake_value.text = tr(&"UI_SETTINGS_PERCENT") % roundi(_shake_slider.value)
	_photosensitive_button.set_pressed_no_signal(Settings.photosensitive)
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


## Saves the volume (Settings skips an unchanged value) and plays the SFX preview if the volume changed.
func _commit_volume(bus: StringName, percent: float) -> void:
	var before: float = Settings.volume(bus)
	Settings.set_volume(bus, percent / PERCENT)
	if bus == Settings.SFX_BUS and Settings.volume(bus) != before:
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


func _on_distortion_value_changed(percent: float) -> void:
	_distortion_value.text = tr(&"UI_SETTINGS_PERCENT") % roundi(percent)
	if not _distortion_dragging:
		Settings.set_distortion_intensity(percent / PERCENT)


func _on_distortion_drag_started() -> void:
	_distortion_dragging = true


func _on_distortion_drag_ended(_value_changed: bool) -> void:
	_distortion_dragging = false
	Settings.set_distortion_intensity(_distortion_slider.value / PERCENT)


func _on_shake_value_changed(percent: float) -> void:
	_shake_value.text = tr(&"UI_SETTINGS_PERCENT") % roundi(percent)
	if not _shake_dragging:
		Settings.set_shake_intensity(percent / PERCENT)


func _on_shake_drag_started() -> void:
	_shake_dragging = true


func _on_shake_drag_ended(_value_changed: bool) -> void:
	_shake_dragging = false
	Settings.set_shake_intensity(_shake_slider.value / PERCENT)


func _on_photosensitive_button_toggled(pressed: bool) -> void:
	Settings.set_photosensitive(pressed)


func _on_back_button_pressed() -> void:
	back_requested.emit()
