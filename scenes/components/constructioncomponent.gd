extends Node
class_name ConstructionComponent

@export var health_component : HealthComponent
@export var hitbox_component : HitBoxComponent

var is_built = false
var is_broken = false

var construction_percentage = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
