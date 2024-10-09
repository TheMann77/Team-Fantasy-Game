extends Control

const player_scene = preload("res://Select_player.tscn")
const playerinfoscene = preload("res://player_info.tscn")

signal player_selected

var selected_player


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _add_players(pos_name):
	var players_query : FirestoreQuery = FirestoreQuery.new()
	players_query.from("players")
	players_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	players_query.where("position", FirestoreQuery.OPERATOR.EQUAL, pos_name)
	players_query.order_by_fields([
		["total_points", FirestoreQuery.DIRECTION.DESCENDING],
		["price", FirestoreQuery.DIRECTION.DESCENDING]
	])
	var players_results = await Firebase.Firestore.query(players_query)
	
	for player in players_results:
		var new_player = player_scene.instantiate()
		var player_name = player.document.player_name.stringValue
		var player_price
		if player.document.price.has('doubleValue'):
			player_price = float(player.document.price.doubleValue)
		else:
			player_price = float(player.document.price.integerValue)
		var player_points = int(player.document.total_points.integerValue)
		new_player.get_node("Name").text = player_name
		new_player.get_node("Price").text = "£" + str(player_price) + "m"
		new_player.get_node("Points").text = str(player_points)
		new_player.get_node("Info").pressed.connect(_on_player_info.bind(player_name, player_price, pos_name))
		new_player.get_node("Select").pressed.connect(_on_player_selected.bind(player_name, player_price, pos_name, player.doc_name))
		$Players/ScrollContainer/VBoxContainer.add_child(new_player)

func _on_player_info(name, price, pos):
	var new_info = playerinfoscene.instantiate()
	new_info.get_node("Top/Position").text = pos
	new_info.get_node("Top/Name").text = name
	new_info.get_node("Top/Price").text = "£" + str(price) + "m"
	self.add_child(new_info)

func _on_remove_pressed():
	self.queue_free()

func _on_player_selected(player_name, player_price, pos_name, player_id):
	selected_player = {
		"player_name": player_name,
		"player_price": player_price,
		"pos_name": pos_name,
		"player_id": player_id
	}
	emit_signal("player_selected")
