extends Node2D

func _ready():
	$CPUParticles2D.emitting = true

func _on_cpu_particles_2d_finished():
	queue_free()
