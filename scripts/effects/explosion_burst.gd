extends Node3D
@onready var sparks: GPUParticles3D = $Sparks
@onready var fire: GPUParticles3D = $Fire
@onready var smoke: GPUParticles3D = $Smoke

func _ready() -> void:
	sparks.emitting = true
	fire.emitting = true
	smoke.emitting = true
