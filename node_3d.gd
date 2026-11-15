extends Node3D

var hedgehog: PackedScene = preload("res://hedgehog.tscn")
var tape: PackedScene = preload("res://tape.tscn")

@export var store: Array[Vector2]
@export var destinations: Array[Vector2]
@export var items: Array[String]
@export var hoglocations: Array[Vector2]
@export var tapelocations: Array[Vector2]

@onready var player: CharacterBody3D = $Player
@onready var pointer: MeshInstance3D = $DestinationPointer
@onready var display: MeshInstance3D = $Order
@onready var control: Control = $Control

@onready var PICKSOUND: AudioStreamPlayer = $Pickup
@onready var DROPSOUND: AudioStreamPlayer = $Dropoff

var order: Array[String]
var destination: int = 0
var order_status: OrderStatus = OrderStatus.EMPTY

var points: int

enum OrderStatus { EMPTY, INPROGRESS }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	control.died.connect(player.die)
	player.interact.connect(_try_interact)
	player.damage.connect(control._take_damage)
	player.heal.connect(control._take_heal)
	
	for i in range(store.size()):
		store[i] *= 2
	for i in range(destinations.size()):
		destinations[i] *= 2
	destinations.append_array(destinations)
	destinations.append_array(destinations)
	destinations.append_array(destinations)
	destinations.append_array(destinations)
	destinations.append_array(destinations)
	destinations.append_array(destinations)
	for i in range(hoglocations.size()):
		hoglocations[i] *= 2
	for i in range(tapelocations.size()):
		tapelocations[i] *= 2
	
	create_hogs()
	create_tapes()
	_create_order()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if order_status == OrderStatus.INPROGRESS:
		pointer.visible = true
		pointer.position.x = destinations[destination].x
		pointer.position.z = destinations[destination].y
		pointer.rotate_y(delta)
	else:
		pointer.visible = false
		
	if order_status == OrderStatus.INPROGRESS:
		player.point_at(destinations[destination])
	else:
		player.point_at(_nearest_store())

func _try_interact(location: Vector2):
	if order_status == OrderStatus.INPROGRESS:
		if location == destinations[destination]:
			_complete_order()
			_create_order()
	if order_status == OrderStatus.EMPTY:
		if location in store:
			PICKSOUND.play()
			destination += 1
			control._display_order(order)
			display.visible = false
			order_status = OrderStatus.INPROGRESS

func _create_order():
	order.clear()
	for i in range(randi_range(1,3)):
		order.append(items[randi_range(0, items.size() - 1)])
	display.visible = true
	display.mesh.material.albedo_texture = load(order[0])

func _complete_order():
	DROPSOUND.play()
	control._hide_order()
	for i in range(order.size()):
		points += 100
	control.points = points
	order_status = OrderStatus.EMPTY

func _nearest_store() -> Vector2:
	var player_xz = Vector2(player.position.x, player.position.z)
	var best = store[0]
	for s in store:
		if s.distance_to(player_xz) < best.distance_to(player_xz):
			best = s
	return best

func create_hogs():
	for hoglocation in hoglocations:
		var newhog = hedgehog.instantiate()
		newhog.position = Vector3(hoglocation.x, 0, hoglocation.y)
		newhog.player_entered.connect(control._take_damage)
		newhog.target = player
		add_child(newhog)

func create_tapes():
	for tapelocation in tapelocations:
		var newtape = tape.instantiate()
		newtape.position = Vector3(tapelocation.x, 0, tapelocation.y)
		add_child(newtape)
