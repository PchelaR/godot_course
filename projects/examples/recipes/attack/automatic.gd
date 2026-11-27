extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 10.0
@export var magazine_size: int = 12
@export var reload_time: float = 1.2
@export var spread: float = 4.0

var ammo: int
var cooldown: float = 0.0
var reloading: float = 0.0

@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	ammo = magazine_size


func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	cooldown = maxf(cooldown - delta, 0.0)
	if reloading > 0.0:
		reloading -= delta
		if reloading <= 0.0:
			ammo = magazine_size
			modulate.a = 1.0
		return
	if Input.is_action_pressed("shoot") and cooldown == 0.0:
		shoot()


func shoot() -> void:
	cooldown = 1.0 / fire_rate
	ammo -= 1
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_transform = muzzle.global_transform
	bullet.rotate(deg_to_rad(randf_range(-spread, spread)))
	get_tree().current_scene.add_child(bullet)
	if ammo == 0:
		reloading = reload_time
		modulate.a = 0.4
