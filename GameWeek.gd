extends Node2D

var fixturescene
var matches

signal fixture_added
signal fixture_removed
signal gw_removed

# Called when the node enters the scene tree for the first time.
func _ready():
	fixturescene = preload("res://Fixture.tscn")
	matches = []
	_on_add_button_pressed()

func _on_add_button_pressed():
	var new_match = fixturescene.instantiate()
	new_match.position.y = 30 + 60 * len(matches)
	matches.append(new_match)
	new_match.get_node("DeleteButton").pressed.connect(_on_fixture_delete_button_pressed.bind(new_match))
	add_child(new_match)
	emit_signal("fixture_added")

func _on_delete_button_pressed():
	emit_signal("gw_removed")

func _on_fixture_delete_button_pressed(fixture):
	var i = matches.find(fixture, 0)
	matches[i].queue_free()
	for e in range(i+1, len(matches)):
		matches[e].position.y -= 60
	matches.remove_at(i)
	emit_signal("fixture_removed")
