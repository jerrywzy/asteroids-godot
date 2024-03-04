extends RigidBody2D
class_name Player

@export var engine_power = 600
@export var spin_power = 5000
var thrust = Vector2.ZERO # (0,0)
var rotation_dir = 0
@onready var screensize = get_viewport_rect().size
@onready var start_pos = position
var resetting: bool
var vuln: bool = false
var powered: bool = false
var teleport_uses: int = 1
var game_running: bool = true

signal bullet_fired
signal dying
signal teleport
signal powered_up

func _ready():
	resetting = false
	$Ship.show()
	$Explosion.hide()
	$Exhaust.hide()
	vuln = false
	$AnimationPlayer.play("invuln")
	$InvulnTimer.start()

func _physics_process(_delta):
	get_input()
	constant_force = thrust   # positional forces, takes in a Vector2
	constant_torque = rotation_dir * spin_power  # rotational forces, takes in a float
	
	
func get_input():
	thrust = Vector2.ZERO
	$Exhaust.hide()
	if Input.is_action_pressed("up"):
		$Exhaust.show()
		thrust = transform.x * engine_power  # transform.x stores x axis rotational information (direction), multiply by speed
	if Input.is_action_just_pressed("up") and game_running:
		AudioManager.thrust_sfx.play()	
	if Input.is_action_just_released("up") and game_running:
		AudioManager.thrust_sfx.stop()	
	rotation_dir = Input.get_axis("left", "right")  # -1 or 1
	# Linear/Damp and Angular/Damp set to 1 and 2 to simulate friction
	if Input.is_action_just_pressed("shoot") and game_running:
		AudioManager.bullet_sfx.play()
		bullet_fired.emit()
	if powered and game_running:
		if Input.is_action_pressed("shoot"):
			bullet_fired.emit()
		if Input.is_action_just_pressed("shoot"):
			AudioManager.rapid_fire.play()
		if Input.is_action_just_released("shoot"):
			AudioManager.rapid_fire.stop()
	if Input.is_action_just_pressed("warp"):
		if teleport_uses > 0:
			teleport.emit()
			teleport_uses -= 1

func _integrate_forces(state):  # used when position of RigidBody2D needs to be change, will not interfere with physics process
	var xform = state.transform  # grab the current transform, state is the PhysicsDirectBodyState2D of our body
	xform.origin.x = wrapf(xform.origin.x, -30, screensize.x + 30)  # modify it to wrap around the screen using wrapf()
	xform.origin.y = wrapf(xform.origin.y, -30, screensize.y + 30) # eg wraps current origin.y to loop between 0 (origin) and screensize (end of screen)
	state.transform = xform  # apply new xform (new position) to current state.transform (current position)

	if resetting:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0

func power_up():
	powered = true
	powered_up.emit()
	await get_tree().create_timer(10).timeout  # power up cooldown
	powered = false

func die():
	if vuln:
		resetting = true
		$AnimationPlayer.play("explode")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		dying.emit()
		

func _on_invuln_timer_timeout():
	vuln = true



func _on_hitbox_area_entered(area):
	if area.get_parent() is Asteroid or area.get_parent() is Enemy:
		die()
	if area.get_parent() is Power:
		power_up()
		area.get_parent().queue_free()

