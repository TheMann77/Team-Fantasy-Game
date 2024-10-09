extends Control

const rowscene = preload("res://table_row.tscn")
const pointspage = preload("res://Points.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var league_collection : FirestoreCollection = Firebase.Firestore.collection('leagues')
	var league_document = await league_collection.get_doc(GlobalVars.league_info.league_id)
	var gw
	if league_document:
		$LeagueName.text = league_document.document.league_name.stringValue
		gw = int(league_document.document.last_gw_scored.integerValue)
		if gw > 0:
			$GW.text = "Gameweek " + str(gw)
		else:
			$GW.text = "League yet to start"
	
	var user_query : FirestoreQuery = FirestoreQuery.new()
	user_query.from("users")
	user_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	user_query.order_by("total_points", FirestoreQuery.DIRECTION.DESCENDING)
	var user_results = await Firebase.Firestore.query(user_query)
	if user_results:
		pass
	else:
		connection_error()
		return
	var rank = 1
	var prev_rank = null
	var prev_score = null
	var score = null
	for user in user_results:
		var new_row = rowscene.instantiate()
		if user.document.user_id.stringValue == GlobalVars.auth.localid:
			pass
			#new_row.get_node("Own").visible = true
			#$Own.position.y = 55*(rank-1) + 170
		prev_score = score
		score = user.document.total_points.integerValue
		if score == prev_score:
			new_row.get_node("Rank").text = str(prev_rank)
		else:
			new_row.get_node("Rank").text = str(rank)
			prev_rank = rank
		new_row.get_node("Name").text = user.document.team_name.stringValue
		new_row.get_node("User").text = user.document.user_name.stringValue
		if user.document.has('last_gw_score'):
			new_row.get_node("GW").text = str(user.document.last_gw_score.integerValue)
		else:
			new_row.get_node("GW").text = "0"
		new_row.get_node("Total").text = str(score)
		rank += 1
		new_row.get_node("Select").pressed.connect(_on_player_clicked.bind(user.doc_name, gw))
		$ScrollContainer/VBoxContainer.add_child(new_row)


func connection_error():
	$Error.text = "Connection error"

func _on_player_clicked(user_id, gw):
	print(user_id)
	var newpage = pointspage.instantiate()
	#connect_navbar(currentpage.get_node("Navbar"), "Points")
	newpage.get_team(user_id, gw)
	newpage.get_node("Back").visible = true
	add_child(newpage)
