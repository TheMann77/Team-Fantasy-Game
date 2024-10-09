extends Control

const playerscene = preload("res://score_player.tscn")

var player_scenes
var point_type_results
var player_scores

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var players_query : FirestoreQuery = FirestoreQuery.new()
	players_query.from("players")
	players_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id)
	var player_results = await Firebase.Firestore.query(players_query)
	
	var point_types_query : FirestoreQuery = FirestoreQuery.new()
	point_types_query.from("point_types")
	point_types_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id)
	point_type_results = await Firebase.Firestore.query(point_types_query)
	
	var point_type_names = []
	for point_type in point_type_results:
		point_type_names.append(point_type.document.point_name.stringValue)
	
	var i = 0
	player_scenes = []
	for player in player_results:
		var new_player = playerscene.instantiate()
		new_player.get_node("Name").text = player.document.player_name.stringValue
		new_player.add_point_types(point_type_names)
		new_player.position.y = 45 * i
		new_player.added.connect(_on_added.bind(i))
		new_player.removed.connect(_on_removed.bind(i))
		new_player.add_info(player.document.position.stringValue, player.doc_name)
		$ScrollContainer/VBoxContainer.add_child(new_player)
		player_scenes.append(new_player)
		i += 1

func _on_added(i):
	for e in range(i+1, len(player_scenes)):
		player_scenes[e].position.y += 40
	$ScrollContainer/VBoxContainer.custom_minimum_size.y += 40

func _on_removed(i):
	for e in range(i+1, len(player_scenes)):
		player_scenes[i].position.y -= 40
	$ScrollContainer/VBoxContainer.custom_minimum_size.y -= 40


func _on_update_scores_pressed() -> void:
	player_scores = {}
	for player in player_scenes:
		var player_score = {}
		var score = 0
		var player_pos = player.pos
		for type in player.point_type_scenes:
			var point_type_i = int(type.get_node("PointType").selected)
			var num = int(type.get_node("Num").text)
			var scoring = point_type_results[point_type_i].document[player_pos].mapValue.fields
			var type_score = int(num / int(scoring.per.integerValue)) * int(scoring.points.integerValue)
			type.get_node("Points").text = str(type_score)
			score += type_score
			var type_name = type.get_node("PointType").get_item_text(point_type_i)
			player_score[type_name] = {"num": num, "points": type_score}
		player.get_node("Score").text = str(score)
		player_score["match_points"] = score
		player_scores[player.player_id] = player_score


func _on_confirm_pressed() -> void:
	_on_update_scores_pressed()
	
	if not $GW.text.is_valid_int():
		print("GW not valid")
		return
	if not $Match.text.is_valid_int():
		print("Match not valid")
		return
	if not $HomeGoals.text.is_valid_int():
		print("Home goals not valid")
		return
	if not $AwayGoals.text.is_valid_int():
		print("Away goals not valid")
		return
	var leagues_collection = Firebase.Firestore.collection("leagues")
	var league_document = await leagues_collection.get_doc(GlobalVars.league_info.league_id)
	if int(league_document.document.last_gw_scored.integerValue) > int($GW.text):
		print("GW less than last one scored")
		return
	
	var user_teams_query : FirestoreQuery = FirestoreQuery.new()
	user_teams_query.from("user_teams")
	user_teams_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	user_teams_query.where("gw", FirestoreQuery.OPERATOR.EQUAL, int($GW.text))
	var user_teams_results = await Firebase.Firestore.query(user_teams_query)
	
	var teams = []
	for user_team in user_teams_results:
		var user_id = user_team.document.user_id.stringValue
		teams.append(make_team(user_team, user_id))
	
	var users_query : FirestoreQuery = FirestoreQuery.new()
	users_query.from("users")
	users_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	users_query.where("last_gw_changed", FirestoreQuery.OPERATOR.EQUAL, int($GW.text))
	var users_results = await Firebase.Firestore.query(users_query)
	for user_team in users_results:
		var user_id = user_team.doc_name
		teams.append(make_team(user_team, user_id))
	
	var team_scores = {}
	for team in teams:
		var team_score = 0
		for pl in team.team:
			team_score += player_scores[pl].match_points
		var c_multiplier = 1
		if team.chip == "TC":
			c_multiplier = 2
		team_score += player_scores[team.captain].match_points * c_multiplier
		team_scores[team.user_id] = team_score
	
	var players_collection = Firebase.Firestore.collection("players")
	for player in player_scores:
		var player_document = await players_collection.get_doc(player)
		player_document.add_or_update_field("total_points", player_scores[player].match_points)
		player_document = await players_collection.update(player_document)
	print("Uploaded player totals")
	

	var users_collection = Firebase.Firestore.collection("users")
	for team in team_scores:
		var user_document = await users_collection.get_doc(team)
		var prev_points = int(user_document.document.total_points.integerValue)
		var prev_gw_points
		if user_document.document.has('last_gw_score'):
			prev_gw_points = user_document.document.last_gw_score.integerValue
		else:
			prev_gw_points = 0
		user_document.add_or_update_field("total_points", prev_points + team_scores[team])
		if int($Match.text) > 1:
			user_document.add_or_update_field("last_gw_score", prev_gw_points + team_scores[team])
		else:
			user_document.add_or_update_field("last_gw_score", team_scores[team])
		user_document = await users_collection.update(user_document)
	print("Uploaded user scores")
	
	var player_scores_collection = Firebase.Firestore.collection("player_scores")
	for player_score in player_scores:
		var player_score_document = await player_scores_collection.add("", {
			"league_id": GlobalVars.league_info.league_id,
			"gw": int($GW.text),
			"match": int($Match.text),
			"player_id": player_score,
			"scores": player_scores[player_score],
			"home_goals": int($HomeGoals.text),
			"away_goals": int($AwayGoals.text)
		})
	print("Uploaded player match scores")
	
	league_document.add_or_update_field("last_gw_scored", int($GW.text))
	league_document = await leagues_collection.update(league_document)
	print("Updated league info")
	print("Done")

func make_team(user_team, user_id):
	var team_dict
	var bench_dict
	var chip
	if user_team.document.has('team'):
		team_dict = user_team.document.team.mapValue.fields
		bench_dict = user_team.document.bench.arrayValue.values
		if user_team.document.has('chip'):
			chip = user_team.document.chip.stringValue
		else:
			chip = "None"
	else:
		team_dict = user_team.document.current_team.mapValue.fields
		bench_dict = user_team.document.current_bench.arrayValue.values
		if user_team.document.has('current_chip'):
			chip = user_team.document.current_chip.stringValue
		else:
			chip = "None"
	var captain_info = user_team.document.captain_info.mapValue.fields
	var user_bench = []
	var user_team_nice = []
	for bench_player in bench_dict:
		user_bench.append([int(bench_player.mapValue.fields.index.integerValue), bench_player.mapValue.fields.pos.stringValue])
	var captain
	for pos in team_dict:
		var i = 0
		for player in team_dict[pos].arrayValue.values:
			if ([i, pos] not in user_bench) or (chip == "BB"):
				user_team_nice.append(player.mapValue.fields.player_id.stringValue)
			if i == int(captain_info.c_index.integerValue) and pos == captain_info.c_pos.stringValue:
				captain = player.mapValue.fields.player_id.stringValue
			i += 1
	return {
		"user_id": user_id,
		"team": user_team_nice,
		"captain": captain,
		"chip": chip
		}
	
