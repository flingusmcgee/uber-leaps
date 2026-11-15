extends CharacterBody3D

signal player_entered

const hoganim1: NodePath = "res://assets/hogwalkup1.png"
const hoganim2: NodePath = "res://assets/hogwalkup2.png"
const hoganim3: NodePath = "res://assets/hogwalkdown1.png"
const hoganim4: NodePath = "res://assets/hogwalkdown2.png"

@export var speed: float = 3.0
@export var range: float = 7.0

@onready var hogmesh: MeshInstance3D = $MeshInstance3D

var counter: float = 0
var frame: int = 0
var target: CharacterBody3D
var is_facing_right: bool
var is_facing_up: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	counter += delta
	frame = round(counter)
	frame = frame % 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var chase_vector := Vector3(target.position.x - position.x, 0, target.position.z - position.z)
	var chase_direction := atan2(chase_vector.z, chase_vector.x) - PI / 4
	if chase_vector.length_squared() > 0.1:
		if chase_direction < 0 and abs(chase_direction) < PI:
			is_facing_right = true
		else:
			is_facing_right = false
		if abs(chase_direction) > PI / 2:
			is_facing_up = true
		else:
			is_facing_up = false

		if chase_vector.length() < range:
			velocity = chase_vector.normalized() * speed
			set_frame()
		else:
			velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO
	move_and_slide()

func set_frame():
	hogmesh.get_surface_override_material(0).uv1_scale.x = 1 if is_facing_right else -1
	if is_facing_up:
		if frame == 0:
			hogmesh.get_surface_override_material(0).albedo_texture = load(hoganim1)
		elif frame == 1:
			hogmesh.get_surface_override_material(0).albedo_texture = load(hoganim2)
	else:
		if frame == 0:
			hogmesh.get_surface_override_material(0).albedo_texture = load(hoganim3)
		elif frame == 1:
			hogmesh.get_surface_override_material(0).albedo_texture = load(hoganim4)
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	player_entered.emit()
