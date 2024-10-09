extends Control

var league_code

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = "League created successfully!
	League name: " + GlobalVars.league_info.league_name + "
	Join code: " + GlobalVars.league_info.league_id
	league_code = GlobalVars.league_info.league_id
	GlobalVars.league_info = {}

func _on_copy_pressed():
	DisplayServer.clipboard_set(league_code)
