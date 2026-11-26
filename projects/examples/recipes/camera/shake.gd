extends Camera2D

@export var decay: float = 1.2
@export var max_offset: Vector2 = Vector2(48, 36)
@export var max_roll: float = 0.06
@export var frequency: float = 15.0

var trauma: float = 0.0
var time: float = 0.0
var noise: FastNoiseLite = FastNoiseLite.new()


func _ready() -> void:
	noise.frequency = 1.0


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _process(delta: float) -> void:
	time += delta
	trauma = maxf(trauma - decay * delta, 0.0)
	var power: float = trauma * trauma
	var phase: float = time * frequency
	offset = Vector2(noise.get_noise_2d(phase, 0.0), noise.get_noise_2d(0.0, phase)) * max_offset * power
	rotation = noise.get_noise_2d(phase, 100.0) * max_roll * power


func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		add_trauma(0.4)
