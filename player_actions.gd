extends Control

signal switch
signal captain
signal vice_captain

func _on_cancel_pressed():
	self.queue_free()

func _on_switch_pressed():
	emit_signal("switch")
	self.queue_free()

func _on_captain_pressed():
	emit_signal("captain")
	self.queue_free()

func _on_vicecaptain_pressed():
	emit_signal("vice_captain")
	self.queue_free()
