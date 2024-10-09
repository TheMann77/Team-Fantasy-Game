extends Control

signal league_joined


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_join_league_pressed():
	$Error.text = "Joining league..."
	if len($LeagueCode.text) == 0:
		$Error.text = "Enter a league code"
		return
	if len($TeamName.text) == 0:
		$Error.text = "Enter a team name"
		return
	if len($UserName.text) == 0:
		$Error.text = "Enter your name"
		return
	var leagues_collection : FirestoreCollection = Firebase.Firestore.collection("leagues")
	var league_document = await leagues_collection.get_doc($LeagueCode.text)
	
	if league_document:
		var league_name = league_document.document.league_name.stringValue
		
		
		#Check if already in league
		var users_collection : FirestoreCollection = Firebase.Firestore.collection("users")
		var user_query : FirestoreQuery = FirestoreQuery.new()
		user_query.from("users")
		user_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, $LeagueCode.text, FirestoreQuery.OPERATOR.AND)
		user_query.where("user_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.auth.localid)
		var user_results = await Firebase.Firestore.query(user_query)
		if len(user_results):
			$Error.text = "Already in this league"
			return
		
		
		#Want to choose the cheapest set of players here as a template
		var pos_query : FirestoreQuery = FirestoreQuery.new()
		pos_query.from("positions")
		pos_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, $LeagueCode.text)
		var pos_results = await Firebase.Firestore.query(pos_query)
		
		var team = {}
		var bench = []
		var captain_info = {"c_index": null, "c_pos": null, "vc_index": null, "vc_pos": null}
		var budget = int(league_document.document.budget.integerValue)
		var squad_size = 0
		for pos in pos_results:
			squad_size += int(pos.document.in_squad.integerValue)
		var bench_needed = squad_size - int(league_document.document.team_size.integerValue)
		for pos in pos_results:
			var num_in_squad = int(pos.document.in_squad.integerValue)
			var pos_name = pos.document.pos_name.stringValue
			team[pos_name] = []
			var cheap_query : FirestoreQuery = FirestoreQuery.new()
			cheap_query.from("players")
			cheap_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, $LeagueCode.text, FirestoreQuery.OPERATOR.AND)
			cheap_query.where("position", FirestoreQuery.OPERATOR.EQUAL, pos_name)
			cheap_query.order_by("price", FirestoreQuery.DIRECTION.ASCENDING)
			var cheap_results = await Firebase.Firestore.query(cheap_query)
			for i in range(num_in_squad):
				var new_player = cheap_results[i]
				var player_price
				if new_player.document.price.has('doubleValue'):
					player_price = float(new_player.document.price.doubleValue)
				else:
					player_price = float(new_player.document.price.integerValue)
				team[pos_name].append({
					"player_id": new_player.doc_name,
					"player_name": new_player.document.player_name.stringValue,
					"price": player_price
					})
				budget -= float(player_price)
			var min_in_lineup = int(pos.document.min_in_lineup.integerValue)
			var num_of_pos_on_bench = min(num_in_squad - min_in_lineup, bench_needed)
			for i in range(len(team[pos_name])-num_of_pos_on_bench, len(team[pos_name])):
				bench.append({"pos":pos_name, "index":i})
			if num_of_pos_on_bench < num_in_squad - 1:
				captain_info = {
					"c_index": 1,
					"c_pos": pos_name,
					"vc_index": captain_info.c_index,
					"vc_pos": captain_info.c_pos
				}
			if num_of_pos_on_bench < num_in_squad:
				captain_info = {
					"c_index": 0,
					"c_pos": pos_name,
					"vc_index": captain_info.c_index,
					"vc_pos": captain_info.c_pos
				}
			bench_needed -= num_of_pos_on_bench
		if budget >= 0:
			var user_document = await users_collection.add("", {
				"user_id": GlobalVars.auth.localid,
				"league_id": $LeagueCode.text,
				"user_name": $UserName.text,
				"team_name": $TeamName.text,
				"league_name": league_name,
				"current_team": team,
				"current_bench": bench,
				"total_points": 0,
				"budget_remaining": float(budget),
				"free_transfers": 0,
				"last_gw_changed": int(league_document.document.upcoming_gw.integerValue),
				"captain_info": captain_info,
				"just_joined": true
			})
			league_document.add_or_update_field("num_players", int(league_document.document.num_players.integerValue)+1)
			league_document = await leagues_collection.update(league_document)
		else:
			$Error.text = "Cannot join this league at the moment as a squad cannot be made within the budget"
			return
		emit_signal("league_joined")
	else:
		$Error.text = "Could not connect to server"
		return
