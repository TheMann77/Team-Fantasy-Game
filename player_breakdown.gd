extends Control

const type_scene = preload("res://player_score_type.tscn")
const match_scene = preload("res://player_breakdown_match.tscn")

func _on_remove_pressed() -> void:
	self.queue_free()

func add_types(scores, match_score):
	var match_pos = 40
	var breakdown_size = 55
	for fixture_num in range(len(scores)):
		var new_match = match_scene.instantiate()
		new_match.get_node("Score").text = match_score[fixture_num]
		var match_size = 70
		var i = 0
		for type in scores[fixture_num]:
			if type != "match_points":
				var new_type = type_scene.instantiate()
				new_type.get_node("Statistic").text = type
				new_type.get_node("Num").text = str(scores[fixture_num][type].mapValue.fields.num.integerValue)
				new_type.get_node("Points").text = str(scores[fixture_num][type].mapValue.fields.points.integerValue)
				new_type.position.y = 30 + i * 30
				new_type.position.x = 0
				new_match.get_node("Stats").add_child(new_type)
				match_size += 30
				i += 1
		new_match.position.y = match_pos
		match_pos += match_size
		$Breakdown.add_child(new_match)
		breakdown_size += match_size
	$Breakdown.set_size(Vector2(360, breakdown_size))
