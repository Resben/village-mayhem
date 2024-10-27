extends Control

var next_callback : Callable
var scene_to_load : String
var is_loading = false

var scene_status
var scene_progress = []

var next_scene = null

func _process(delta):
	if is_loading:
		if scene_to_load == "null":
			is_loading = false
			$Default.start()
			return
		scene_status = ResourceLoader.load_threaded_get_status(scene_to_load, scene_progress)
		# Set text progress
		if scene_status == ResourceLoader.THREAD_LOAD_LOADED:
			next_scene = ResourceLoader.load_threaded_get(scene_to_load).instantiate()
			get_node("/root/").add_child(next_scene)
	if next_scene != null:
		if next_scene.is_level_ready():
			is_loading = false
			Global.is_scene_loaded = true
			scene_loaded()
			next_scene = null

func play_transition(callback : Callable, scene_id : String = "null"):
	scene_to_load = scene_id
	next_callback = callback
	is_loading = true
	$AnimationPlayer.play("transition")

func play_callback():
	$Sprite2D3.visible = true
	$Label.visible = true
	$LoadingAnimationPlayer.play("loop")
	next_callback.call()
	if scene_to_load != "null":
		ResourceLoader.load_threaded_request(scene_to_load)

func scene_loaded():
	$LoadingAnimationPlayer.stop()
	$Sprite2D3.visible = false
	$Label.visible = false
	$AnimationPlayer.play("transition_pt2")

func _on_default_timeout():
	scene_loaded()
