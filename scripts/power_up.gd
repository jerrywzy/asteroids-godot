extends CharacterBody2D
class_name Power

@onready var screen_size = get_viewport_rect().size
var direction_x
var direction_y
var speed

# Called when the node enters the scene tree for the first time.
func _ready():
	direction_x = randf_range(-1, 1) 
	direction_y = randf_range(-1, 1) 
	speed = randf_range(10, 50) 
	velocity.x = direction_x * speed
	velocity.y = direction_y * speed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_and_slide()
	
	position.x = wrapf(position.x, -10, screen_size.x + 10)  # loops x pos value between 0 and screensize.x 
	position.y = wrapf(position.y, -10, screen_size.y + 10)
