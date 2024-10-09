extends Control

var player_id
var player_name
var player_price
var player_pos
var player_oppo
var first_player_id
var player_index
var player_is_start

func assign_player(id, nam, price, oppo, pos, i, is_start, first):
	player_id = id
	player_name = nam
	player_price = price
	player_pos = pos
	player_oppo = oppo
	player_index = i
	if first:
		player_is_start = is_start
		first_player_id = player_id
	$Name.text = player_name.rsplit(" ", true, 1)[-1]
	$Oppo.text = player_oppo
	$Pos.text = player_pos
