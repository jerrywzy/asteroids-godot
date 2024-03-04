extends CharacterBody2D
class_name Enemy

@onready var screen_size = get_viewport_rect().size
var direction_x
var direction_y
var speed

signal enemy_bullet_fired

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.show()
	$Explosion.hide()
	AudioManager.beeping.play()
	direction_x = randf_range(-1, 1) 
	direction_y = randf_range(0, 0) 
	speed = randf_range(10, 50) 
	velocity.x = direction_x * speed
	velocity.y = direction_y * speed
	$BulletTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_and_slide()
	
	position.x = wrapf(position.x, -10, screen_size.x + 10)  # loops x pos value between 0 and screensize.x 
	position.y = wrapf(position.y, -10, screen_size.y + 10)

func _on_bullet_timer_timeout():
	enemy_bullet_fired.emit(self)
	$BulletTimer.start()
	
func die():
	$AnimationPlayer.play("explode")
	

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		AudioManager.exp_short.play()
		AudioManager.beeping.stop()
		queue_free()
