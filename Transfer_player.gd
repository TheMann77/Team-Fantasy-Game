extends Control

var player_id
var player_name
var player_price
var player_pos
var first_player_id


# Called when the node enters the scene tree for the first time.
func _ready():
	$NotBlank.visible = true
	$Blank.visible = false


func _on_remove_pressed():
	$NotBlank.visible = false
	$Blank.visible = true

func _on_restore_pressed():
	$NotBlank.visible = true
	$Blank.visible = false

func assign_player(id, nam, price, pos, first):
	player_id = id
	player_name = nam
	player_price = price
	player_pos = pos
	if first:
		first_player_id = player_id
	$NotBlank/Name.text = player_name.rsplit(" ", true, 1)[-1]
	var price_string = "£" + str(player_price)
	if int(player_price) == player_price:
		price_string += ".0"
	price_string += "m"
	$NotBlank/Price.text = price_string
	
