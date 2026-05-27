extends Node

@onready var music_player = $"Music Player"

func play_music(music: AudioStream = null):
	if music != null: music_player.stream = music
	music_player.play()
	await music_player.finished
	play_music()

func tween_music_volume(final_volume, tween_duration):
	await create_tween().tween_property(music_player, "volume_db", final_volume, tween_duration).set_ease(Tween.EASE_IN_OUT)

const quiet_music_db = -24

func quiet_music_tween(tween_duration):
	await tween_music_volume(quiet_music_db, tween_duration)

func regular_music_tween(tween_duration): await tween_music_volume(0, tween_duration)
