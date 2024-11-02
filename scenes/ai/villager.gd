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

var is_travelling = false
var dock1
var dock2
var target

var task_type_to_animation = {
	Global.TaskType.BUILD_HOUSE : "construction", Global.TaskType.BUILD_FARM : "construction", Global.TaskType.BUILD_MINE : "construction", Global.TaskType.REPAIR : "construction", # Construction tasks
	Global.TaskType.ACQUIRE_HOUSE_MATERIAL : "idle", Global.TaskType.ACQUIRE_FARM_MATERIAL : "idle", Global.TaskType.ACQUIRE_MINE_MATERIAL : "idle", # Collection tasks
	Global.TaskType.FARM_FOOD : "food", Global.TaskType.CUT_TREES : "logging", Global.TaskType.MINE_MATERIALS : "mine", # Gathering tasks
	Global.TaskType.CHOP_WOOD : "idle", Global.TaskType.REFINE_MATERIALS : "idle" # Refining tasks
}

@onready var original_wait_time = $ActionComplete.wait_time

@onready var emotes = $Emotes
@onready var hurtbox_component : HurtBoxComponent = $HurtBoxComponent
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
		if job_reference != null:
			if !job_reference.is_job_complete():
				state = job_reference.get_job_state()
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
	$AnimationPlayer.play(task_type_to_animation[type])
	
	if $ActionComplete.is_stopped():
		$ActionComplete.start()

func job_complete(job_type, was_successful):
	job_reference = null
	set_idle()

func get_in_boat():
	navigation_component.set_layer(2)

func get_out_boat():
	navigation_component.set_layer(1)

func travel_to(target_position):
	if navigation_component.is_navigation_possible(target_position):
		state = Global.VillagerState.TRAVELLING
		dock1 = null
		dock2 = null
		target = target_position
	else:
		var current_island = Global.main_map.get_island_id(global_position)
		var target_island = Global.main_map.get_island_id(target_position)
		
		print(str(self.name) + " TO: " + str(current_island) + " to " + str(target_island))
		
		if target_island == -1 || current_island == -1:
			print("Tried to travel to invalid island")
			return false
		
		var dock_pair = Global.get_dock_from_to(current_island, target_island)
		if dock_pair != null:
			state = Global.VillagerState.TRAVELLING
			dock1 = dock_pair[0]
			dock2 = dock_pair[1]
			target = target_position
		
		print("dock1: " + str(dock1.data.connected_ocean_pos) + " & " + str(dock1.data.connected_island_pos))
		print("dock2: " + str(dock2.data.connected_ocean_pos) + " & " + str(dock2.data.connected_island_pos))
	return true

func _physics_process(delta):
	
	if state != last_state:
		exit_state(last_state)
		enter_state(state)
		last_state = state
	
	run_state(delta, state)
	
	if job_reference:
		job_reference.process_job(delta)
	
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
		Global.VillagerState.TRAVELLING:
			if dock1 == null:
				navigation_component.force_set_target_position(target)
			else:
				navigation_component.force_set_target_position(dock1.get_land_position())
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
		Global.VillagerState.TRAVELLING:
			if dock1 == null:
				return
			if navigation_component.is_navigation_finished():
				if navigation_component.get_target_position() == dock1.get_land_position():
					get_in_boat()
					global_position = dock1.get_boat_position()
					navigation_component.force_set_target_position(dock2.get_boat_position())
				elif navigation_component.get_target_position() == dock2.get_boat_position():
					get_out_boat()
					global_position = dock2.get_land_position()
					navigation_component.force_set_target_position(target)
		Global.VillagerState.WORKING:
			pass
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

func _on_idle_period_timeout():
	if state == Global.VillagerState.DEMO:
		navigation_component.set_target_position(Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position)
	elif state == Global.VillagerState.IDLING:
		navigation_component.set_target_position(Vector2(randf_range(-500, 500), randf_range(-500, 500)) + global_position)

func _on_action_complete_timeout():
	job_reference.add_work_point()
