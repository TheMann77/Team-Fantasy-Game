extends Control

signal league_ended

var positions
var bench_players
var pos_names
var user_doc_name

var chip

var user_collection : FirestoreCollection
var user_document

const positionscene = preload("res://Transfer_position.tscn")
const playerscene = preload("res://Points_player.tscn")
const playerinfoscene = preload("res://player_info.tscn")
const playerbreakdownscene = preload("res://player_breakdown.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func get_team(user_id, gw):
	$Loading.visible = true
	if gw == -1:
		var league_collection : FirestoreCollection = Firebase.Firestore.collection('leagues')
		var league_document = await league_collection.get_doc(GlobalVars.league_info.league_id)
		if league_document: pass
		else:
			$Loading.text = "Connection failed"
		gw = int(league_document.document.last_gw_scored.integerValue)
	var user_team_query : FirestoreQuery = FirestoreQuery.new()
	user_team_query.from("user_teams")
	user_team_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	user_team_query.where("user_id", FirestoreQuery.OPERATOR.EQUAL, user_id, FirestoreQuery.OPERATOR.AND)
	user_team_query.where("gw", FirestoreQuery.OPERATOR.EQUAL, gw)
	var user_team_results = await Firebase.Firestore.query(user_team_query)
	if len(user_team_results) > 1:
		print("not 1 user_team")
		$Loading.text = "Failed to retrieve team"
		return
	var team
	var bench
	var chip
	if len(user_team_results) == 0:
		var user_collection = Firebase.Firestore.collection('users')
		var user_document = await user_collection.get_doc(user_id)
		if not user_document:
			print("no user")
			$Loading.text = "Failed to retrieve team"
			return
		user_team_results = [user_document]
		
		team = user_team_results[0].document.current_team.mapValue.fields
		if user_team_results[0].document.current_bench.arrayValue.has('values'):
			bench = user_team_results[0].document.current_bench.arrayValue.values
		else:
			bench = []
		chip = user_team_results[0].document.current_chip.stringValue
	else:
		team = user_team_results[0].document.team.mapValue.fields
		if user_team_results[0].document.bench.arrayValue.has('values'):
			bench = user_team_results[0].document.bench.arrayValue.values
		else:
			bench = []
		chip = user_team_results[0].document.chip.stringValue
	
	var captain_info = user_team_results[0].document.captain_info.mapValue.fields
	var c_pos
	var c_index
	var vc_pos
	var vc_index
	if captain_info.c_pos.has('stringValue'):
		c_pos = captain_info.c_pos.stringValue
		c_index = int(captain_info.c_index.integerValue)
	if captain_info.vc_pos.has('stringValue'):
		vc_pos = captain_info.vc_pos.stringValue
		vc_index = int(captain_info.vc_index.integerValue)
	
	var gws_query : FirestoreQuery = FirestoreQuery.new()
	gws_query.from("gws")
	gws_query.where("gw_name", FirestoreQuery.OPERATOR.EQUAL, gw, FirestoreQuery.OPERATOR.AND)
	gws_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id)
	var gws_results = await Firebase.Firestore.query(gws_query)
	if len(gws_results) == 0:
		print("No gws")
		$Loading.text = "Failed to retrieve team"
		return
	var ha = []
	var oppo = []
	for fixture in gws_results[0].document.fixtures.arrayValue.values:
		ha.append(fixture.mapValue.fields.HA.stringValue)
		oppo.append(fixture.mapValue.fields.Oppo_abbreviation.stringValue)
	
	
	$GW.text = "Gameweek " + str(gw)
	var chip_string
	if chip == "TC":
		chip_string = "Triple captain"
	elif chip == "BB":
		chip_string = "Bench boost"
	else:
		chip_string = chip
	$ActiveChip.text = "Active chip: " + chip_string
	
	var pos_query : FirestoreQuery = FirestoreQuery.new()
	pos_query.from("positions")
	pos_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id)
	pos_query.order_by("i", FirestoreQuery.DIRECTION.ASCENDING)
	var pos_results = await Firebase.Firestore.query(pos_query)
	
	var player_scores_query : FirestoreQuery = FirestoreQuery.new()
	player_scores_query.from("player_scores")
	player_scores_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	player_scores_query.where("gw", FirestoreQuery.OPERATOR.EQUAL, gw)
	player_scores_query.order_by("match", FirestoreQuery.DIRECTION.ASCENDING)
	var player_scores_results = await Firebase.Firestore.query(player_scores_query)
	var player_scores_dict = {}
	for player_score in player_scores_results:
		if int(player_score.document.match.integerValue) == 1:
			player_scores_dict[player_score.document.player_id.stringValue] = [player_score.document]
		else:
			player_scores_dict[player_score.document.player_id.stringValue].append(player_score.document)
	
	pos_names = []
	for pos in pos_results:
		var pos_name = pos.document.pos_name.stringValue
		pos_names.append(pos_name)
	var total_score = 0
	positions = {}
	for pos in pos_names:
		var players = []
		var pl_index = 0
		for pl in team[pos].arrayValue.values:
			var new_player
			var player_id = pl.mapValue.fields.player_id.stringValue
			var player_name = pl.mapValue.fields.player_name.stringValue
			new_player = playerscene.instantiate()
			var match_score = []
			var player_price
			if pl.mapValue.fields.price.has('doubleValue'):
				player_price = float(pl.mapValue.fields.price.doubleValue)
			else:
				player_price = float(pl.mapValue.fields.price.integerValue)
			var total_points = 0
			var scores = []
			
			var fixture_num = 0
			for fixture in player_scores_dict[player_id]:
				total_points += int(fixture.scores.mapValue.fields.match_points.integerValue)
				scores.append(fixture.scores.mapValue.fields)
				var hg = int(fixture.home_goals.integerValue)
				var ag = int(fixture.away_goals.integerValue)
				var fixture_str
				if ha[fixture_num] == "Home":
					fixture_str = "SPO " + str(hg) + "-" + str(ag) + " " + oppo[fixture_num]
				else:
					fixture_str = oppo[fixture_num] + " " + str(hg) + "-" + str(ag) + " SPO"
				match_score.append(fixture_str)
				fixture_num += 1
			if pos == c_pos and pl_index == c_index:
				if chip == "TC":
					total_points *= 3
				else:
					total_points *= 2
			total_score += total_points

			if pos == vc_pos and pl_index == vc_index:
				new_player.get_node("VC").visible = true
			elif pos == c_pos and pl_index == c_index:
				new_player.get_node("C").visible = true
			
			new_player.assign_player(player_id, player_name, player_price, pos, total_points, scores, match_score)
			new_player.get_node("Info").pressed.connect(_on_player_info.bind(new_player))
			new_player.get_node("Select").pressed.connect(_on_player_pressed.bind(new_player))
			players.append(new_player)
			
			pl_index += 1
		positions[pos] = players

	bench_players = []
	for b in bench:
		var b_pos = b.mapValue.fields.pos.stringValue
		var b_index = int(b.mapValue.fields.index.integerValue)
		var b_player = positions[b_pos][b_index]
		positions[b_pos].remove_at(b_index)
		bench_players.append(b_player)
		if chip != "BB":
			total_score -= b_player.player_total_points
	
	$Score.text = "Total score: " + str(total_score)
	
	$Loading.visible = false
	
	var num_positions = 0
	var num_players = 0
	var new_pos = positionscene.instantiate()
	new_pos.get_node("Name").text = "Starters"
	new_pos.position.y = num_positions * 40 + num_players * 40
	$ScrollContainer/VBoxContainer.add_child(new_pos)
	num_positions += 1
	for pos in pos_names:
		for new_player in positions[pos]:
			new_player.position.y = num_positions * 40 + num_players * 40
			num_players += 1
			$ScrollContainer/VBoxContainer.add_child(new_player)
	new_pos = positionscene.instantiate()
	new_pos.get_node("Name").text = "Bench"
	new_pos.position.y = num_positions * 40 + num_players * 40
	$ScrollContainer/VBoxContainer.add_child(new_pos)
	num_positions += 1
	for new_player in bench_players:
		new_player.position.y = num_positions * 40 + num_players * 40
		num_players += 1
		$ScrollContainer/VBoxContainer.add_child(new_player)

func _on_player_pressed(player):
	var new_breakdown = playerbreakdownscene.instantiate()
	new_breakdown.get_node("Breakdown/Name").text = player.player_name
	new_breakdown.add_types(player.player_scores, player.player_match_score)
	add_child(new_breakdown)

func _on_player_info(player):
	var name = player.player_name
	var price = player.player_price
	var pos = player.player_pos
	var new_info = playerinfoscene.instantiate()
	new_info.get_node("Top/Position").text = pos
	new_info.get_node("Top/Name").text = name
	new_info.get_node("Top/Price").text = "£" + str(price) + "m"
	new_info._on_history_pressed()
	self.add_child(new_info)


func _on_back_pressed() -> void:
	self.queue_free()
