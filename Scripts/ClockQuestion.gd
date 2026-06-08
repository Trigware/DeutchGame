extends Control
class_name ClockQuestion

const spawned_clock_count = 1

var spawned_clocks: Array[QuestionClock]
var used_hours: Array[int]
var used_minutes: Array[int]

func _ready():
	for i in range(spawned_clock_count):
		var clock_instance = UID.question_clock.instantiate()
		clock_instance.clock_index = i
		clock_instance.spawner = self
		spawned_clocks.append(clock_instance)
		add_child(clock_instance)

func show_answers():
	for clock in spawned_clocks: clock.show_answer()
