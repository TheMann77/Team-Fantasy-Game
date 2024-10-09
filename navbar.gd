extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var tab_i = 0
	var button_width = $Points/TextureButton.size.x * $Points/TextureButton.scale.x + $Points/TextureButton.position.x
	for tab in ['Points', 'Pick Team', 'Transfers', 'Table', 'Leagues']:
		get_node(tab+"/Label").text = tab
		get_node(tab).position.x = tab_i * button_width
		tab_i += 1
