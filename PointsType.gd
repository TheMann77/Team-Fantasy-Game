extends Node2D


const position_points = preload("res://Position_points.tscn")
var points_by_position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _add_positions(positions):
	points_by_position = []
	for i in range(len(positions)):
		var new_position = position_points.instantiate()
		new_position.get_node("Label").text = positions[i]
		new_position.position.y = 30*(i+1)
		points_by_position.append(new_position)
		self.add_child(new_position)
