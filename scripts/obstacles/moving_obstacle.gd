class_name MovingObstacle
extends RockObstacle

@export var travel: float = 95.0
@export var frequency: float = 0.65
var origin := Vector2.ZERO
var elapsed := 0.0

func _init() -> void:
	radius = 32
	tint = Color("ddbd78")

func _ready() -> void:
	super._ready()
	origin = position

func _physics_process(delta: float) -> void:
	elapsed += delta
	position.x = origin.x + sin(elapsed * frequency) * travel
