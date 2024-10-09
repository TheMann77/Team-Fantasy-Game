extends Control

const pointscene = preload("res://score_player_point.tscn")

var point_types
var point_type_scenes
var pos
var player_id

signal added
signal removed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	point_type_scenes = []

func add_point_types(pt):
	point_types = pt

func add_info(p, id):
	pos = p
	player_id = id
	$Pos.text = p

func _on_add_pressed() -> void:
	var new_point = pointscene.instantiate()
	for pt in point_types:
		new_point.get_node("PointType").add_item(pt)
	new_point.position.y = 40 + 40 * len(point_type_scenes)
	point_type_scenes.append(new_point)
	add_child(new_point)
	emit_signal("added")
	custom_minimum_size.y += 40
