extends Control

signal league_ended
signal transfers_made

var budget_remaining
var positions
var pos_names
var user_doc_name
var league_started : bool
var free_transfers : int

var upcoming_deadline

var user_collection : FirestoreCollection
var user_document
var player_collection : FirestoreCollection

var teams_in_league

var original_team_ids

const positionscene = preload("res://Transfer_position.tscn")
const playerscene = preload("res://Transfer_player.tscn")
const playerinfoscene = preload("res://player_info.tscn")
const playerselectscene = preload("res://player_select.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	$Loading.visible = true
	var user_query : FirestoreQuery = FirestoreQuery.new()
	user_query.from("users")
	user_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	user_query.where("user_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.auth.localid)
	var user_results = await Firebase.Firestore.query(user_query)
	if user_results: user_doc_name = user_results[0].doc_name
	else:
		connection_error()
		return
	var team = user_results[0].document.current_team.mapValue.fields
	var bench
	if user_results[0].document.current_bench.arrayValue.has('values'):
		bench = user_results[0].document.current_bench.arrayValue.values
	else:
		bench = []
	var captain_info = user_results[0].document.captain_info.mapValue.fields
	budget_remaining = user_results[0].document.budget_remaining
	if budget_remaining.has("doubleValue"):
		budget_remaining = float(budget_remaining.doubleValue)
	else:
		budget_remaining = float(budget_remaining.integerValue)
	var prev_fts = int(user_results[0].document.free_transfers.integerValue)
	update_budget()
	
	var pos_query : FirestoreQuery = FirestoreQuery.new()
	pos_query.from("positions")
	pos_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id)
	pos_query.order_by("i", FirestoreQuery.DIRECTION.ASCENDING)
	var pos_results = await Firebase.Firestore.query(pos_query)
	
	pos_names = []
	for pos in pos_results:
		pos_names.append(pos.document.pos_name.stringValue)
	

	var league_collection : FirestoreCollection = Firebase.Firestore.collection('leagues')
	var league_document = await league_collection.get_doc(GlobalVars.league_info.league_id)
	if league_document: pass
	else:
		connection_error()
		return
	teams_in_league = int(league_document.document.num_players.integerValue)
	upcoming_deadline = int(league_document.document.upcoming_deadline.integerValue)
	var upcoming_gw = int(league_document.document.upcoming_gw.integerValue)
	var user_teams_connected = false
	var user_teams_collection : FirestoreCollection
	free_transfers = prev_fts
	var last_gw_changed = int(user_results[0].document.last_gw_changed.integerValue)
	var league_deadline_passed = false
	var old_chip
	if user_results[0].document.has('current_chip'):
		old_chip = user_results[0].document.current_chip.stringValue
	else:
		old_chip = "None"
	while last_gw_changed < upcoming_gw:
		if not user_teams_connected:
			user_teams_collection = Firebase.Firestore.collection('user_teams')
			user_teams_connected = true
		var user_team_document = await user_teams_collection.add("", {
			"league_id": GlobalVars.league_info.league_id,
			"user_id": user_results[0].doc_name,
			"gw": last_gw_changed,
			"team": prettify_team(team),
			"bench": prettify_bench(bench),
			"captain_info": prettify_captain(captain_info),
			"chip": old_chip
		})
		old_chip = "None"
		last_gw_changed += 1
		free_transfers += 1
	while int(Time.get_unix_time_from_system()) > upcoming_deadline:
		league_deadline_passed = true
		if not user_teams_connected:
			user_teams_collection = Firebase.Firestore.collection('user_teams')
			user_teams_connected = true
		var user_team_document = await user_teams_collection.add("", {
			"league_id": GlobalVars.league_info.league_id,
			"user_id": user_results[0].doc_name,
			"gw": upcoming_gw,
			"team": prettify_team(team),
			"bench": prettify_bench(bench),
			"captain_info": prettify_captain(captain_info),
			"chip": old_chip
		})
		old_chip = "None"
		
		upcoming_gw += 1
		free_transfers += 1
		var gws_query : FirestoreQuery = FirestoreQuery.new()
		gws_query.from("gws")
		gws_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
		gws_query.where("gw_name", FirestoreQuery.OPERATOR.EQUAL, upcoming_gw)
		var gws_results = await Firebase.Firestore.query(gws_query)
		if len(gws_results) > 0:
			upcoming_deadline = int(gws_results[0].document.fixtures.arrayValue.values[0].mapValue.fields.date_time.integerValue)
		else:
			emit_signal("league_ended")
	var been_around = false
	if free_transfers != prev_fts:
		free_transfers = min(free_transfers, 5)
		user_collection = Firebase.Firestore.collection("users")
		user_document = await user_collection.get_doc(user_doc_name)
		user_document.add_or_update_field("free_transfers", free_transfers)
		user_document.add_or_update_field("last_gw_changed", upcoming_gw)
		user_document.add_or_update_field("current_chip", "None")
		user_document.add_or_update_field("just_joined", false)
		been_around = true
		user_document = await user_collection.update(user_document)
		if league_deadline_passed:
			league_document.add_or_update_field("upcoming_deadline", upcoming_deadline)
			league_document.add_or_update_field("upcoming_gw", upcoming_gw)
			league_document = await league_collection.update(league_document)
	$GW.text = "Gameweek " + str(upcoming_gw)
	var deadline_dict = Time.get_datetime_dict_from_unix_time(upcoming_deadline)
	var deadline_str = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][deadline_dict.weekday] + " " + str(deadline_dict.day) + " " + ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][deadline_dict.month] + " " + str(deadline_dict.hour) + ":"
	if len(str(deadline_dict.minute)) == 1:
		deadline_str += "0"
	deadline_str += str(deadline_dict.minute)
	if deadline_dict.year != Time.get_date_dict_from_system().year:
		deadline_str += " " + str(deadline_dict.year)
	$Deadline.text = "Deadline: " + deadline_str
	if upcoming_gw == 1 or ((not been_around) and user_results[0].document.has('just_joined') and user_results[0].document.just_joined.booleanValue == true):
		league_started = false
		$FreeTransfers.text = "Unlimited"
	else:
		league_started = true
	update_free_transfers()
	
	$Loading.visible = false
	
	original_team_ids = []
	positions = {}
	var num_positions = 0
	var num_players = 0
	for pos in pos_names:
		var new_pos = positionscene.instantiate()
		new_pos.get_node("Name").text = pos
		new_pos.position.y = num_positions * 40 + num_players * 40
		num_positions += 1
		$ScrollContainer/VBoxContainer.add_child(new_pos)

		
		var players = []
		var pl_index = 0
		for pl in team[pos].arrayValue.values:
			var player_id = pl.mapValue.fields.player_id.stringValue
			original_team_ids.append(player_id)
			var player_price
			if pl.mapValue.fields.price.has('doubleValue'):
				player_price = float(pl.mapValue.fields.price.doubleValue)
			else:
				player_price = float(pl.mapValue.fields.price.integerValue)
			var player_name = pl.mapValue.fields.player_name.stringValue
			var new_player = playerscene.instantiate()
			new_player.assign_player(player_id, player_name, player_price, pos, true)
			new_player.get_node("NotBlank/Info").pressed.connect(_on_player_info.bind(new_player))
			new_player.get_node("NotBlank/Remove").pressed.connect(_on_budget_changed.bind(new_player, 1))
			new_player.get_node("Blank/Restore").pressed.connect(_on_budget_changed.bind(new_player, -1))
			new_player.get_node("Blank/Select").pressed.connect(_on_select.bind(pos, pl_index))
			new_player.position.y = num_positions * 40 + num_players * 40
			num_players += 1
			$ScrollContainer/VBoxContainer.add_child(new_player)
			players.append(new_player)
			pl_index += 1
			
		positions[pos] = {"position": new_pos, "players": players}
		#$ScrollContainer/VBoxContainer.custom_minimum_size.y += 40

func connection_error():
	print("Error")
	$Error.text = "Connection error"
	return

func _on_player_info(player):
	var name = player.player_name
	var price = player.player_price
	var pos = player.player_pos
	var new_info = playerinfoscene.instantiate()
	new_info.get_node("Top/Position").text = pos
	new_info.get_node("Top/Name").text = name
	new_info.get_node("Top/Price").text = "£" + str(price) + "m"
	if league_started:
		new_info._on_history_pressed()
	else:
		new_info._on_fixtures_pressed()
	self.add_child(new_info)

func update_budget():
	$Budget.text = "£" + str(budget_remaining) + "m"

func update_free_transfers():
	if league_started:
		if free_transfers >= 0:
			$FreeTransfers.text = str(free_transfers)
			$Cost.text = "0"
		else:
			$FreeTransfers.text = "0"
			$Cost.text = str(4 * free_transfers)

func _on_budget_changed(player, dir):
	var price = player.player_price
	budget_remaining += price * dir
	update_budget()

func _on_select(pos, i):
	var new_select = playerselectscene.instantiate()
	new_select._add_players(pos)
	new_select.player_selected.connect(_on_player_selected.bind(new_select, i))
	self.add_child(new_select)

func _on_player_selected(select, i):
	var selected_player = select.selected_player
	var player_id = selected_player.player_id
	var player_name = selected_player.player_name
	var player_price = selected_player.player_price
	var pos = selected_player.pos_name
	var old_player = positions[selected_player.pos_name].players[i]
	var old_id = old_player.player_id
	var original_id = old_player.first_player_id
	old_player.assign_player(player_id, player_name, player_price, pos, false)
	old_player._on_restore_pressed()
	budget_remaining -= player_price
	update_budget()
	if league_started:
		if old_id == player_id:
			#If transferring to the same player, no change
			pass
		elif old_id != original_id and player_id == original_id:
			#If transferring from different to original player, return transfer
			free_transfers += 1
			update_free_transfers()
		else:
			#Otherwise, remove a transfer
			free_transfers -= 1
			update_free_transfers()
	select.queue_free()



func _on_confirm_pressed():
	if upcoming_deadline < Time.get_unix_time_from_system():
		$Error.text = "Deadline has passed"
		return
	
	$Error.text = "Making transfers..."
	if budget_remaining < 0:
		$Error.text = "Insufficient funds"
		return
	var team = {}
	var player_ids = []
	var players_added = []
	var players_removed = []
	for pos in pos_names:
		team[pos] = []
		for player in positions[pos].players:
			if player.get_node("Blank").visible:
				$Error.text = "Select your players first"
				return
			if player.player_id in player_ids:
				$Error.text = "You can't pick a player twice"
				return
			player_ids.append(player.player_id)
			team[pos].append({
				"player_id": player.player_id,
				"player_name": player.player_name,
				"price": player.player_price
			})
			if player.player_id not in original_team_ids:
				players_added.append(player.player_id)
	for player_id in original_team_ids:
		if player_id not in player_ids:
			players_removed.append(player_id)
	if not user_collection:
		user_collection = Firebase.Firestore.collection("users")
	player_collection = Firebase.Firestore.collection("players")
	if not user_document:
		user_document = await user_collection.get_doc(user_doc_name)
	user_document.add_or_update_field("budget_remaining", float(round(budget_remaining*10))/10)
	if league_started:
		var old_points = int(user_document.document.total_points.integerValue)
		if free_transfers >= 0:
			user_document.add_or_update_field("free_transfers", free_transfers)
		else:
			user_document.add_or_update_field("free_transfers", 0)
			user_document.add_or_update_field("total_points", old_points + 4 * free_transfers)
	var players_changed = []
	for pl_id in players_added:
		players_changed.append([pl_id, 1])
	for pl_id in players_removed:
		players_changed.append([pl_id, -1])
	
	for player_changed in players_changed:
		var player_id = player_changed[0]
		var updown = player_changed[1]
		var player_document = await player_collection.get_doc(player_id)
		var price_locked = false
		if player_document.document.has('price_locked') and player_document.document.price_locked.booleanValue == true:
			price_locked = true
		var to_price_change
		if player_document.document.has('to_price_change'):
			if player_document.document.to_price_change.has('doubleValue'):
				to_price_change = player_document.document.to_price_change.doubleValue
			else:
				to_price_change = player_document.document.to_price_change.integerValue
		else:
			to_price_change = 0
		to_price_change += (2.0 / float(teams_in_league)) * updown
		var player_price
		if player_document.document.price.has('doubleValue'):
			player_price = float(player_document.document.price.doubleValue)
		else:
			player_price = float(player_document.document.price.integerValue)
		var new_price
		var new_to_price_change
		if -0.1 < to_price_change and to_price_change < 0.1:
			if not price_locked:
				player_document.add_or_update_field('to_price_change', to_price_change)
		else:
			if not price_locked:
				new_price = player_price + (float(int(to_price_change*10))/10)
				new_to_price_change = fmod(to_price_change, 0.1)
				player_document.add_or_update_field('to_price_change', new_to_price_change)
				player_document.add_or_update_field('price', new_price)
			var old_owned_by = player_document.document.owned_by.arrayValue.values
			var new_owned_by = []
			for us in old_owned_by:
				if updown == 1 or (us.stringValue != user_document.doc_name):
					new_owned_by.append(us.stringValue)
			if updown == 1:
				new_owned_by.append(user_document.doc_name)
			player_document.add_or_update_field('owned_by', new_owned_by)
			if not price_locked:
				for user in player_document.document.owned_by.arrayValue.values:
					var user_id = user.stringValue
					var new_user_document
					var user_team
					if user_id != user_document.doc_name:
						new_user_document = await user_collection.get_doc(user_id)
						user_team = prettify_team(new_user_document.document.current_team.mapValue.fields)
					else:
						user_team = team
					for pos in user_team:
						for pl in user_team[pos]:
							if pl.player_id == player_id:
								pl.price = new_price
					if user_id != user_document.doc_name:
						new_user_document.add_or_update_field('current_team', user_team)
						new_user_document = await user_collection.update(new_user_document)
					else:
						team = user_team
		player_document = await player_collection.update(player_document)
	user_document.add_or_update_field('current_team', team)
	user_document = await user_collection.update(user_document)
	$Error.text = ""
	emit_signal("transfers_made")	
	

func prettify_team(t):
	var team = {}
	for pos in pos_names:
		team[pos] = []
		for pl in t[pos].arrayValue.values:
			var a = pl.mapValue.fields
			var new_pr
			if a.price.has('doubleValue'):
				new_pr = a.price.doubleValue
			else:
				new_pr = a.price.integerValue
			var new_pl = {
				"player_id": a.player_id.stringValue,
				"price": float(new_pr),
				"player_name": a.player_name.stringValue
			}
			team[pos].append(new_pl)
	return team

func prettify_bench(b):
	var bench = []
	for pl in b:
		bench.append({
			"pos": pl.mapValue.fields.pos.stringValue,
			"index": int(pl.mapValue.fields.index.integerValue)
		})
	return bench

func prettify_captain(c):
	return {
		"c_index": int(c.c_index.integerValue),
		"c_pos": c.c_pos.stringValue,
		"vc_index": int(c.vc_index.integerValue),
		"vc_pos": c.vc_pos.stringValue
	}


func _on_make_transfers_pressed() -> void:
	$AreYouSure.visible = true


func _on_cancel_pressed() -> void:
	$AreYouSure.visible = false
	
