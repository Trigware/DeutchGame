extends Node

@onready var music_player = $"Music Player"
var music_playing: bool = false

func play_music(music: AudioStream = null):
	if music != null: music_player.stream = music
	music_playing = true
	music_player.play()
	await music_player.finished
	play_music()

func stop_music():
	music_playing = false
	music_player.stop()

const pitch_shift_range = 0.15

func play_sound(sound: AudioStream):
	var audio_player = AudioStreamPlayer.new()
	audio_player.pitch_scale = randf_range(1 - pitch_shift_range, 1 + pitch_shift_range)
	audio_player.stream = sound
	add_child(audio_player)
	audio_player.play()
	await audio_player.finished
	audio_player.queue_free()

func tween_music_volume(final_volume, tween_duration):
	await create_tween().tween_property(music_player, "volume_db", final_volume, tween_duration).set_ease(Tween.EASE_IN_OUT)

const quiet_music_db = -24

func quiet_music_tween(tween_duration):
	await tween_music_volume(quiet_music_db, tween_duration)

func regular_music_tween(tween_duration): await tween_music_volume(0, tween_duration)
