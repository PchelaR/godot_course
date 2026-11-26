class_name Vehicle
extends RigidBody2D

signal exploded(vehicle: Vehicle)
signal skidded(left: Vector2, right: Vector2)

@export var max_speed: float = 520.0
@export var reverse_speed: float = 180.0
@export var acceleration: float = 520.0
@export var brake_power: float = 900.0
@export var rolling_drag: float = 0.6
@export var turn_rate: float = 2.8
@export var full_turn_speed: float = 150.0
@export var grip: float = 14.0
@export var drift_grip: float = 1.6
@export var handbrake_power: float = 420.0
@export var knock_speed: float = 70.0
@export var crash_speed: float = 150.0
@export var wall_damage: float = 0.35
@export var fuse_time: float = 3.0
@export var max_health: float = 100.0
@export var police: bool = false

var throttle: float = 0.0
var steer: float = 0.0
var handbrake: bool = true
var has_driver: bool = false
var player_driven: bool = false
var wrecked: bool = false
var health: float = 100.0
var last_velocity: Vector2 = Vector2.ZERO
var skid_timer: float = 0.0
var siren_timer: float = 0.0
var burn_timer: float = 0.0
var fuse: float = 0.0

@onready var look: Polygon2D = $Look
@onready var bumper: Area2D = $Bumper
@onready var smoke: CPUParticles2D = $Smoke
@onready var siren: Node2D = $Siren
@onready var red_light: Polygon2D = $Siren/Red
@onready var blue_light: Polygon2D = $Siren/Blue
@onready var autopilot: Autopilot = $Autopilot


func _ready() -> void:
	health = max_health
	repaint()
	siren.visible = police
	bumper.body_entered.connect(_on_bumper_body_entered)
	body_entered.connect(_on_body_entered)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var step: float = state.step
	var forward: Vector2 = state.transform.x
	var forward_speed: float = state.linear_velocity.dot(forward)
	var side: Vector2 = state.linear_velocity - forward * forward_speed
	var gas: float = 0.0 if wrecked else throttle
	if gas > 0.0:
		forward_speed = move_toward(forward_speed, max_speed, acceleration * gas * step)
	elif gas < 0.0:
		forward_speed = move_toward(forward_speed, -reverse_speed, brake_power * -gas * step)
	else:
		forward_speed = move_toward(forward_speed, 0.0, (absf(forward_speed) * rolling_drag + 10.0) * step)
	if handbrake or wrecked:
		forward_speed = move_toward(forward_speed, 0.0, handbrake_power * step)
	var drifting: bool = handbrake and (has_driver or player_driven) and not wrecked
	side = side.lerp(Vector2.ZERO, minf((drift_grip if drifting else grip) * step, 1.0))
	state.linear_velocity = forward * forward_speed + side
	if not wrecked:
		var direction: float = 1.0 if forward_speed >= 0.0 else -1.0
		var turning: float = steer * turn_rate * minf(absf(forward_speed) / full_turn_speed, 1.0) * direction
		state.angular_velocity = lerpf(state.angular_velocity, turning, minf(8.0 * step, 1.0))


func _physics_process(delta: float) -> void:
	last_velocity = linear_velocity
	smoke.emitting = health < max_health * 0.4 or burn_timer > 0.0
	burn_timer -= delta
	if not wrecked and health < max_health * 0.2:
		fuse += delta
		Palette.set_light(smoke, "color", Palette.ACCENT)
		if fuse > fuse_time:
			damage(health + 1.0)
	if police and not wrecked:
		siren_timer += delta
		var flip: bool = int(siren_timer * 6.0) % 2 == 0
		Palette.set_light(red_light, "color", Palette.ACCENT if flip else Palette.INK)
		Palette.set_light(blue_light, "color", Palette.INK if flip else Palette.ACCENT)
	skid_timer -= delta
	if skid_timer > 0.0 or wrecked:
		return
	var forward: Vector2 = global_transform.x
	var lateral: float = absf(linear_velocity.dot(global_transform.y))
	var sliding: bool = lateral > 90.0 or (handbrake and player_driven and linear_velocity.length() > 120.0)
	if sliding:
		skid_timer = 0.03
		var back: Vector2 = global_position - forward * 16.0
		skidded.emit(back + global_transform.y * 9.0, back - global_transform.y * 9.0)


func damage(amount: float) -> void:
	if wrecked:
		return
	health -= amount
	if health <= 0.0:
		wrecked = true
		has_driver = false
		throttle = 0.0
		steer = 0.0
		burn_timer = 8.0
		siren.visible = false
		Palette.set_light(smoke, "color", Palette.MUTED)
		repaint()
		exploded.emit(self)


func repaint() -> void:
	var color: Color = Palette.LILAC if police else Palette.INK
	if player_driven:
		color = Palette.ACCENT
	if wrecked:
		color = Palette.MUTED
	Palette.set_light(look, "color", color)


func speed() -> float:
	return linear_velocity.length()


func _on_body_entered(body: Node) -> void:
	var impact: float = (last_velocity - linear_velocity).length()
	if impact > crash_speed:
		var scale_damage: float = wall_damage if body is StaticBody2D else 1.0
		damage((impact - crash_speed) * 0.12 * scale_damage)


func _on_bumper_body_entered(body: Node2D) -> void:
	if body.has_method("hit_by_car"):
		body.hit_by_car(self)
