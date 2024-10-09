extends Control

const fixture_scene = preload("res://Transfer_fixture.tscn")
const months = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
const weekdays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

func _ready():
	$History.visible = false
	$Fixtures.visible = true
	
	var gws_query : FirestoreQuery = FirestoreQuery.new()
	gws_query.from("gws")
	gws_query.where("league_id", FirestoreQuery.OPERATOR.EQUAL, GlobalVars.league_info.league_id)
	gws_query.order_by("gw_name", FirestoreQuery.DIRECTION.ASCENDING)
	var gws_results = await Firebase.Firestore.query(gws_query)
	
	for gw in gws_results:
		var gw_info = gw.document
		var gw_name = str(gw_info.gw_name.integerValue)
		var gw_fixtures = gw_info.fixtures.arrayValue.values
		for fix in gw_fixtures:
			var fixture_info = fix.mapValue.fields
			var fixture_datetime = Time.get_datetime_dict_from_unix_time(int(fixture_info.date_time.integerValue) + Time.get_time_zone_from_system().bias*60)
			if int(fixture_info.date_time.integerValue) > Time.get_unix_time_from_system():
				var fixture_datetime_string = weekdays[fixture_datetime.weekday] + " " + str(fixture_datetime.day) + " " + months[fixture_datetime.month] + " " + str(fixture_datetime.hour) + ":"
				if len(str(fixture_datetime.minute)) == 1:
					fixture_datetime_string += "0"
				fixture_datetime_string += str(fixture_datetime.minute)
				if fixture_datetime.year != Time.get_date_dict_from_system().year:
					fixture_datetime_string += " " + str(fixture_datetime.year)
				var fixture_oppo_string = fixture_info.Oppo_abbreviation.stringValue + " (" + fixture_info.HA.stringValue[0] + ")" 
				var new_fixture = fixture_scene.instantiate()
				new_fixture.get_node("Date").text = fixture_datetime_string
				new_fixture.get_node("GW").text = gw_name
				new_fixture.get_node("Oppo").text = fixture_oppo_string
				new_fixture.custom_minimum_size.y = 40
				$Fixtures/ScrollContainer/VBoxContainer.add_child(new_fixture)
	$Fixtures/TimeZone.text = "Note: all times in " + Time.get_time_zone_from_system().name

func _on_remove_pressed():
	self.queue_free()


func _on_history_pressed():
	if $Top/History.button_pressed:
		$History.visible = true
		$Fixtures.visible = false
		$Top/Fixtures.button_pressed = false

func _on_fixtures_pressed():
	if $Top/Fixtures.button_pressed:
		$History.visible = false
		$Fixtures.visible = true
		$Top/History.button_pressed = false
