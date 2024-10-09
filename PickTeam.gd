extends Control

signal league_ended
signal changes_made

var positions
var bench_players
var num_starting
var pos_names
var user_doc_name

var c_pos
var c_index
var vc_pos
var vc_index
var c_player
var vc_player

var chip
var bb_available
var tc_available

var upcoming_deadline

var user_collection : FirestoreCollection
var user_document
var league_started
var upcoming_oppo

var switching_player = null
var pos_mins = {}
var pos_maxs = {}

const positionscene = preload("res://Transfer_position.tscn")
const playerscene = preload("res://Pick_team_player.tscn")
const playerinfoscene = preload("res://player_info.tscn")
const playeractionsscene = preload("res://player_actions.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	$Loading.visible = true
	var user_query : FirestoreQuery = FirestoreQuery.new()
	user_query.from("users")
	user_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
	user_query.where("user_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.auth.localid)
	var user_results = await Firebase.Firestore.query(user_query)
	if user_results: user_doc_name = user_results[0].doc_name
	else: connection_error()
	var team = user_results[0].document.current_team.mapValue.fields
	var bench
	if user_results[0].document.current_bench.arrayValue.has('values'):
		bench = user_results[0].document.current_bench.arrayValue.values
	else:
		bench = []
	var prev_fts = int(user_results[0].document.free_transfers.integerValue)
	
	
	var captain_info = user_results[0].document.captain_info.mapValue.fields
	if captain_info.c_pos.has('stringValue'):
		c_pos = captain_info.c_pos.stringValue
		c_index = int(captain_info.c_index.integerValue)
	if captain_info.vc_pos.has('stringValue'):
		vc_pos = captain_info.vc_pos.stringValue
		vc_index = int(captain_info.vc_index.integerValue)
	
	var league_collection : FirestoreCollection = Firebase.Firestore.collection('leagues')
	var league_document = await league_collection.get_doc(GlobalVars.league_info.league_id)
	if league_document: pass
	else: connection_error()
	upcoming_deadline = int(league_document.document.upcoming_deadline.integerValue)
	var upcoming_gw = int(league_document.document.upcoming_gw.integerValue)
	var user_teams_connected = false
	var user_teams_collection : FirestoreCollection
	var free_transfers = prev_fts
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
	if free_transfers != prev_fts:
		free_transfers = min(free_transfers, 5)
		user_collection = Firebase.Firestore.collection("users")
		user_document = await user_collection.get_doc(user_doc_name)
		user_document.add_or_update_field("free_transfers", free_transfers)
		user_document.add_or_update_field("last_gw_changed", upcoming_gw)
		user_document.add_or_update_field("current_chip", "None")
		user_document.add_or_update_field("just_joined", false)
		user_document = await user_collection.update(user_document)
		if league_deadline_passed:
			league_document.add_or_update_field("upcoming_deadline", upcoming_deadline)
			league_document.add_or_update_field("upcoming_gw", upcoming_gw)
			league_document = await league_collection.update(league_document)
	else:
		var gws_query : FirestoreQuery = FirestoreQuery.new()
		gws_query.from("gws")
		gws_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id, FirestoreQuery.OPERATOR.AND)
		gws_query.where("gw_name", FirestoreQuery.OPERATOR.EQUAL, upcoming_gw)
		var gws_results = await Firebase.Firestore.query(gws_query)
		if len(gws_results) > 0:
			upcoming_oppo = gws_results[0].document.fixtures.arrayValue.values[0].mapValue.fields
			upcoming_oppo = upcoming_oppo.Oppo_abbreviation.stringValue + " (" + upcoming_oppo.HA.stringValue[0] + ")"
		else:
			emit_signal("league_ended")
	
	if user_results[0].document.has('bench_boost_available'):
		bb_available = bool(user_results[0].document.bench_boost_available.booleanValue)
	else:
		bb_available = true
	if not bb_available:
		$BB.disabled = true
		$BB.text = "Used"
		
	if user_results[0].document.has('triple_captain_available'):
		tc_available = bool(user_results[0].document.triple_captain_available.booleanValue)
	else:
		tc_available = true
	if not tc_available:
		$TC.disabled = true
		$TC.text = "Used"
	print(old_chip)
	chip = old_chip
	if chip != "None":
		for i in ['TC', 'BB']:
			get_node(i).disabled = true
		get_node(chip).disabled = false
		get_node(chip).text = "Cancel"
		
	$GW.text = "Gameweek " + str(upcoming_gw)
	var deadline_dict = Time.get_datetime_dict_from_unix_time(upcoming_deadline)
	var deadline_str = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][deadline_dict.weekday] + " " + str(deadline_dict.day) + " " + ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][deadline_dict.month] + " " + str(deadline_dict.hour) + ":"
	if len(str(deadline_dict.minute)) == 1:
		deadline_str += "0"
	deadline_str += str(deadline_dict.minute)
	if deadline_dict.year != Time.get_date_dict_from_system().year:
		deadline_str += " " + str(deadline_dict.year)
	$Deadline.text = "Deadline: " + deadline_str
	if upcoming_gw == 1:
		league_started = false
	else:
		league_started = true
	
	var pos_query : FirestoreQuery = FirestoreQuery.new()
	pos_query.from("positions")
	pos_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id)
	pos_query.order_by("i", FirestoreQuery.DIRECTION.ASCENDING)
	var pos_results = await Firebase.Firestore.query(pos_query)
	
	pos_names = []
	num_starting = {}
	for pos in pos_results:
		var pos_name = pos.document.pos_name.stringValue
		pos_names.append(pos_name)
		pos_mins[pos_name] = int(pos.document.min_in_lineup.integerValue)
		pos_maxs[pos_name] = int(pos.document.max_in_lineup.integerValue)
		num_starting[pos_name] = 0
	

	
	positions = {}
	
	for pos in pos_names:
		var players = []
		var pl_index = 0
		for pl in team[pos].arrayValue.values:
			var new_player
			var player_id = pl.mapValue.fields.player_id.stringValue
			var player_name = pl.mapValue.fields.player_name.stringValue
			new_player = playerscene.instantiate()
			var player_oppo = upcoming_oppo
			var player_price
			if pl.mapValue.fields.price.has('doubleValue'):
				player_price = float(pl.mapValue.fields.price.doubleValue)
			else:
				player_price = float(pl.mapValue.fields.price.integerValue)
			new_player.assign_player(player_id, player_name, player_price, player_oppo, pos, pl_index, true, true)
			new_player.get_node("Info").pressed.connect(_on_player_info.bind(new_player))
			new_player.get_node("Select").pressed.connect(_on_player_pressed.bind(new_player))
			players.append(new_player)
			if pos == vc_pos and pl_index == vc_index:
				new_player.get_node("VC").visible = true
				vc_player = new_player
			elif pos == c_pos and pl_index == c_index:
				new_player.get_node("C").visible = true
				c_player = new_player
			pl_index += 1
		positions[pos] = players
		num_starting[pos] = len(players)
	
	bench_players = []
	for b in bench:
		var b_pos = b.mapValue.fields.pos.stringValue
		var b_index = int(b.mapValue.fields.index.integerValue)
		var b_player = positions[b_pos][b_index]
		b_player.player_is_start = false
		num_starting[b_pos] -= 1
		positions[b_pos].remove_at(b_index)
		bench_players.append(b_player)
	
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
	var new_player_actions = playeractionsscene.instantiate()
	new_player_actions.switch.connect(_on_player_switch.bind(player))
	new_player_actions.captain.connect(_on_player_captain.bind(player))
	new_player_actions.vice_captain.connect(_on_player_vice_captain.bind(player))
	new_player_actions.get_node("Name").text = player.player_name
	self.add_child(new_player_actions)


func _on_player_switch(player):
	if switching_player:
		if player.get_node("Switch").visible:
			player.get_node("Switch").visible = false
			switching_player = null
			return
		elif player.player_is_start and switching_player.player_is_start:
			$Error.text = "Both players already starting"
			switching_player.get_node("Switch").visible = false
			switching_player = null
			return
		elif (not player.player_is_start) and (not switching_player.player_is_start):
			swap_players(player, switching_player)
			switching_player.get_node("Switch").visible = false
			switching_player = null
			return
		else:
			if player.player_pos != switching_player.player_pos:
				if player.player_is_start:
					if num_starting[player.player_pos] <= pos_mins[player.player_pos]:
						$Error.text = "Too few of " + player.player_pos
						return
					if num_starting[switching_player.player_pos] >= pos_maxs[switching_player.player_pos]:
						$Error.text = "Too many of " + switching_player.player_pos
						return
				if switching_player.player_is_start:
					if num_starting[switching_player.player_pos] <= pos_mins[switching_player.player_pos]:
						$Error.text = "Too few of " + switching_player.player_pos
						return
					if num_starting[player.player_pos] >= pos_maxs[player.player_pos]:
						$Error.text = "Too many of " + player.player_pos
						return
			if player.player_is_start:
				num_starting[player.player_pos] -= 1
				num_starting[switching_player.player_pos] += 1
			elif switching_player.player_is_start:
				num_starting[player.player_pos] += 1
				num_starting[switching_player.player_pos] -= 1
			swap_players(player, switching_player)
			switching_player.get_node("Switch").visible = false
			switching_player = null
			return
	else:
		player.get_node("Switch").visible = true
		switching_player = player
		return

func swap_players(p1, p2):
	var id = p1.player_id
	var nam = p1.player_name
	var price = p1.player_price
	var pos = p1.player_pos
	var oppo = p1.player_oppo
	var i = p1.player_index
	#var is_start = p1.is_start
	p1.assign_player(p2.player_id, p2.player_name, p2.player_price, p2.player_oppo, p2.player_pos, p2.player_index, false, false)
	p2.assign_player(id, nam, price, oppo, pos, i, false, false)
	

func _on_player_captain(player):
	if not player.player_is_start:
		$Error.text = "You can't captain a bench player"
		return
	if player.get_node("C").visible:
		return
	elif player.get_node("VC").visible:
		var old_captain = c_player
		c_player = vc_player
		vc_player = old_captain
		
		c_pos = c_player.player_pos
		c_index = c_player.player_index
		vc_pos = vc_player.player_pos
		vc_index = vc_player.player_index
		
		c_player.get_node("VC").visible = false
		c_player.get_node("C").visible = true
		vc_player.get_node("C").visible = false
		vc_player.get_node("VC").visible = true
	else:
		vc_player.get_node("VC").visible = false
		
		vc_player = c_player
		c_player = player
		
		c_pos = c_player.player_pos
		c_index = c_player.player_index
		vc_pos = vc_player.player_pos
		vc_index = vc_player.player_index
		
		c_player.get_node("VC").visible = false
		c_player.get_node("C").visible = true
		vc_player.get_node("C").visible = false
		vc_player.get_node("VC").visible = true

func _on_player_vice_captain(player):
	if vc_index == null:
		return
	if not player.player_is_start:
		$Error.text = "You can't vice-captain a bench player"
		return
	if player.get_node("VC").visible:
		return
	elif player.get_node("C").visible:
		var old_captain = c_player
		c_player = vc_player
		vc_player = old_captain
		
		c_pos = c_player.player_pos
		c_index = c_player.player_index
		vc_pos = vc_player.player_pos
		vc_index = vc_player.player_index
		
		c_player.get_node("VC").visible = false
		c_player.get_node("C").visible = true
		vc_player.get_node("C").visible = false
		vc_player.get_node("VC").visible = true
	else:
		vc_player.get_node("VC").visible = false
		vc_player = player
		vc_pos = vc_player.player_pos
		vc_index = vc_player.player_index
		vc_player.get_node("C").visible = false
		vc_player.get_node("VC").visible = true

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

func _on_confirm_pressed():
	if upcoming_deadline < Time.get_unix_time_from_system():
		$Error.text = "Deadline has passed"
		return
	$Error.text = "Saving changes..."
	var bench = []
	for b_player in bench_players:
		bench.append({"index": b_player.player_index, "pos": b_player.player_pos})
	var captain_info = {
		"c_index": c_index,
		"c_pos": c_pos,
		"vc_index": vc_index,
		"vc_pos": vc_pos
	}
	if not user_collection:
		user_collection = Firebase.Firestore.collection("users")
	if not user_document:
		user_document = await user_collection.get_doc(user_doc_name)
	user_document.add_or_update_field("current_bench", bench)
	user_document.add_or_update_field("captain_info", captain_info)
	user_document.add_or_update_field("current_chip", chip)
	user_document.add_or_update_field("bench_boost_available", bb_available)
	user_document.add_or_update_field("triple_captain_available", tc_available)
	user_document = await user_collection.update(user_document)
	$Error.text = ""
	emit_signal("changes_made")

func connection_error():
	print("Error")
	return

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


func _on_tc_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$TC.text = "Cancel"
		chip = "TC"
		$BB.disabled = true
		tc_available = false
	else:
		$TC.text = "Play"
		chip = "None"
		tc_available = true
		if bb_available:
			$BB.disabled = false


func _on_bb_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$BB.text = "Cancel"
		chip = "BB"
		$TC.disabled = true
		bb_available = false
	else:
		$BB.text = "Play"
		chip = "None"
		bb_available = true
		if tc_available:
			$TC.disabled = false
