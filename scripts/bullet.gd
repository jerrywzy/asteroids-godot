extends Node2D
class_name bullet

var speed = 1000
var direction = Vector2.UP

# Called when the node enters the scene tree for the first time.
func _ready():
	$LifeTimer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += direction * speed * delta  # default direction is upwards
	

func _on_life_timer_timeout():
	queue_free()



func _on_area_2d_area_entered(area):
	if area.get_parent() is Asteroid:
		area.get_parent().hit(10)
		queue_free()
	if area.get_parent() is Player:
		area.get_parent().die()
	if area.get_parent() is Enemy:
		area.get_parent().die()
