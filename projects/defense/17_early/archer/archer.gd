extends Tower

@export var arrow_scene: PackedScene
@export var upgraded_reload_time: float = 0.45

@onready var reload: Timer = $Reload


func _on_reload_timeout() -> void:
	var target: Enemy = first_enemy()
	if target == null:
		return
	var arrow: Arrow = arrow_scene.instantiate()
	arrow.target = target
	arrow.position = global_position
	add_child(arrow)


func apply_upgrade() -> void:
	reload.wait_time = upgraded_reload_time
