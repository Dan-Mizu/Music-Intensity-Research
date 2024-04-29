extends Node2D

# The number of targets to spawn
@onready var max_target_count = Settings.max_target_count
@onready var spawn_time = Settings.spawn_time
@onready var time_time_to_live = Settings.time_time_to_live
# Minimum distance targets have to be apart
@export var min_dist = 200

# The path to the target scene
const TARGET_SCENE = "res://Scenes/target.tscn"

@onready var timer: Timer = $TargetTimer
# Load the end scene
@onready var end_scene: EndMenu = $CanvasLayer/EndMenu
# Load the target scene
@onready var target_scene = load(TARGET_SCENE)
# Get the screen size
@onready var screen_size = get_viewport_rect().size
# The array of target instances
@onready var targets = []
# The array of active target locs
@onready var active_target_locs = []
@onready var target_locs = []
# List of reaction times for each *hit* target
@onready var reaction_times: Array[int] = []
# Number of targets spawned
@onready var spawned_targets = 0
@onready var accuracy = 0.0
@onready var num_hit = 0
@onready var clicks = 0
@onready var final_target = null
@onready var target_hit = $TargetHit
@onready var target_miss = $TargetMiss
@onready var end = false;

# used as an ID for each data point sent from the client -- possibly not foolproof, but the sample is expected to be ~20 people anyway
var ip_address: String

func _ready():
	timer.wait_time = spawn_time
	timer.timeout.connect(spawn_target)
	timer.start()
	end_scene.visible = false

	# get IP
	ip_address = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)

func _on_target_hide(target: Target):
	active_target_locs.pop_front()
	target_locs.append(target)

	# Add to hit count
	if target.hit:
		num_hit += 1

		# Store reaction time
		if target.reaction_time:
			reaction_times.push_back(target.reaction_time)

	# Check if there are no more targets left
	if spawned_targets == max_target_count and target == final_target:
		# End the game
		end_game()

func spawn_target():
	# Create a new target instance
	var target = target_scene.instantiate()
	# Make the target invisible
	target.visible = false;
	# Add it to the scene
	add_child(target)
	target.timetolive.wait_time = time_time_to_live
	# Target radius to 
	var radius = target.collision_shape_2d.shape.radius
	# Attempt to get a random location that is not too close to another target
	var newLoc = getSpawnLoc(radius)
	# Check if the placement worked
	while(newLoc == Vector2(-1, -1)):
		# Wait for next frame and try again
		await get_tree().process_frame
		newLoc = getSpawnLoc(radius)
	# Set its position to a random point on the screen
	target.position = newLoc
	# Make the target visible
	target.visible = true
	# Add it to the array
	targets.append(target)
	# Connect its hide signal to a function that handles target hiding
	target.hidden.connect(_on_target_hide.bind(target))
	# Increment the amount of targets and check if it reached the max number to stop spawning targets
	spawned_targets += 1
	if spawned_targets == max_target_count:
		final_target = target
		timer.queue_free()
func getSpawnLoc(radius) -> Vector2:
	var max_tries = 100
	while (max_tries > 0):
		var newLoc = Vector2(randf_range(0 + radius, screen_size.x - radius), randf_range(0 + radius, screen_size.y - radius))
		var tooClose = false
		for loc in active_target_locs:
			if newLoc.distance_to(loc) < min_dist:
				tooClose = true
				break
		if !tooClose:
			active_target_locs.append(newLoc)
			return newLoc
		max_tries -= 1
	return Vector2(-1,-1)

func end_game():
	end = true
	end_scene.visible = true

	# display targets hit
	end_scene.targets_hit.text = "Targets hit: " + str(num_hit) + "/"  + str(spawned_targets)

	# display miss count
	end_scene.misses.text = "Misses: " + str(clicks - num_hit)

	# calculate and display accuracy
	accuracy = (100 * num_hit) / float(maxi(1, clicks))
	end_scene.accuracy.text = "Accuracy: " + str(accuracy)  + "%"

	# calculate and display average reaction time
	if reaction_times.size() > 0:
		var reaction_time_sum = 0
		for time in reaction_times:
			reaction_time_sum += time
		var average_reaction_time = reaction_time_sum / float(reaction_times.size())
		end_scene.reaction_time.text = "Avg. Reaction Time: " + str(average_reaction_time)  + "ms"
	else:
		end_scene.reaction_time.hide()

func _unhandled_input(event):
	if (end == true):
		return
	if event is InputEventMouseButton:
		if event.pressed:
			clicks += 1
			for target in targets:
				if target.visible and target.mouse_hover:
					target_hit.play()
					return
			target_miss.play()

func _on_control_resized():
	pass # Replace with function body.
