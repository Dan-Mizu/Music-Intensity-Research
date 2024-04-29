extends Area2D
class_name Target

@onready var collision_shape_2d = $CollisionShape2D
@onready var timetolive = $TimeToLive
@onready var hit = false
@onready var initial_time: int
@onready var reaction_time: int
var mouse_hover = false

func _on_input_event(_viewport, event, _shape_idx):
	# Check if the event is a left mouse button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Mark as hit
		hit = true

		# Calculate and store reaction time
		reaction_time = Time.get_ticks_msec() - initial_time

		# Hide the target
		hide()
		mouse_hover = false

func _on_draw():
	# start timer
	timetolive.start()

	# get initial time
	initial_time = Time.get_ticks_msec()

func _on_time_to_live_timeout():
	hide()
	mouse_hover = false

func _on_mouse_entered():
	if visible:
		mouse_hover = true

func _on_mouse_exited():
	mouse_hover = false
