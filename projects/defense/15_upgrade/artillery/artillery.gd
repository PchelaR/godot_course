extends Tower

@export var shell_scene: PackedScene
@export var damage: int = 4
@export var upgraded_damage: int = 7


func _on_reload_timeout() -> void:
	var target: Enemy = first_enemy()
	if target == null:
		return
	var shell: Shell = shell_scene.instantiate()
	shell.damage = damage
	shell.from = global_position
	shell.to = target.position_in(shell.flight_time)
	shell.position = shell.from
	add_child(shell)


func apply_upgrade() -> void:
	damage = upgraded_damage
