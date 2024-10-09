extends Control

signal logged_in

var user_auth


func _ready():
	
	Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_failed.connect(on_signup_failed)
	
	#Firebase.Auth.login_with_email_and_password("ajtias7@gmail.com", "Complexity0707")

func _on_login_pressed():
	var email = $email.text
	var password = $password.text
	Firebase.Auth.login_with_email_and_password(email, password)

func _on_register_pressed():
	var email = $email.text
	var password = $password.text
	if len(password) <= 20:
		Firebase.Auth.signup_with_email_and_password(email, password)

func _on_FirebaseAuth_login_succeeded(auth):
		# You do not need to call get_user_data() here, as auth is the same variable
	GlobalVars.auth = auth
	print("signed in")
	emit_signal("logged_in")
	
func on_login_failed(error_code, message):
	print("error code: " + str(error_code))
	print("message: " + str(message))
	$Error.text = "Login failed"

func on_signup_failed(error_code, message):
	print("error code: " + str(error_code))
	print("message: " + str(message))
	$Error.text = "Signup failed"

func _on_view_button_up():
	$password.secret = true


func _on_view_button_down():
	$password.secret = false
