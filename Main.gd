extends Control

var currentpage = null
const loginpage = preload("res://login_page.tscn")
const createleaguepage = preload("res://create_league.tscn")
const leaguecreatedpage = preload("res://league_created_page.tscn")
const joinleaguepage = preload("res://join_league.tscn")
const leagueselectpage = preload("res://league_select.tscn")
const transferspage = preload("res://transfers.tscn")
const pickteampage = preload("res://Pick_team.tscn")
const pointspage = preload("res://Points.tscn")
const tablepage = preload("res://table.tscn")
const addscorepage = preload("res://add_score.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	_login_page()

func _login_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = loginpage.instantiate()
	currentpage.logged_in.connect(_league_select_page)
	add_child(currentpage)
	
func _league_select_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = leagueselectpage.instantiate()
	currentpage.get_node("JoinCreate/JoinLeague").pressed.connect(_join_league_page)
	currentpage.get_node("JoinCreate/CreateLeague").pressed.connect(_create_league_page)
	currentpage.user_league_pressed.connect(_transfers_page)
	currentpage.admin_league_pressed.connect(_manage_league_page)
	add_child(currentpage)
	
func _create_league_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = createleaguepage.instantiate()
	currentpage.league_created.connect(_league_created_page)
	currentpage.get_node("Home").pressed.connect(_league_select_page)
	add_child(currentpage)

func _league_created_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = leaguecreatedpage.instantiate()
	currentpage.get_node("ManageLeague").pressed.connect(_manage_league_page)
	currentpage.get_node("JoinLeague").pressed.connect(_join_league_page)
	currentpage.get_node("Home").pressed.connect(_league_select_page)
	add_child(currentpage)
	
func _manage_league_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = addscorepage.instantiate()
	currentpage.get_node("Home").pressed.connect(_league_select_page)
	add_child(currentpage)
	
func _join_league_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = joinleaguepage.instantiate()
	currentpage.league_joined.connect(_league_select_page)
	currentpage.get_node("Home").pressed.connect(_league_select_page)
	add_child(currentpage)

func _transfers_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = transferspage.instantiate()
	connect_navbar(currentpage.get_node("Navbar"), "Transfers")
	currentpage.league_ended.connect(_points_page)
	currentpage.transfers_made.connect(_pick_team_page)
	add_child(currentpage)

func _pick_team_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = pickteampage.instantiate()
	connect_navbar(currentpage.get_node("Navbar"), "Pick Team")
	currentpage.league_ended.connect(_points_page)
	currentpage.changes_made.connect(_pick_team_page)
	add_child(currentpage)

func _points_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = pointspage.instantiate()
	connect_navbar(currentpage.get_node("Navbar"), "Points")
	currentpage.get_team(GlobalVars.league_info.user_id, -1)
	add_child(currentpage)

func _league_table_page():
	if currentpage:
		currentpage.queue_free()
	currentpage = tablepage.instantiate()
	connect_navbar(currentpage.get_node("Navbar"), "Table")
	add_child(currentpage)

func connect_navbar(navbar, page: String = ""):
	navbar.get_node("Points/TextureButton").pressed.connect(_points_page)
	navbar.get_node("Pick Team/TextureButton").pressed.connect(_pick_team_page)
	navbar.get_node("Transfers/TextureButton").pressed.connect(_transfers_page)
	navbar.get_node("Leagues/TextureButton").pressed.connect(_league_select_page)
	navbar.get_node("Table/TextureButton").pressed.connect(_league_table_page)
	if page != "":
		navbar.get_node(page + "/TextureButton").disabled = true
		pass
