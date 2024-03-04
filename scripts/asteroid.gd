extends CharacterBody2D
class_name Asteroid

@onready var screen_size = get_viewport_rect().size
var health = 10
var direction_x
var direction_y
var speed
var rotation_speed

signal exploding

# Called when the node enters the scene tree for the first time.
func _ready():
	$Rock.show()
	$Explosion.hide()
	direction_x = randf_range(-1, 1) 
	direction_y = randf_range(-1, 1) 
	speed = randf_range(10, 50) 
	velocity.x = direction_x * speed
	velocity.y = direction_y * speed
	rotation_speed = randf_range(-2, 2) 
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_and_slide()
	rotation_degrees += rotation_speed
			
	position.x = wrapf(position.x, -40, screen_size.x + 40)  # loops x pos value between 0 and screensize.x 
	position.y = wrapf(position.y, -40, screen_size.y + 40)

func hit(damage_amount):
	health -= damage_amount
	if health <= 0:
		explode()
		
func explode():
	AudioManager.exp_short.play()
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$CPUParticles2D.emitting = true
	$AnimationPlayer.play("explode")
	await $CPUParticles2D.finished
	queue_free()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		exploding.emit(self)
	
