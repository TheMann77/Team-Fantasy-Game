extends Control

var player_id
var player_name
var player_price
var player_pos
var player_total_points
var player_scores
var player_match_score

func assign_player(id, nam, price, pos, total_points, scores, match_score):
	player_id = id
	player_name = nam
	player_price = price
	player_pos = pos
	player_total_points = total_points
	player_scores = scores
	player_match_score = match_score
	$Name.text = player_name.rsplit(" ", true, 1)[-1]
	$Pos.text = player_pos
	$Points.text = str(player_total_points)
