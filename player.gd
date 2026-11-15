extends CharacterBody3D

signal interact(location: Vector2)
signal damage
signal heal

@export var JUMP_HEIGHT = 7
@export var JUMP_DIST = 4
@export var GRAVITY = 0.5
@export var ANIM_SPEED = 0.1

@onready var POINTER: MeshInstance3D = $Pointer
@onready var SPRITE: MeshInstance3D = $Sprite
@onready var DETECTHOG: Area3D = $DetectHog
@onready var DETECTTAPE: Area3D = $DetectTape
@onready var landing_particles: CPUParticles3D = $CPUParticles3D

@onready var BOINGSOUND: AudioStreamPlayer = $Boing
@onready var DIESOUND: AudioStreamPlayer = $Die

var running = true
var direction = Vector2(1,1)
var processing_dir: float
var rad_dir: float
var sprites: Array[CompressedTexture2D]
var landed: bool = false
var squished: bool = false
var damaging: bool = false

var order: String

var speed_multiplier: float = 1

func _ready():
	sprites.append(load("res://assets/upfull.png"))
	sprites.append(load("res://assets/downfull.png"))
	sprites.append(load("res://assets/urfull.png"))
	sprites.append(load("res://assets/drfull.png"))
	sprites.append(load("res://assets/leftfull.png"))
	sprites.append(load("res://assets/upsquish.png"))
	sprites.append(load("res://assets/downsquish.png"))
	sprites.append(load("res://assets/ursquish.png"))
	sprites.append(load("res://assets/drsquish.png"))
	sprites.append(load("res://assets/leftsquish.png"))

func _process(_delta: float) -> void:
	if not damaging:
		if DETECTHOG.get_overlapping_bodies().size() > 0:
			damage.emit()
			damaging = true
	else:
		if DETECTHOG.get_overlapping_bodies().size() == 0:
			damaging = false
	
	if DETECTTAPE.get_overlapping_bodies().size() > 0:
		for tape in DETECTTAPE.get_overlapping_bodies():
			tape.queue_free()
			take_heal()
	
	var new_direction = Vector2.ZERO
		
	if Input.is_action_pressed("FORWARD"):
		new_direction.x += 1
		new_direction.y += 1
	if Input.is_action_pressed("BACKWARD"):
		new_direction.x += -1
		new_direction.y += -1
	if Input.is_action_pressed("LEFT"):
		new_direction.x += 1
		new_direction.y += -1
	if Input.is_action_pressed("RIGHT"):
		new_direction.x += -1
		new_direction.y += 1
	if new_direction.x != 0:
		new_direction.x = new_direction.x / abs(new_direction.x)
	if new_direction.y != 0:
		new_direction.y = new_direction.y / abs(new_direction.y)
	
	if running:
		if new_direction.length() > 0:
			direction = new_direction
		
		var squish_adder = 5 if squished else 0
		match direction:
			Vector2(1, 1): #UP
				$Sprite.mesh.material.albedo_texture = sprites[0 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = 1
			Vector2(1, 0): #UPLEFT
				$Sprite.mesh.material.albedo_texture = sprites[2 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = -1
			Vector2(1, -1): #LEFT
				$Sprite.mesh.material.albedo_texture = sprites[4 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = 1
			Vector2(0, 1): #UPRIGHT
				$Sprite.mesh.material.albedo_texture = sprites[2 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = 1
			Vector2(0, -1): #DOWNLEFT
				$Sprite.mesh.material.albedo_texture = sprites[3 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = -1
			Vector2(-1, 1): #RIGHT
				$Sprite.mesh.material.albedo_texture = sprites[4 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = -1
			Vector2(-1, 0): #DOWNRIGHT
				$Sprite.mesh.material.albedo_texture = sprites[3 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = 1
			Vector2(-1, -1): #DOWN
				$Sprite.mesh.material.albedo_texture = sprites[1 + squish_adder]
				$Sprite.mesh.material.uv1_scale.x = 1

func _physics_process(delta: float) -> void:
	velocity.y -= GRAVITY
	
	if position.y > 1.3:
		squished = false
	
	if is_on_floor() and running:
		squished = true
		_jump()
		landing_particles.restart()
	
	if not running:
		velocity.x = 0
		velocity.z = 0
		POINTER.visible = false
	
	move_and_slide()
	
func _move_forward():
	var try_move = Vector3(-direction.x * JUMP_DIST / 2, 0, -direction.y * JUMP_DIST / 2)
	if test_move(transform, try_move):
		velocity.x = 0
		velocity.z = 0
		var interact_location := Vector2(round(position.x - direction.x * JUMP_DIST / 2), round(position.z - direction.y * JUMP_DIST / 2))
		print(interact_location)
		interact.emit(interact_location)
	else:
		velocity.x = -direction.x * JUMP_DIST / speed_multiplier
		velocity.z = -direction.y * JUMP_DIST / speed_multiplier

func _jump():
	BOINGSOUND.play()
	velocity.y = JUMP_HEIGHT * speed_multiplier
	_move_forward()

func take_damage():
	damage.emit()

func take_heal():
	heal.emit()

func die():
	if running:
		DIESOUND.play()
		running = false
		var tween = create_tween()
		tween.tween_property(SPRITE.mesh.material, "albedo_texture", load("res://assets/pop1.png"), ANIM_SPEED)
		tween.tween_property(SPRITE.mesh.material, "albedo_texture", load("res://assets/pop2.png"), ANIM_SPEED)
		tween.tween_property(SPRITE.mesh.material, "albedo_texture", load("res://assets/pop3.png"), ANIM_SPEED)
		tween.tween_property(SPRITE.mesh.material, "albedo_texture", load("res://assets/pop4.png"), ANIM_SPEED)

func point_at(location: Vector2):
	var wingo = Vector3(location.x - position.x, 0, location.y - position.z)
	POINTER.rotation.y = atan2(wingo.x, wingo.z)
