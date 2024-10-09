extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(1,32):
		$Day.add_item(str(i))
	$Day.selected = 0
	var current_year = Time.get_date_dict_from_system().year
	for i in range(current_year, current_year+10):
		$Year.add_item(str(i))
	$Year.selected = 0
