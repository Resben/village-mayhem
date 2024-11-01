extends CharacterBody2D
class_name Villager

var state = Global.VillagerState.IDLING
var last_state = Global.VillagerState.IDLING
var last_working_state = Global.VillagerState.IDLING

var panic_locations = []

var job_reference : Job

@export var is_demo : bool

var direction
var texture : Texture2D
var house : House

var in_house = false
var is_returning = false

var playback_speed = 1

@onready var original_wait_time = $ActionComplete.wait_time

@onready var emotes = $Emotes
@onready var hurtbox_component : HealthComponent = $HurtBoxComponent
@onready var navigation_component : NavigationComponent = $NavigationComponent
@onready var velocity_component : VelocityComponent = $VelocityComponent

func _ready():
	$AnimationPlayer.play("walk")
	$Sprite2D.texture = Global.get_random_villager()
	
	hurtbox_component._on_damage.connect(on_disaster)
	
	if in_house:
		visible = false
	
	if Global.is_in_disaster:
		on_disaster()
	
	if is_demo:
		state = Global.VillagerState.DEMO
	else:
		playback_speed = Global.current_playback
		$AnimationPlayer.speed_scale = playback_speed

func on_disaster():
	state = Global.VillagerState.SCARED

func disaster_over():
	state = last_working_state
	print(last_working_state)
	exit_house()

func enter_house():
	in_house = true
	visible = false

func has_job():
	if job_reference == null:
		return false
	return job_reference.is_job_complete()

func exit_house(pos = null):
	if pos != null:
		if has_job():
			state = Global.VillagerState.WORKING
	visible = true
	in_house = false
	is_returning = false

func set_job(job):
	state = Global.VillagerState.WORKING
	job_reference = job
	job_reference._on_job_completion.connect(job_complete)

func set_idle():
	state = Global.VillagerState.IDLING

func start_work(type):
	if $ActionComplete.is_stopped():
		$ActionComplete.start()

func job_complete(job_type):
	job_reference = null
	set_idle()

func travel_to(target_position):
	if navigation_component.is_navigation_possible(target_position):
		navigation_component.force_set_target_position(target_position)
	else:
		var current_island
		var target_island
		
		var dock_position
		

func _physics_process(delta):
	
	if state != last_state:
		exit_state(last_state)
		enter_state(state)
		last_state = state
	
	run_state(delta, state)
	
	if in_house:
		return
	
	navigation_component.follow_path()
	velocity_component.move(self)
	
	if velocity_component.velocity.x > 0:
		$Sprite2D.flip_h = false
	elif velocity_component.velocity.x < 0:
		$Sprite2D.flip_h = true

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity

func exit_state(in_state):
	match in_state:
		Global.VillagerState.WORKING:
			pass
		Global.VillagerState.IDLING:
			pass
		Global.VillagerState.SCARED:
			pass

func enter_state(in_state):
	match in_state:
		Global.VillagerState.WORKING:
			$AnimationPlayer.play("walk")
		Global.VillagerState.IDLING:
			navigation_component.set_target_position(Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position)
			$AnimationPlayer.play("walk")
			$Emotes.set_emote("chilled")
		Global.VillagerState.DEMO:
			navigation_component.set_target_position(Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position)
			$AnimationPlayer.play("walk")
		Global.VillagerState.SCARED:
			$Emotes.set_emote("scared")
			last_working_state = last_state
			var new_direction = (house.door_pos - global_position).normalized()
			var perpendicular = Vector2(-new_direction.y, new_direction.x)
			for i in range(3):
				var t = (i + 1) / 3 + randf_range(0.1, -0.1)
				var point_on_line = global_position.lerp(house.door_pos, t)
				var offset = perpendicular * randf_range(-25, 25)
				panic_locations.push_back(point_on_line + offset)

func run_state(delta, in_state):
	match in_state:
		Global.VillagerState.WORKING:
			job_reference.process_job(delta)
			$Emotes.set_emote("work")
		Global.VillagerState.IDLING:
			if navigation_component.is_navigation_finished() && $IdlePeriod.is_stopped():
				$IdlePeriod.start()
				$Emotes.set_emote("chilled")
			elif $IdlePeriod.is_stopped():
				$Emotes.set_emote("none")
		Global.VillagerState.DEMO:
			if navigation_component.is_navigation_finished() && $IdlePeriod.is_stopped():
				$IdlePeriod.start()
				$Emotes.set_emote("chilled")
			elif $IdlePeriod.is_stopped():
				$Emotes.set_emote("none")
		Global.VillagerState.SCARED:
			if panic_locations.size() > 0 && navigation_component.is_navigation_finished():
				navigation_component.set_target_position(panic_locations[0])
				panic_locations.remove_at(0)
			elif panic_locations.size() == 0 && !in_house:
				navigation_component.force_set_target_position(house.door_pos)
			
			if panic_locations.size() == 0 && navigation_component.get_navigation_target() == house.door_pos:
				if navigation_component.is_navigation_finished():
					enter_house()

func set_progress(value):
	if value == 0 || value == 1:
		$TextureProgressBar.visible = false
	else:
		$TextureProgressBar.visible =  true
		
	$TextureProgressBar.value = value

func set_speed(value):
	playback_speed = value
	$AnimationPlayer.speed_scale = value
	$ActionComplete.wait_time = original_wait_time / value

func _on_yum_timeout():
	if state != Global.VillagerState.DEMO:
		Global.remove_resources("food", 1)
		$Yum.start(randi_range(7, 10))

func _on_idle_period_timeout():
	if state == Global.VillagerState.DEMO:
		navigation_component.set_target_position(Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position)
	elif state == Global.VillagerState.IDLING:
		navigation_component.set_target_position(Vector2(randf_range(-500, 500), randf_range(-500, 500)) + global_position)

func _on_action_complete_timeout():
	job_reference.add_work_point()
