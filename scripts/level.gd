extends Node2D

@onready var screen_size = get_viewport_rect().size
var player_scene: PackedScene = load("res://scenes/player_ship.tscn")
var bullet_scene: PackedScene = load("res://scenes/bullet.tscn")
var enemy_bullet_scene: PackedScene = load("res://scenes/enemy_bullet.tscn")
var asteroid_scene: PackedScene = load("res://scenes/asteroid.tscn")
var enemy_scene: PackedScene = load("res://scenes/enemy_ship.tscn")
var player_explosion_particles: PackedScene = load("res://scenes/player_explosion_particles.tscn")
var power_up_scene: PackedScene = load("res://scenes/power_up.tscn")
var spawn_amount: int
var score: int = 0
var lives: int = 3
var game_running: bool = true
var wave_number: int = 0
var power_up_active: bool = false
var wave_transition: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	wave_number = 1
	spawn_wave(wave_number)
	var current_player = get_tree().get_nodes_in_group("player")[0]
	connect_player_functions(current_player)  # connect signals to functions
	$EnemySpawnTimer.start()
	$PowerSpawnTimer.start()
	$PowerUpAlert.hide()
	$GameOver.hide()
	$WaveCleared.hide()
	$NewWaveAlert.hide()
	await get_tree().create_timer(3).timeout
	AudioManager.wave_boom.play()
	$NewWaveAlert.show()
	$NewWaveAlert/AnimationPlayer.play("pulse")
	$NewWaveAlert/Label.text = ("Wave " + str(wave_number))
	await get_tree().create_timer(6).timeout
	$NewWaveAlert.hide()
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_ui()
	
	if len(get_tree().get_nodes_in_group("hazards")) == 0 and not wave_transition:
		for obj in get_tree().get_nodes_in_group("pickups"):
			obj.queue_free()
		if power_up_active:
			$PowerUpAlert.hide()
			AudioManager.alarm_alert.stop()
		flash_wave_text()
		wave_transition = true
		
func flash_wave_text():
	game_running = false
	var player = get_tree().get_first_node_in_group("player")
	player.game_running = false
	$EnemySpawnTimer.stop()
	$PowerSpawnTimer.stop()
	$WaveCleared/Label.text = ("Wave " + str(wave_number) + " cleared!")
	$WaveCleared.show()
	$WaveCleared/AnimationPlayer.play("pulse")
	await get_tree().create_timer(6).timeout
	$WaveCleared.hide()
	wave_number += 1
	AudioManager.wave_boom.play()
	$NewWaveAlert.show()
	$NewWaveAlert/AnimationPlayer.play("pulse")
	$NewWaveAlert/Label.text = ("Wave " + str(wave_number))
	await get_tree().create_timer(6).timeout
	$NewWaveAlert.hide()
	spawn_wave(wave_number*2)
	game_running = true
	player.game_running = true
	
func spawn_wave(difficulty_number):
	for i in range(difficulty_number):  # initial spawn
		var asteroid_spawn_location = $AsteroidSpawnPath/AsteroidSpawnLocation
		asteroid_spawn_location.progress_ratio = randf()
		spawn_asteroid(1, asteroid_spawn_location.position.x, asteroid_spawn_location.position.y, asteroid_explode_level_1)  # (amount, x, y, explosion_to_transition, scale)
	for i in range(difficulty_number):  # initial spawn for smaller asteroids
		var asteroid_spawn_location = $AsteroidSpawnPath/AsteroidSpawnLocation
		asteroid_spawn_location.progress_ratio = randf()
		spawn_asteroid(1, asteroid_spawn_location.position.x, asteroid_spawn_location.position.y, asteroid_explode_level_2, Vector2(0.5, 0.5))
	$EnemySpawnTimer.start()
	$PowerSpawnTimer.start()
	wave_transition = false
	
func update_ui():
	$UI/Score.text = "Score: " + str(score)
	match lives:
		3:
			$UI/TextureRect.modulate = Color("ffffff")
			$UI/TextureRect2.modulate = Color("ffffff")
			$UI/TextureRect3.modulate = Color("ffffff")
		2:
			$UI/TextureRect.modulate = Color("000000")
			$UI/TextureRect2.modulate = Color("ffffff")
			$UI/TextureRect3.modulate = Color("ffffff")
		1:
			$UI/TextureRect.modulate = Color("000000")
			$UI/TextureRect2.modulate = Color("000000")
			$UI/TextureRect3.modulate = Color("ffffff")
		0:
			$UI/TextureRect.modulate = Color("000000")
			$UI/TextureRect2.modulate = Color("000000")
			$UI/TextureRect3.modulate = Color("000000")
			
	
func connect_player_functions(player_ship: Player):
	player_ship.bullet_fired.connect(create_bullet)
	player_ship.powered_up.connect(show_power_up_alert)
	player_ship.teleport.connect(teleport_to_random_pos)
	player_ship.dying.connect(reset_ship)
	
func reset_ship():
	if lives > 0:
		lives -= 1
		$PowerUpAlert.hide()
		var current_player = get_tree().get_nodes_in_group("player")[0]
		var player_pos = current_player.position
		AudioManager.exp_death.play()
		current_player.queue_free()
		# create a explosion particle effect
		var explosion = player_explosion_particles.instantiate()
		explosion.position = player_pos
		add_child(explosion)
		# initiate new ship
		var new_player_ship = player_scene.instantiate()
		new_player_ship.position = $SpawnPosition.position
		add_child(new_player_ship)
		connect_player_functions(new_player_ship)
	else:
		$PowerUpAlert.hide()
		var current_player = get_tree().get_nodes_in_group("player")[0]
		var player_pos = current_player.position
		AudioManager.exp_death.play()
		current_player.queue_free()
		# create a explosion particle effect
		var explosion = player_explosion_particles.instantiate()
		explosion.position = player_pos
		add_child(explosion)
		#show game over menu
		game_running = false
		$GameOver.show()
	
func spawn_asteroid(amount, position_x, position_y, explode_level_to_transition, chunk_scale: Vector2 = Vector2(1,1)):
	for i in range(amount):
		var new_asteroid = asteroid_scene.instantiate()
		new_asteroid.position.x = position_x  # set positions
		new_asteroid.position.y = position_y
		new_asteroid.scale = chunk_scale   # set scaling  (linked to explosion transition)
		new_asteroid.exploding.connect(explode_level_to_transition.bind())  # set level of explosion to transition to
		add_child(new_asteroid)

func asteroid_explode_level_1(asteroid_obj):
	var old_asteroid = asteroid_obj
	spawn_asteroid(2, old_asteroid.position.x, old_asteroid.position.y, asteroid_explode_level_2, Vector2(0.5,0.5))
	score += 50

func asteroid_explode_level_2(asteroid_obj):
	var old_asteroid = asteroid_obj
	spawn_asteroid(2, old_asteroid.position.x, old_asteroid.position.y, asteroid_destroyed, Vector2(0.25,0.25))
	score += 100
	
func asteroid_destroyed(asteroid_obj):
	asteroid_obj.queue_free()
	score += 150
	
func spawn_enemy():
	if game_running:
		var enemy_spawn_location = $EnemySpawnPath/EnemySpawnLocation
		enemy_spawn_location.progress_ratio = randf()
		var _enemy = enemy_scene.instantiate()
		_enemy.position = enemy_spawn_location.position  # set positions
		_enemy.enemy_bullet_fired.connect(create_bullet_enemy.bind())  # set level of explosion to transition to
		add_child(_enemy)

func spawn_powerup():
	if game_running:
		var enemy_spawn_location = $EnemySpawnPath/EnemySpawnLocation
		enemy_spawn_location.progress_ratio = randf()
		var power_up = power_up_scene.instantiate()
		power_up.position = enemy_spawn_location.position  # set positions
		add_child(power_up)

func create_bullet():
	if game_running:
		var bullet_node = bullet_scene.instantiate()
		var current_player = get_tree().get_nodes_in_group("player")[0]
		bullet_node.position = current_player.get_node("Marker2D").global_position  # set initial potion to PlayerShip's Marker2D
		bullet_node.direction = current_player.transform.x  # set direction to PlayerShips transform.x, VectorUp from bullet will take care of movement
		$Bullets.add_child(bullet_node)
	
func create_bullet_enemy(enemy_obj):
	if game_running:
		var bullet_node = enemy_bullet_scene.instantiate()
		var current_enemy = enemy_obj
		var current_player = get_tree().get_nodes_in_group("player")[0]
		bullet_node.position = current_enemy.global_position  # set initial potion to PlayerShip's Marker2D
		bullet_node.direction = (current_player.global_position - current_enemy.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))).normalized()  # set direction to PlayerShips transform.x, VectorUp from bullet will take care of movement
		$Bullets.add_child(bullet_node)
	
func _on_enemy_spawn_timer_timeout():
	spawn_enemy()
	$EnemySpawnTimer.start()
	
func _on_power_spawn_timer_timeout():
	spawn_powerup()	
	$PowerSpawnTimer.start()
	
func teleport_to_random_pos():
	var current_player = get_tree().get_nodes_in_group("player")[0]
	current_player.global_position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))
	
func show_power_up_alert():
	if not power_up_active:
		power_up_active = true
		$PowerUpAlert.show()
		AudioManager.alarm_alert.play()
		await get_tree().create_timer(10).timeout
		$PowerUpAlert.hide()
		AudioManager.alarm_alert.stop()
		power_up_active = false
		


