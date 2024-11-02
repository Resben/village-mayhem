extends Node2D
class_name Workable

enum { CONSTRUCTION, BROKEN, DAMAGED, BUILT, NONE }
var state = CONSTRUCTION
var last_state = NONE

var available_work_slots = 3
var workers = 0
var work_radius = 20

var world_ready = false

@export var health_component : HealthComponent
@export var hurtbox_component : HurtBoxComponent

@export var construction_texture : Texture2D
@export var broken_texture : Texture2D
@export var damaged_texture : Texture2D
@export var built_texture : Texture2D

@export var jobs : Array[Job]

func _ready():
	Global.setup_complete.connect(_on_world_setup)
	if hurtbox_component:
		hurtbox_component._on_damage.connect(_on_damage)
	if health_component:
		health_component._on_health_change.connect(_health_changed)
		health_component._on_health_depletion.connect(_on_destroyed)
		if state != BUILT:
			health_component.current_health = 0
		update_progress()
	else:
		$TextureProgressBar.visible = false
	
	if state == BUILT:
		last_state = BUILT

func _on_world_setup():
	pass

func _process(delta):
	if state != last_state:
		enter_state(state)
		last_state = state

func enter_state(in_state):
	match in_state:
		CONSTRUCTION:
			health_component.current_health = 0
			$Sprite2D.texture = construction_texture
		BROKEN:
			$Sprite2D.texture = broken_texture
		DAMAGED:
			$Sprite2D.texture = damaged_texture
		BUILT:
			if last_state != DAMAGED:
				on_repair_complete()
			$Sprite2D.texture = built_texture

func get_random_edge_location():
	var angle = randf_range(0, TAU)
	var x = work_radius * cos(angle)
	var y = work_radius * sin(angle)
	return Vector2(x, y) + global_position

func on_repair_complete():
	pass

func get_available_workers():
	return available_work_slots - workers

func add_worker():
	workers += 1

func remove_worker():
	workers -= 1

func update_progress():
	if health_component:
		if health_component.has_max_health():
			$TextureProgressBar.visible = false
		else:
			$TextureProgressBar.visible = true
			$TextureProgressBar.value = health_component.get_health_as_percentage()
	else:
		$TextureProgressBar.visible = false

func _on_job_complete(type, was_successful):
	if Global.is_construction_job(type) && was_successful:
		state = BUILT
	else:
		remove_worker()

func create_job(type, villager):
	for j in jobs:
		if j.type == type:
			var newJob = j.duplicate()
			newJob.set_up(self, villager)
			villager.set_job(newJob)
			newJob._on_job_completion.connect(_on_job_complete)
			if Global.is_resource_job(type):
				add_worker()
			return
	print("couldn't find job")

func _health_changed():
	update_progress()

func _on_destroyed():
	state = BROKEN

func _on_damage(dmg, type):
	$WorkableEffects.play_anim(type)
