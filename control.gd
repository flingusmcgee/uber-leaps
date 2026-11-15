extends Control

signal died

@onready var RESPAWN: TextureButton = $Respawn
@onready var HURTSOUND: AudioStreamPlayer = $Hurt

var points: int = 0
var health: int = 5
var paused: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("PAUSE"):
		paused = not paused
		get_tree().paused = paused

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RESPAWN.visible = false
	_hide_order()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$RichTextLabel.text = "Points: " + str(points)

func _hide_order():
	$Sprite2D.visible = false
	$Sprite2D2.visible = false
	$Sprite2D3.visible = false

func _display_order(order: Array[String]):
	$Sprite2D.visible = true
	$Sprite2D2.visible = false
	$Sprite2D3.visible = false

	$Sprite2D.texture = load(order[0])
	if order.size() > 1:
		$Sprite2D2.texture = load(order[1])
		$Sprite2D2.visible = true
	if order.size() > 2:
		$Sprite2D3.texture = load(order[2])
		$Sprite2D3.visible = true

func _take_damage():
	HURTSOUND.play()
	print("take damage")
	if health > 0:
		get_node("Health" + str(health)).texture = load("res://assets/noheart.png")
	health -= 1
	if health < 1:
		died.emit()
		RESPAWN.visible = true
	
func _take_heal():
	if health < 5:
		health += 1
		get_node("Health" + str(health)).texture = load("res://assets/heart.png")

func _on_respawn_button_down() -> void:
	get_tree().reload_current_scene()
