extends Control

var positions
var max_pos_num
const position_scene = preload("res://Position.tscn")
const point_type_scene = preload("res://PointsType.tscn")
const player_scene = preload("res://Player.tscn")
const gw_scene = preload("res://GameWeek.tscn")
var position_names
var point_types
var players
var gws
signal league_created

func _ready():
	$Page1.visible = true
	$Page2.visible = false
	$Page3.visible = false
	$Page4.visible = false
	var default_positions = ['GK', 'DEF', 'MID', 'FWD']
	positions = []
	for i in range(len(default_positions)):
		var new_position = position_scene.instantiate()
		new_position.get_node("LineEdit").text = default_positions[i]
		new_position.get_node("TextureButton").pressed.connect(_on_position_deleted.bind(new_position))
		new_position.position.y = 35*i
		positions.append(new_position)
		$Page1/Positions/VBoxContainer.add_child(new_position)

func _on_position_deleted(pos):
	var i = positions.find(pos, 0)
	positions[i].queue_free()
	for e in range(i+1, len(positions)):
		positions[e].position.y -= 35
	positions.remove_at(i)
	$Page1/Positions/VBoxContainer.custom_minimum_size.y = 35 * len(positions) - 5

func _on_add_position_pressed():
	var new_position = position_scene.instantiate()
	new_position.position.y = 35 * len(positions)
	new_position.get_node("TextureButton").pressed.connect(_on_position_deleted.bind(new_position))
	positions.append(new_position)
	$Page1/Positions/VBoxContainer.add_child(new_position)
	$Page1/Positions/VBoxContainer.custom_minimum_size.y = 35 * len(positions) - 5
	$Page1/Positions.scroll_vertical = $Page1/Positions.get_v_scroll_bar().max_value

func _on_page_2_button_pressed():
	var min_players = 0
	var max_players = 0
	if len($"Page1/League Name".text) == 0:
		$Page1/Page1Error.text = "League name cannot be empty"
		return
	if not $Page1/Budget.text.is_valid_float():
		$Page1/Page1Error.text = "Budget must be a number"
		return
	if not $Page1/TeamSize.text.is_valid_int():
		$Page1/Page1Error.text = "Team size must be an integer"
		return
	for x in positions:
		if len(x.get_node("LineEdit").text) == 0:
			$Page1/Page1Error.text = "Position name cannot be empty"
			return
		if x.get_node("InSquad").text.is_valid_int():
			if int(x.get_node("InSquad").text) <= 0:
				$Page1/Page1Error.text = "# in squad must be positive"
				return
		else:
			$Page1/Page1Error.text = "# in squad must be an integer"
			return
		if x.get_node("MinInLineup").text.is_valid_int():
			min_players += int(x.get_node("MinInLineup").text)
			if int(x.get_node("MinInLineup").text) < 0:
				$Page1/Page1Error.text = "min # in lineup cannot be negative"
				return
			else:
				if x.get_node("MaxInLineup").text.is_valid_int():
					max_players += int(x.get_node("MaxInLineup").text)
					if int(x.get_node("MaxInLineup").text) <= 0:
						$Page1/Page1Error.text = "max # in lineup must be positive"
						return
					else:
						if int(x.get_node("MaxInLineup").text) < int(x.get_node("MinInLineup").text):
							$Page1/Page1Error.text = "max # in lineup must be greater or equal to min # in lineup"
							return
						elif int(x.get_node("InSquad").text) < int(x.get_node("MaxInLineup").text):
							$Page1/Page1Error.text = "# in squad must be greater or equal to max # in lineup"
							return
				else:
					$Page1/Page1Error.text = "max # in lineup must be an integer"
					return
		else:
			$Page1/Page1Error.text = "min # in lineup must be an integer"
			return
	if int($Page1/TeamSize.text) < min_players:
		$Page1/Page1Error.text = "Team size too small"
		return
	if int($Page1/TeamSize.text) > max_players:
		$Page1/Page1Error.text = "Team size too large"
		return
	
	$Page1.visible = false
	$Page2.visible = true
	$Page3.visible = false
	$Page4.visible = false
	position_names = []
	for x in positions:
		position_names.append(x.get_node("LineEdit").text)
	point_types = []
	_on_add_point_type_pressed()

func _on_add_point_type_pressed():
	var new_point_type = point_type_scene.instantiate()
	new_point_type.position.y = (30 * (1+len(position_names)) + 5) * len(point_types)
	new_point_type.get_node("TextureButton").pressed.connect(_on_point_type_deleted.bind(new_point_type))
	point_types.append(new_point_type)
	new_point_type._add_positions(position_names)
	$Page2/PointTypes/VBoxContainer.add_child(new_point_type)
	$Page2/PointTypes/VBoxContainer.custom_minimum_size.y = (30 * (1+len(position_names)) + 5) * len(point_types) - 5
	$Page2/PointTypes.scroll_vertical = $Page2/PointTypes.get_v_scroll_bar().max_value
	
func _on_point_type_deleted(point_type):
	var i = point_types.find(point_type, 0)
	point_types[i].queue_free()
	for e in range(i+1, len(point_types)):
		point_types[e].position.y -= 30 * (1+len(position_names))
	point_types.remove_at(i)
	$Page2/PointTypes/VBoxContainer.custom_minimum_size.y = (30 * (1+len(position_names)) + 5) * len(point_types) - 5

func _on_page_3_button_pressed():
	for x in point_types:
		if len(x.get_node("LineEdit").text) == 0:
			$Page2/Page2Error.text = "Name cannot be empty"
			return
		if x.get_node("LineEdit").text == "match_points":
			$Page2/Page2Error.text = "match_points is a forbidden point name"
			return
		for y in x.points_by_position:
			if not y.get_node("Points").text.is_valid_int():
				$Page2/Page2Error.text = "Points must be an integer"
				return
			if not y.get_node("Per").text.is_valid_int():
				$Page2/Page2Error.text = "Per must be an integer"
				return
	
	$Page1.visible = false
	$Page2.visible = false
	$Page3.visible = true
	$Page4.visible = false
	players = []
	_on_add_player_pressed()

func _on_add_player_pressed():
	var new_player = player_scene.instantiate()
	new_player.position.y = 35 * len(players)
	new_player.get_node("TextureButton").pressed.connect(_on_player_deleted.bind(new_player))
	players.append(new_player)
	for x in position_names:
		new_player.get_node("Position").add_item(x)
	$Page3/Players/VBoxContainer.add_child(new_player)
	$Page3/Players/VBoxContainer.custom_minimum_size.y = 35 * len(players) - 5
	$Page3/Players.scroll_vertical = $Page3/Players.get_v_scroll_bar().max_value

func _on_player_deleted(player):
	var i = players.find(player, 0)
	players[i].queue_free()
	for e in range(i+1, len(players)):
		players[e].position.y -= 35
	players.remove_at(i)
	$Page3/Players/VBoxContainer.custom_minimum_size.y = 35 * len(players) - 5
	

func _on_page_4_button_pressed():
	var players_list = []
	var num_of_each_pos = []
	for x in position_names:
		num_of_each_pos.append(0)
	for x in players:
		if len(x.get_node("Name").text) == 0:
			$Page3/Page3Error.text = "Name cannot be empty"
			return
		if not x.get_node("Price").text.is_valid_float():
			$Page3/Page3Error.text = "Player price must be a number"
			return
		if x.get_node("Name").text in players_list:
			$Page3/Page3Error.text = "Player names must be unique"
			return
		else:
			players_list.append(x.get_node("Name").text)
		for i in range(len(position_names)):
			if x.get_node("Position").text == position_names[i]:
				num_of_each_pos[i] += 1
	
	for i in range(len(position_names)):
		if num_of_each_pos[i] < int(positions[i].get_node("InSquad").text):
			$Page3/Page3Error.text = "Not enough of " + position_names[i]
			return
	
	$Page1.visible = false
	$Page2.visible = false
	$Page3.visible = false
	$Page4.visible = true
	gws = []
	_on_add_gameweek_pressed()

func _on_add_gameweek_pressed():
	var new_gw = gw_scene.instantiate()
	new_gw.position.y = $Page4/GWs/VBoxContainer.custom_minimum_size.y + 5
	new_gw.fixture_added.connect(_on_fixture_added.bind(new_gw))
	new_gw.fixture_removed.connect(_on_fixture_removed.bind(new_gw))
	new_gw.gw_removed.connect(_on_gw_removed.bind(new_gw))
	new_gw.get_node("GW").text = str(len(gws)+1)
	gws.append(new_gw)
	$Page4/GWs/VBoxContainer.add_child(new_gw)
	$Page4/GWs/VBoxContainer.custom_minimum_size.y += 35
	$Page4/GWs.scroll_vertical = $Page4/GWs.get_v_scroll_bar().max_value

func _on_fixture_added(gw):
	var i = gws.find(gw, 0)
	for e in range(i+1, len(gws)):
		gws[e].position.y += 60
	$Page4/GWs/VBoxContainer.custom_minimum_size.y += 60

func _on_fixture_removed(gw):
	var i = gws.find(gw, 0)
	for e in range(i+1, len(gws)):
		gws[e].position.y -= 60
	$Page4/GWs/VBoxContainer.custom_minimum_size.y -= 60

func _on_gw_removed(gw):
	var i = gws.find(gw, 0)
	var gw_size = 30 + 60 * len(gw.matches) + 5
	for e in range(i+1, len(gws)):
		gws[e].position.y -= gw_size
		gws[e].get_node("GW").text = str(int(gws[e].get_node("GW").text)-1)
	gw.queue_free()
	gws.remove_at(i)
	$Page4/GWs/VBoxContainer.custom_minimum_size.y -= gw_size

func _on_create_button_pressed():
	$Page4/Page4Error.text = "Creating league..."
	var latest_fixture = Time.get_unix_time_from_system()
	#var oppo_names = []
	#var oppo_abbs = []
	var gws_list = []
	if len(gws) == 0:
		$Page4/Page4Error.text = "Please enter a gameweek"
		return
	for x in gws:
		var gw_name = int(x.get_node("GW").text)
		var fixtures_list = []
		for y in x.matches:
			var day = int(y.get_node("Day").text)
			var month = y.get_node("Month").text
			var year =  int(y.get_node("Year").text)
			if not is_valid_date(day, month, year):
				$Page4/Page4Error.text = str(day) + " " + month + " " + str(year) + " is not a valid date"
				return
			month = 1 + ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].find(month, 0)
			var time = y.get_node("Time").text
			var hour
			var minute
			if ':' in time:
				var time_list = time.split(':')
				hour = time_list[0]
				minute = time_list[1]
				if (not hour.is_valid_int()) or (not minute.is_valid_int()):
					$Page4/Page4Error.text = "time format must be HH:MM"
					return
				hour = int(hour)
				minute = int(minute)
				if hour < 0 or hour > 23 or minute < 0 or minute > 59:
					$Page4/Page4Error.text = hour + ":" + minute + " is an invalid time"
					return
			else:
				$Page4/Page4Error.text = "time format must be HH:MM"
				return
			var date_dict = {
				"year": year,
				"month": month,
				"day": day,
				"hour": hour,
				"minute": minute
			}
			var date = Time.get_unix_time_from_datetime_dict(date_dict)
			
			var current_date = Time.get_unix_time_from_system()
			if date < current_date:
				$Page4/Page4Error.text = "Fixture date cannot be in the past"
				return
			if date < latest_fixture:
				$Page4/Page4Error.text = "Fixtures must be in time order"
				return
			else:
				latest_fixture = date
			var oppo = y.get_node("Oppo").text
			var oppo_abb = y.get_node("Oppo2").text
			if len(oppo) == 0:
				$Page4/Page4Error.text = "Opposition name cannot be empty"
				return
				
			#The absolute moron that wrote this code forgot that you can play the same team twice
			"""if oppo in oppo_names:
				$Page4/Page4Error.text = "Opposition names must be unique"
				return
			else:
				oppo_names.append(oppo)
			if oppo_abb in oppo_abbs:
				$Page4/Page4Error.text = "Opposition abbreviations must be unique"
				return
			else:
				oppo_abbs.append(oppo_abb)"""

			fixtures_list.append({
				"date_time": date,
				"Oppo": oppo,
				"Oppo_abbreviation": oppo_abb,
				"HA": y.get_node("HA").text
			})
		gws_list.append({
			"gw_name": gw_name,
			"fixtures": fixtures_list
		})
			
	if GlobalVars.auth.localid:
		pass
	else:
		$Page4/Page4Error.text = "Failed to connect to server"
		return
		
	
	var positions_list = []
	var i = 0
	for x in positions:
		var pos_name = x.get_node("LineEdit").text
		var pos_info = {
			'pos_name': pos_name,
			'in_squad': int(x.get_node("InSquad").text),
			'min_in_lineup': int(x.get_node("MinInLineup").text),
			'max_in_lineup': int(x.get_node("MaxInLineup").text),
			'i': i
		}
		#positions_dict[pos_name] = pos_info
		positions_list.append(pos_info)
		i += 1
	
	var point_type_names = []
	var point_types_list = []
	i = 0
	for x in point_types:
		var point_name = x.get_node("LineEdit").text
		point_type_names.append(point_name)
		var point_dict = {"point_name": point_name, 'i': i}
		for y in x.points_by_position:
			point_dict[y.get_node("Label").text] = {
				"points": int(y.get_node("Points").text),
				"per": int(y.get_node("Per").text)
			}
		#point_types_dict[point_name] = point_dict
		point_types_list.append(point_dict)
		i += 1
		
	var players_list = []
	for x in players:
		players_list.append({
			"player_name": x.get_node("Name").text,
			"position": x.get_node("Position").text,
			"price": float(x.get_node("Price").text),
			"total_points": 0
		})
	
	var league_document
	var leagues_collection : FirestoreCollection = Firebase.Firestore.collection("leagues")
	league_document = await leagues_collection.add("", {
		'league_name': $"Page1/League Name".text,
		'budget': int($Page1/Budget.text),
		'captains': $Page1/Captains.button_pressed,
		'wildcard': $Page1/Wildcard.button_pressed,
		'free_hit': $Page1/FreeHit.button_pressed,
		'bench_boost': $Page1/BenchBoost.button_pressed,
		'auto_subs': $Page1/AutoSubs.button_pressed,
		'price_changes': $Page1/PriceChanges.button_pressed,
		'admin_user': GlobalVars.auth.localid,
		'team_size': int($Page1/TeamSize.text),
		'upcoming_gw': gws_list[0].gw_name,
		'upcoming_deadline': gws_list[0].fixtures[0].date_time,
		'last_gw_scored': 0
	})

	if league_document:
		var league_id = league_document.doc_name
		
		var positions_document
		var positions_collection : FirestoreCollection = Firebase.Firestore.collection("positions")
		for x in positions_list:
			x.merge({'league_id': league_id})
			positions_document = await positions_collection.add("", x)
		
		var point_types_document
		var point_types_collection : FirestoreCollection = Firebase.Firestore.collection("point_types")
		for x in point_types_list:
			x.merge({'league_id': league_id})
			point_types_document = await point_types_collection.add("", x)
		
		var players_document
		var players_collection : FirestoreCollection = Firebase.Firestore.collection("players")
		for x in players_list:
			x.merge({'league_id': league_id})
			players_document = await players_collection.add("", x)
			
		var gws_document
		var gws_collection : FirestoreCollection = Firebase.Firestore.collection("gws")
		for x in gws_list:
			x.merge({'league_id': league_id})
			gws_document = await gws_collection.add("", x)
		
		
		GlobalVars.league_info = {
			'league_id': league_document.doc_name,
			'league_name': league_document.document.league_name.stringValue
		}
		emit_signal("league_created")
	else:
		$Page4/Page4Error.text = "Failed to contact server"
		return

func is_valid_date(day, month, year):
	# In format 1, "Jan", 2000
	if day > 31 or day < 1:
		return false
	elif month in ['Apr', 'Jun', 'Sep', 'Nov']:
		if day == 31:
			return false
	elif month == 'Feb':
		if day > 29:
			return false
		elif day < 29:
			return true
		else:
			if year % 400 == 0:
				return true
			elif year % 100 == 0:
				return false
			elif year % 4 == 0:
				return true
			else:
				return false
	return true
