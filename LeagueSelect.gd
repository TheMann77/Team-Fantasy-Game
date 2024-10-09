extends Control

const leaguescene = preload("res://League.tscn")

signal user_league_pressed
signal admin_league_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	var user_query : FirestoreQuery = FirestoreQuery.new()
	user_query.from("users")
	user_query.where("user_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.auth.localid)
	var user_results = await Firebase.Firestore.query(user_query)
	var i = 0
	if len(user_results):
		$ScrollContainer/VBoxContainer/Label.visible = true
		for league in user_results:
			var new_league = leaguescene.instantiate()
			new_league.get_node("LeagueButton").text = league.document.league_name.stringValue
			new_league.get_node("LeagueButton").pressed.connect(_on_league_button_pressed.bind(league.document.league_id.stringValue, "user", league.doc_name))
			new_league.position.y = 43 * i
			i += 1
			$ScrollContainer/VBoxContainer/User.add_child(new_league)
	else:
		$ScrollContainer/VBoxContainer/Label.visible = false
	$ScrollContainer/VBoxContainer/Label2.position.y = 26 + 43 * len(user_results) + 20
	$ScrollContainer/VBoxContainer/Admin.position.y = 26 + 43 * len(user_results) + 20 + 26
	#$ScrollContainer/VBoxContainer/JoinCreate.position.y = 26 + 43 * len(user_results) + 20 + 26 + 20

	var admin_query : FirestoreQuery = FirestoreQuery.new()
	admin_query.from("leagues")
	admin_query.where("admin_user", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.auth.localid)
	var admin_results = await Firebase.Firestore.query(admin_query)
	i = 0
	if len(admin_results):
		$ScrollContainer/VBoxContainer/Label2.visible = true
		for league in admin_results:
			var new_league = leaguescene.instantiate()
			new_league.get_node("LeagueButton").text = league.document.league_name.stringValue
			new_league.get_node("LeagueButton").pressed.connect(_on_league_button_pressed.bind(league.doc_name, "admin", null))
			new_league.position.y = 43 * i
			i += 1
			$ScrollContainer/VBoxContainer/Admin.add_child(new_league)
	else:
		$ScrollContainer/VBoxContainer/Label2.visible = false
	#$ScrollContainer/VBoxContainer/JoinCreate.position.y = 26 + 43 * len(user_results) + 20 + 26 + 43 * len(admin_results) + 20


func _on_league_button_pressed(league_id, role, user_id):
	GlobalVars.league_info = {"league_id": league_id, "role": role, "user_id": user_id}
	if role == "user":
		emit_signal("user_league_pressed")
	elif role == "admin":
		emit_signal("admin_league_pressed")
